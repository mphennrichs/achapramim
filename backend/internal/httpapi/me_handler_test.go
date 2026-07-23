package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

func TestMeHandler_GetReflectsUsernameState(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUser(t, pool, "user")

	req := newWatchRequest(t, http.MethodGet, "/api/me", claimsFor(user), nil)
	rec := httptest.NewRecorder()
	h.Get(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var before userResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &before))
	require.Nil(t, before.Username)

	setReq := newWatchRequest(t, http.MethodPut, "/api/me/username", claimsFor(user), setUsernameRequest{Username: "fulano_x"})
	setRec := httptest.NewRecorder()
	h.SetUsername(setRec, setReq)
	require.Equal(t, http.StatusOK, setRec.Code, setRec.Body.String())

	getReq2 := newWatchRequest(t, http.MethodGet, "/api/me", claimsFor(user), nil)
	rec2 := httptest.NewRecorder()
	h.Get(rec2, getReq2)
	var after userResponse
	require.NoError(t, json.Unmarshal(rec2.Body.Bytes(), &after))
	require.NotNil(t, after.Username)
	require.Equal(t, "fulano_x", *after.Username)
}

func TestMeHandler_SetUsername(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUser(t, pool, "user")

	req := newWatchRequest(t, http.MethodPut, "/api/me/username", claimsFor(user), setUsernameRequest{
		Username: "fulano_123",
	})
	rec := httptest.NewRecorder()
	h.SetUsername(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var updated userResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &updated))
	require.NotNil(t, updated.Username)
	require.Equal(t, "fulano_123", *updated.Username)
}

func TestMeHandler_SetUsernameRejectsInvalidFormat(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUser(t, pool, "user")

	req := newWatchRequest(t, http.MethodPut, "/api/me/username", claimsFor(user), setUsernameRequest{
		Username: "AB", // maiúsculas e menos de 3 chars
	})
	rec := httptest.NewRecorder()
	h.SetUsername(rec, req)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestMeHandler_SetUsernameRejectsDuplicate(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)

	q := sqlcgen.New(pool)
	taken := "ja_existe"
	other, err := q.CreateUser(context.Background(), sqlcgen.CreateUserParams{
		Name:         "Other",
		Email:        "other-" + uuid.NewString() + "@example.com",
		PasswordHash: "hash",
		Role:         "user",
	})
	require.NoError(t, err)
	_, err = q.SetUsername(context.Background(), sqlcgen.SetUsernameParams{ID: other.ID, Username: &taken})
	require.NoError(t, err)

	user := createTestUser(t, pool, "user")
	req := newWatchRequest(t, http.MethodPut, "/api/me/username", claimsFor(user), setUsernameRequest{
		Username: taken,
	})
	rec := httptest.NewRecorder()
	h.SetUsername(rec, req)
	require.Equal(t, http.StatusConflict, rec.Code)
}

func TestMeHandler_SetUsernameRejectsWhenAlreadySet(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUser(t, pool, "user")

	first := newWatchRequest(t, http.MethodPut, "/api/me/username", claimsFor(user), setUsernameRequest{
		Username: "primeiro_nome",
	})
	rec := httptest.NewRecorder()
	h.SetUsername(rec, first)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	second := newWatchRequest(t, http.MethodPut, "/api/me/username", claimsFor(user), setUsernameRequest{
		Username: "segundo_nome",
	})
	rec2 := httptest.NewRecorder()
	h.SetUsername(rec2, second)
	require.Equal(t, http.StatusConflict, rec2.Code)
}

func TestMeHandler_ChangePassword(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUserWithPassword(t, pool, "senhaAntiga1")

	req := newWatchRequest(t, http.MethodPut, "/api/me/password", claimsFor(user), changePasswordRequest{
		CurrentPassword: "senhaAntiga1",
		NewPassword:     "senhaNova2",
	})
	rec := httptest.NewRecorder()
	h.ChangePassword(rec, req)
	require.Equal(t, http.StatusNoContent, rec.Code, rec.Body.String())

	q := sqlcgen.New(pool)
	updated, err := q.GetUserByID(context.Background(), user.ID)
	require.NoError(t, err)
	require.True(t, auth.CheckPassword(updated.PasswordHash, "senhaNova2"))
}

func TestMeHandler_ChangePasswordRejectsWrongCurrentPassword(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUserWithPassword(t, pool, "senhaAntiga1")

	req := newWatchRequest(t, http.MethodPut, "/api/me/password", claimsFor(user), changePasswordRequest{
		CurrentPassword: "senhaErrada",
		NewPassword:     "senhaNova2",
	})
	rec := httptest.NewRecorder()
	h.ChangePassword(rec, req)
	require.Equal(t, http.StatusUnauthorized, rec.Code)
}

func TestMeHandler_ChangePasswordRejectsShortNewPassword(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUserWithPassword(t, pool, "senhaAntiga1")

	req := newWatchRequest(t, http.MethodPut, "/api/me/password", claimsFor(user), changePasswordRequest{
		CurrentPassword: "senhaAntiga1",
		NewPassword:     "abc",
	})
	rec := httptest.NewRecorder()
	h.ChangePassword(rec, req)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestMeHandler_UpdateProfileChangesNameAndUsername(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)
	user := createTestUser(t, pool, "user")

	first := newWatchRequest(t, http.MethodPut, "/api/me/username", claimsFor(user), setUsernameRequest{
		Username: "nome_antigo",
	})
	rec := httptest.NewRecorder()
	h.SetUsername(rec, first)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	newName := "Novo Nome"
	newUsername := "nome_novo"
	req := newWatchRequest(t, http.MethodPut, "/api/me/profile", claimsFor(user), updateProfileRequest{
		Name:     &newName,
		Username: &newUsername,
	})
	rec2 := httptest.NewRecorder()
	h.UpdateProfile(rec2, req)
	require.Equal(t, http.StatusOK, rec2.Code, rec2.Body.String())

	var updated userResponse
	require.NoError(t, json.Unmarshal(rec2.Body.Bytes(), &updated))
	require.Equal(t, newName, updated.Name)
	require.NotNil(t, updated.Username)
	require.Equal(t, newUsername, *updated.Username)
}

func TestMeHandler_UpdateProfileRejectsDuplicateUsername(t *testing.T) {
	pool := newTestPool(t)
	h := NewMeHandler(pool)

	q := sqlcgen.New(pool)
	taken := "ja_existe_perfil"
	other, err := q.CreateUser(context.Background(), sqlcgen.CreateUserParams{
		Name:         "Other",
		Email:        "other-" + uuid.NewString() + "@example.com",
		PasswordHash: "hash",
		Role:         "user",
	})
	require.NoError(t, err)
	_, err = q.SetUsername(context.Background(), sqlcgen.SetUsernameParams{ID: other.ID, Username: &taken})
	require.NoError(t, err)

	user := createTestUser(t, pool, "user")
	req := newWatchRequest(t, http.MethodPut, "/api/me/profile", claimsFor(user), updateProfileRequest{
		Username: &taken,
	})
	rec := httptest.NewRecorder()
	h.UpdateProfile(rec, req)
	require.Equal(t, http.StatusConflict, rec.Code)
}
