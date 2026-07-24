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

func TestUserHandler_CreateWithUsername(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)

	username := "fulano_dev"
	req := newWatchRequest(t, http.MethodPost, "/api/users", nil, createUserRequest{
		Name:     "Fulano",
		Email:    "fulano2@example.com",
		Password: "supersecret",
		Role:     "user",
		Username: &username,
	})
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created userResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.NotNil(t, created.Username)
	require.Equal(t, "fulano_dev", *created.Username)
}

func TestUserHandler_CreateRejectsInvalidUsername(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)

	username := "Ab"
	req := newWatchRequest(t, http.MethodPost, "/api/users", nil, createUserRequest{
		Name:     "Fulano",
		Email:    "fulano3@example.com",
		Password: "supersecret",
		Role:     "user",
		Username: &username,
	})
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestUserHandler_SetUsername(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)
	user := createTestUser(t, pool, "user")

	req := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/users/"+uuidString(user.ID)+"/username", nil, setUserUsernameRequest{Username: "carol_dev"}), "id", uuidString(user.ID))
	rec := httptest.NewRecorder()
	h.SetUsername(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var updated userResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &updated))
	require.NotNil(t, updated.Username)
	require.Equal(t, "carol_dev", *updated.Username)
}

func TestUserHandler_SetUsernameRejectsDuplicate(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)
	existing := createTestUser(t, pool, "user")
	other := createTestUser(t, pool, "user")

	takeReq := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/users/"+uuidString(existing.ID)+"/username", nil, setUserUsernameRequest{Username: "taken_name"}), "id", uuidString(existing.ID))
	takeRec := httptest.NewRecorder()
	h.SetUsername(takeRec, takeReq)
	require.Equal(t, http.StatusOK, takeRec.Code, takeRec.Body.String())

	req := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/users/"+uuidString(other.ID)+"/username", nil, setUserUsernameRequest{Username: "taken_name"}), "id", uuidString(other.ID))
	rec := httptest.NewRecorder()
	h.SetUsername(rec, req)
	require.Equal(t, http.StatusConflict, rec.Code)
}

func TestUserHandler_SetUsernameNotFound(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)

	missingID := "00000000-0000-0000-0000-000000000000"
	req := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/users/"+missingID+"/username", nil, setUserUsernameRequest{Username: "ghost_user"}), "id", missingID)
	rec := httptest.NewRecorder()
	h.SetUsername(rec, req)
	require.Equal(t, http.StatusNotFound, rec.Code)
}

func TestUserHandler_UsernameAvailable(t *testing.T) {
	pool := newTestPool(t)
	h := NewUserHandler(pool)

	takenUsername := "already_taken"
	createReq := newWatchRequest(t, http.MethodPost, "/api/users", nil, createUserRequest{
		Name:     "Fulano",
		Email:    "fulano4@example.com",
		Password: "supersecret",
		Role:     "user",
		Username: &takenUsername,
	})
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	require.Equal(t, http.StatusCreated, createRec.Code)

	takenReq := newWatchRequest(t, http.MethodGet, "/api/users/username-available?u=already_taken", nil, nil)
	takenRec := httptest.NewRecorder()
	h.UsernameAvailable(takenRec, takenReq)
	require.Equal(t, http.StatusOK, takenRec.Code)
	var takenResp usernameAvailableResponse
	require.NoError(t, json.Unmarshal(takenRec.Body.Bytes(), &takenResp))
	require.False(t, takenResp.Available)

	freeReq := newWatchRequest(t, http.MethodGet, "/api/users/username-available?u=totally_free", nil, nil)
	freeRec := httptest.NewRecorder()
	h.UsernameAvailable(freeRec, freeReq)
	require.Equal(t, http.StatusOK, freeRec.Code)
	var freeResp usernameAvailableResponse
	require.NoError(t, json.Unmarshal(freeRec.Body.Bytes(), &freeResp))
	require.True(t, freeResp.Available)

	invalidReq := newWatchRequest(t, http.MethodGet, "/api/users/username-available?u=AB", nil, nil)
	invalidRec := httptest.NewRecorder()
	h.UsernameAvailable(invalidRec, invalidReq)
	require.Equal(t, http.StatusOK, invalidRec.Code)
	var invalidResp usernameAvailableResponse
	require.NoError(t, json.Unmarshal(invalidRec.Body.Bytes(), &invalidResp))
	require.False(t, invalidResp.Available)
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
