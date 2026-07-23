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
