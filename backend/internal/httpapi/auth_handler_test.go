package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

func createTestUserWithPassword(t *testing.T, pool *pgxpool.Pool, password string) sqlcgen.User {
	t.Helper()
	hash, err := auth.HashPassword(password)
	require.NoError(t, err)

	q := sqlcgen.New(pool)
	user, err := q.CreateUser(context.Background(), sqlcgen.CreateUserParams{
		Name:         "Login Test User",
		Email:        "login-" + uuid.NewString() + "@example.com",
		PasswordHash: hash,
		Role:         "user",
	})
	require.NoError(t, err)
	return user
}

func newAuthHandler(pool *pgxpool.Pool) *AuthHandler {
	return NewAuthHandler(pool, auth.NewTokenIssuer("test-secret", time.Hour), 30*24*time.Hour)
}

func TestAuthHandler_LoginByEmail(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUserWithPassword(t, pool, "supersecret")
	h := newAuthHandler(pool)

	req := newWatchRequest(t, http.MethodPost, "/api/auth/login", nil, loginRequest{
		EmailOrUsername: user.Email,
		Password:        "supersecret",
	})
	rec := httptest.NewRecorder()
	h.Login(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var resp tokenResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.NotEmpty(t, resp.AccessToken)
	require.NotEmpty(t, resp.RefreshToken)
	require.True(t, resp.UsernamePending)
}

func TestAuthHandler_LoginByUsername(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUserWithPassword(t, pool, "supersecret")
	q := sqlcgen.New(pool)
	username := "fulano123"
	_, err := q.SetUsername(context.Background(), sqlcgen.SetUsernameParams{ID: user.ID, Username: &username})
	require.NoError(t, err)

	h := newAuthHandler(pool)
	req := newWatchRequest(t, http.MethodPost, "/api/auth/login", nil, loginRequest{
		EmailOrUsername: username,
		Password:        "supersecret",
	})
	rec := httptest.NewRecorder()
	h.Login(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var resp tokenResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.False(t, resp.UsernamePending)
}

func TestAuthHandler_LoginInvalidCredentials(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUserWithPassword(t, pool, "supersecret")
	h := newAuthHandler(pool)

	req := newWatchRequest(t, http.MethodPost, "/api/auth/login", nil, loginRequest{
		EmailOrUsername: user.Email,
		Password:        "wrong-password",
	})
	rec := httptest.NewRecorder()
	h.Login(rec, req)
	require.Equal(t, http.StatusUnauthorized, rec.Code)
}
