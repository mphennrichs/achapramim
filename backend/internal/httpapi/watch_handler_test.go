package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

func createTestUser(t *testing.T, pool *pgxpool.Pool, role string) sqlcgen.User {
	t.Helper()
	q := sqlcgen.New(pool)
	user, err := q.CreateUser(context.Background(), sqlcgen.CreateUserParams{
		Name:         "Test User",
		Email:        role + "-" + uuid.NewString() + "@example.com",
		PasswordHash: "hash",
		Role:         role,
	})
	require.NoError(t, err)
	return user
}

func claimsFor(user sqlcgen.User) *auth.Claims {
	return &auth.Claims{UserID: uuidString(user.ID), Role: user.Role}
}

func newWatchRequest(t *testing.T, method, target string, claims *auth.Claims, body any) *http.Request {
	t.Helper()
	var buf bytes.Buffer
	if body != nil {
		require.NoError(t, json.NewEncoder(&buf).Encode(body))
	}
	req := httptest.NewRequest(method, target, &buf)
	req = req.WithContext(auth.WithClaims(req.Context(), claims))
	return req
}

func withChiParam(req *http.Request, key, value string) *http.Request {
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add(key, value)
	return req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
}

func sampleWatchBody() watchRequest {
	return watchRequest{
		Name:                      "PS5 barato",
		TargetPriceCents:          250000,
		TolerancePercent:          "5.00",
		MaxOffers:                 20,
		PriceDropThresholdPercent: "10.00",
		Keywords:                  []string{"playstation", "ps5"},
		BlockedWords:              []string{"quebrado"},
		Marketplaces:              []string{"mercado_livre", "olx"},
	}
}

func TestWatchHandler_CreateAndGet(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool)

	req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created watchResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.Equal(t, "PS5 barato", created.Name)
	require.ElementsMatch(t, []string{"playstation", "ps5"}, created.Keywords)
	require.ElementsMatch(t, []string{"quebrado"}, created.BlockedWords)
	require.ElementsMatch(t, []string{"mercado_livre", "olx"}, created.Marketplaces)
	require.True(t, created.Active)

	getReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID, claims, nil), "id", created.ID)
	getRec := httptest.NewRecorder()
	h.Get(getRec, getReq)
	require.Equal(t, http.StatusOK, getRec.Code, getRec.Body.String())

	var fetched watchResponse
	require.NoError(t, json.Unmarshal(getRec.Body.Bytes(), &fetched))
	require.Equal(t, created.ID, fetched.ID)
}

func TestWatchHandler_GetDeniedForOtherUser(t *testing.T) {
	pool := newTestPool(t)
	owner := createTestUser(t, pool, "user")
	other := createTestUser(t, pool, "user")
	h := NewWatchHandler(pool)

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claimsFor(owner), sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	require.Equal(t, http.StatusCreated, createRec.Code)

	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	getReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID, claimsFor(other), nil), "id", created.ID)
	getRec := httptest.NewRecorder()
	h.Get(getRec, getReq)
	require.Equal(t, http.StatusNotFound, getRec.Code)
}

func TestWatchHandler_AdminCanAccessOthersWatch(t *testing.T) {
	pool := newTestPool(t)
	owner := createTestUser(t, pool, "user")
	admin := createTestUser(t, pool, "admin")
	h := NewWatchHandler(pool)

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claimsFor(owner), sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	require.Equal(t, http.StatusCreated, createRec.Code)

	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	getReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID, claimsFor(admin), nil), "id", created.ID)
	getRec := httptest.NewRecorder()
	h.Get(getRec, getReq)
	require.Equal(t, http.StatusOK, getRec.Code)
}

func TestWatchHandler_Update(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool)

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	updated := sampleWatchBody()
	updated.Name = "PS5 mais barato ainda"
	updated.Keywords = []string{"playstation 5"}
	updated.BlockedWords = nil
	updated.Marketplaces = []string{"facebook_marketplace"}

	updateReq := withChiParam(newWatchRequest(t, http.MethodPut, "/api/watches/"+created.ID, claims, updated), "id", created.ID)
	updateRec := httptest.NewRecorder()
	h.Update(updateRec, updateReq)
	require.Equal(t, http.StatusOK, updateRec.Code, updateRec.Body.String())

	var result watchResponse
	require.NoError(t, json.Unmarshal(updateRec.Body.Bytes(), &result))
	require.Equal(t, "PS5 mais barato ainda", result.Name)
	require.ElementsMatch(t, []string{"playstation 5"}, result.Keywords)
	require.Empty(t, result.BlockedWords)
	require.ElementsMatch(t, []string{"facebook_marketplace"}, result.Marketplaces)
}

func TestWatchHandler_SetActiveAndDelete(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool)

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))
	require.True(t, created.Active)

	deactivateReq := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/watches/"+created.ID+"/active", claims, setActiveRequest{Active: false}), "id", created.ID)
	deactivateRec := httptest.NewRecorder()
	h.SetActive(deactivateRec, deactivateReq)
	require.Equal(t, http.StatusOK, deactivateRec.Code, deactivateRec.Body.String())

	var deactivated watchResponse
	require.NoError(t, json.Unmarshal(deactivateRec.Body.Bytes(), &deactivated))
	require.False(t, deactivated.Active)

	deleteReq := withChiParam(newWatchRequest(t, http.MethodDelete, "/api/watches/"+created.ID, claims, nil), "id", created.ID)
	deleteRec := httptest.NewRecorder()
	h.Delete(deleteRec, deleteReq)
	require.Equal(t, http.StatusNoContent, deleteRec.Code)

	getReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID, claims, nil), "id", created.ID)
	getRec := httptest.NewRecorder()
	h.Get(getRec, getReq)
	require.Equal(t, http.StatusNotFound, getRec.Code)
}

func TestWatchHandler_List(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool)

	for i := 0; i < 2; i++ {
		req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
		rec := httptest.NewRecorder()
		h.Create(rec, req)
		require.Equal(t, http.StatusCreated, rec.Code)
	}

	listReq := newWatchRequest(t, http.MethodGet, "/api/watches", claims, nil)
	listRec := httptest.NewRecorder()
	h.List(listRec, listReq)
	require.Equal(t, http.StatusOK, listRec.Code)

	var watches []watchResponse
	require.NoError(t, json.Unmarshal(listRec.Body.Bytes(), &watches))
	require.Len(t, watches, 2)
}
