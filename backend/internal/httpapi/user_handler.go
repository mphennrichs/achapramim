package httpapi

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

type UserHandler struct {
	queries *sqlcgen.Queries
}

func NewUserHandler(pool *pgxpool.Pool) *UserHandler {
	return &UserHandler{queries: sqlcgen.New(pool)}
}

type createUserRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

type setUserRoleRequest struct {
	Role string `json:"role"`
}

type setUserActiveRequest struct {
	Active bool `json:"active"`
}

type userResponse struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	Active bool   `json:"active"`
}

// Create cadastra um novo User. Não existe self-signup: só um admin chega
// aqui (rota atrás de auth.RequireAdmin), e define a senha inicial
// diretamente — o User não é obrigado a trocá-la no primeiro login.
func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req createUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if len(req.Password) < auth.MinPasswordLength {
		writeError(w, http.StatusBadRequest, "password too short")
		return
	}

	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	user, err := h.queries.CreateUser(r.Context(), sqlcgen.CreateUserParams{
		Name:         req.Name,
		Email:        req.Email,
		PasswordHash: hash,
		Role:         req.Role,
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, "failed to create user: "+err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, toUserResponse(user))
}

// List retorna todos os Users cadastrados.
func (h *UserHandler) List(w http.ResponseWriter, r *http.Request) {
	users, err := h.queries.ListUsers(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	resp := make([]userResponse, len(users))
	for i, u := range users {
		resp[i] = toUserResponse(u)
	}
	writeJSON(w, http.StatusOK, resp)
}

// SetRole muda o Role de um User (ex: promover a admin).
func (h *UserHandler) SetRole(w http.ResponseWriter, r *http.Request) {
	var req setUserRoleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	userID := parseUUID(chi.URLParam(r, "id"))

	user, err := h.queries.SetUserRole(ctx, sqlcgen.SetUserRoleParams{ID: userID, Role: req.Role})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusNotFound, "user not found")
			return
		}
		writeError(w, http.StatusBadRequest, "failed to set role: "+err.Error())
		return
	}
	writeJSON(w, http.StatusOK, toUserResponse(user))
}

// SetActive ativa/desativa um User. Desativar pausa automaticamente todos
// os Watches dele (derivado via join em DueWatches, nunca persistido no
// Watch) — reativar volta os Watches ao funcionamento normal, respeitando
// o estado ativo/inativo de cada um.
func (h *UserHandler) SetActive(w http.ResponseWriter, r *http.Request) {
	var req setUserActiveRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	userID := parseUUID(chi.URLParam(r, "id"))

	user, err := h.queries.SetUserActive(ctx, sqlcgen.SetUserActiveParams{ID: userID, Active: req.Active})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusNotFound, "user not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, toUserResponse(user))
}

func toUserResponse(u sqlcgen.User) userResponse {
	return userResponse{
		ID:     uuidString(u.ID),
		Name:   u.Name,
		Email:  u.Email,
		Role:   u.Role,
		Active: u.Active,
	}
}
