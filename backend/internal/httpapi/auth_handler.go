package httpapi

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

type AuthHandler struct {
	queries         *sqlcgen.Queries
	pool            *pgxpool.Pool
	issuer          *auth.TokenIssuer
	refreshTokenTTL time.Duration
}

func NewAuthHandler(pool *pgxpool.Pool, issuer *auth.TokenIssuer, refreshTokenTTL time.Duration) *AuthHandler {
	return &AuthHandler{
		queries:         sqlcgen.New(pool),
		pool:            pool,
		issuer:          issuer,
		refreshTokenTTL: refreshTokenTTL,
	}
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type tokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	user, err := h.queries.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusUnauthorized, "invalid credentials")
			return
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	if !user.Active {
		writeError(w, http.StatusForbidden, "user is deactivated")
		return
	}

	if !auth.CheckPassword(user.PasswordHash, req.Password) {
		writeError(w, http.StatusUnauthorized, "invalid credentials")
		return
	}

	h.issueTokenPair(w, r, user.ID.String(), user.Role)
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	hash := auth.HashRefreshToken(req.RefreshToken)
	stored, err := h.queries.GetRefreshTokenByHash(ctx, hash)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid or expired refresh token")
		return
	}

	user, err := h.queries.GetUserByID(ctx, stored.UserID)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid or expired refresh token")
		return
	}
	if !user.Active {
		writeError(w, http.StatusForbidden, "user is deactivated")
		return
	}

	// Rotação: o refresh token usado é revogado e um novo par é emitido.
	if err := h.queries.RevokeRefreshToken(ctx, stored.ID); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	h.issueTokenPair(w, r, user.ID.String(), user.Role)
}

func (h *AuthHandler) issueTokenPair(w http.ResponseWriter, r *http.Request, userID, role string) {
	accessToken, err := h.issuer.IssueAccessToken(userID, role)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to issue token")
		return
	}

	refreshToken, refreshHash, err := auth.NewRefreshToken()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to issue token")
		return
	}

	_, err = h.queries.CreateRefreshToken(r.Context(), sqlcgen.CreateRefreshTokenParams{
		UserID:    parseUUID(userID),
		TokenHash: refreshHash,
		ExpiresAt: pgTimestamptz(time.Now().Add(h.refreshTokenTTL)),
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to persist refresh token")
		return
	}

	writeJSON(w, http.StatusOK, tokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}
