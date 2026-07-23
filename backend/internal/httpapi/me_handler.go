package httpapi

import (
	"encoding/json"
	"errors"
	"net/http"
	"regexp"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

// MeHandler expõe ações que o User autenticado faz sobre si mesmo,
// distintas da administração de outros Users (UserHandler).
type MeHandler struct {
	queries *sqlcgen.Queries
}

func NewMeHandler(pool *pgxpool.Pool) *MeHandler {
	return &MeHandler{queries: sqlcgen.New(pool)}
}

// usernamePattern espelha a constraint username_format da migration
// 000002_add_username.up.sql — mantenha as duas em sincronia.
var usernamePattern = regexp.MustCompile(`^[a-z0-9_]{3,30}$`)

type setUsernameRequest struct {
	Username string `json:"username"`
}

type changePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

type updateProfileRequest struct {
	Name     *string `json:"name"`
	Username *string `json:"username"`
}

// Get retorna o perfil do User autenticado — usado pelo front para
// confirmar o estado atual (incl. se o username já foi definido) sem
// depender de um flag salvo localmente, que ficaria dessincronizado se o
// Primeiro Acesso for concluído em outro dispositivo/sessão.
func (h *MeHandler) Get(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	user, err := h.queries.GetUserByID(r.Context(), parseUUID(claims.UserID))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	writeJSON(w, http.StatusOK, toUserResponse(user))
}

// SetUsername define o Username do User autenticado no Primeiro Acesso (ver
// CONTEXT.md). Só funciona uma vez — uma vez definido, o username é
// permanente (a query SetUsername só aplica com username IS NULL).
func (h *MeHandler) SetUsername(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	var req setUsernameRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if !usernamePattern.MatchString(req.Username) {
		writeError(w, http.StatusBadRequest, "username must be 3-30 characters, lowercase letters, numbers or underscore")
		return
	}

	ctx := r.Context()
	user, err := h.queries.SetUsername(ctx, sqlcgen.SetUsernameParams{
		ID:       parseUUID(claims.UserID),
		Username: &req.Username,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusConflict, "username already set for this account")
			return
		}
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			writeError(w, http.StatusConflict, "username already taken")
			return
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	writeJSON(w, http.StatusOK, toUserResponse(user))
}

// ChangePassword troca a senha do User autenticado, exigindo a senha atual
// correta (defesa contra sessão sequestrada de longa duração).
func (h *MeHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	var req changePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if len(req.NewPassword) < auth.MinPasswordLength {
		writeError(w, http.StatusBadRequest, "new password too short")
		return
	}

	ctx := r.Context()
	user, err := h.queries.GetUserByID(ctx, parseUUID(claims.UserID))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if !auth.CheckPassword(user.PasswordHash, req.CurrentPassword) {
		writeError(w, http.StatusUnauthorized, "current password is incorrect")
		return
	}

	hash, err := auth.HashPassword(req.NewPassword)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	if _, err := h.queries.SetPasswordHash(ctx, sqlcgen.SetPasswordHashParams{
		ID:           user.ID,
		PasswordHash: hash,
	}); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// UpdateProfile atualiza nome e/ou username do User autenticado a partir da
// tela de Perfil. Diferente de SetUsername (Primeiro Acesso, one-shot), aqui
// o username já definido pode ser trocado livremente — só a unicidade
// continua garantida (constraint users_username_key). Campos omitidos (nil)
// não são alterados.
func (h *MeHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	var req updateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Username != nil && !usernamePattern.MatchString(*req.Username) {
		writeError(w, http.StatusBadRequest, "username must be 3-30 characters, lowercase letters, numbers or underscore")
		return
	}
	if req.Name != nil && *req.Name == "" {
		writeError(w, http.StatusBadRequest, "name cannot be empty")
		return
	}

	ctx := r.Context()
	userID := parseUUID(claims.UserID)

	if req.Name != nil {
		if _, err := h.queries.SetName(ctx, sqlcgen.SetNameParams{ID: userID, Name: *req.Name}); err != nil {
			writeError(w, http.StatusInternalServerError, "internal error")
			return
		}
	}

	user, err := h.queries.GetUserByID(ctx, userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	if req.Username != nil {
		user, err = h.queries.UpdateUsername(ctx, sqlcgen.UpdateUsernameParams{ID: userID, Username: req.Username})
		if err != nil {
			var pgErr *pgconn.PgError
			if errors.As(err, &pgErr) && pgErr.Code == "23505" {
				writeError(w, http.StatusConflict, "username already taken")
				return
			}
			writeError(w, http.StatusInternalServerError, "internal error")
			return
		}
	}

	writeJSON(w, http.StatusOK, toUserResponse(user))
}
