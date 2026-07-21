package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestUserHandler_CreateAndList(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)

	req := newWatchRequest(t, http.MethodPost, "/api/users", nil, createUserRequest{
		Name:     "Fulano",
		Email:    "fulano@example.com",
		Password: "supersecret",
		Role:     "user",
	})
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created userResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.Equal(t, "fulano@example.com", created.Email)
	require.Equal(t, "user", created.Role)
	require.True(t, created.Active)

	listReq := newWatchRequest(t, http.MethodGet, "/api/users", nil, nil)
	listRec := httptest.NewRecorder()
	h.List(listRec, listReq)
	require.Equal(t, http.StatusOK, listRec.Code)

	var users []userResponse
	require.NoError(t, json.Unmarshal(listRec.Body.Bytes(), &users))
	require.Len(t, users, 1)
}

func TestUserHandler_CreateRejectsShortPassword(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)

	req := newWatchRequest(t, http.MethodPost, "/api/users", nil, createUserRequest{
		Name:     "Fulano",
		Email:    "fulano@example.com",
		Password: "123",
		Role:     "user",
	})
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestUserHandler_SetRole(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)
	user := createTestUser(t, pool, "user")

	req := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/users/"+uuidString(user.ID)+"/role", nil, setUserRoleRequest{Role: "admin"}), "id", uuidString(user.ID))
	rec := httptest.NewRecorder()
	h.SetRole(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var updated userResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &updated))
	require.Equal(t, "admin", updated.Role)
}

func TestUserHandler_SetActive(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)
	user := createTestUser(t, pool, "user")

	req := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/users/"+uuidString(user.ID)+"/active", nil, setUserActiveRequest{Active: false}), "id", uuidString(user.ID))
	rec := httptest.NewRecorder()
	h.SetActive(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var updated userResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &updated))
	require.False(t, updated.Active)
}

func TestUserHandler_SetRoleNotFound(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)

	missingID := "00000000-0000-0000-0000-000000000000"
	req := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/users/"+missingID+"/role", nil, setUserRoleRequest{Role: "admin"}), "id", missingID)
	rec := httptest.NewRecorder()
	h.SetRole(rec, req)
	require.Equal(t, http.StatusNotFound, rec.Code)
}
