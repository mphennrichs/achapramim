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
	"github.com/mphennrichs/achapramim/backend/internal/scan"
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
	return withChiParams(req, map[string]string{key: value})
}

func withChiParams(req *http.Request, params map[string]string) *http.Request {
	rctx := chi.NewRouteContext()
	for key, value := range params {
		rctx.URLParams.Add(key, value)
	}
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
		Marketplaces:              []string{"olx"},
	}
}

func TestWatchHandler_CreateAndGet(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created watchResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.Equal(t, "PS5 barato", created.Name)
	require.ElementsMatch(t, []string{"playstation", "ps5"}, created.Keywords)
	// "quebrado" já está no seed global (Configurações Globais) — a lista
	// final é a união com o seed, não apenas o que foi enviado no request.
	require.Contains(t, created.BlockedWords, "quebrado")
	require.Contains(t, created.BlockedWords, "sucata")
	require.ElementsMatch(t, []string{"olx"}, created.Marketplaces)
	require.True(t, created.Active)
	require.Equal(t, "any", created.KeywordMatchMode, "default mode when omitted from the request")

	getReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID, claims, nil), "id", created.ID)
	getRec := httptest.NewRecorder()
	h.Get(getRec, getReq)
	require.Equal(t, http.StatusOK, getRec.Code, getRec.Body.String())

	var fetched watchResponse
	require.NoError(t, json.Unmarshal(getRec.Body.Bytes(), &fetched))
	require.Equal(t, created.ID, fetched.ID)
}

func TestWatchHandler_CreateWithAllKeywordMatchMode(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	body := sampleWatchBody()
	body.KeywordMatchMode = "all"
	req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, body)
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created watchResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.Equal(t, "all", created.KeywordMatchMode)
}

func TestWatchHandler_CreateRejectsInvalidKeywordMatchMode(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	body := sampleWatchBody()
	body.KeywordMatchMode = "bogus"
	req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, body)
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestWatchHandler_GetDeniedForOtherUser(t *testing.T) {
	pool := newTestPool(t)
	owner := createTestUser(t, pool, "user")
	other := createTestUser(t, pool, "user")
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

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
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

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
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	updated := sampleWatchBody()
	updated.Name = "PS5 mais barato ainda"
	updated.Keywords = []string{"playstation 5"}
	updated.BlockedWords = nil
	updated.Marketplaces = []string{"olx"}

	updateReq := withChiParam(newWatchRequest(t, http.MethodPut, "/api/watches/"+created.ID, claims, updated), "id", created.ID)
	updateRec := httptest.NewRecorder()
	h.Update(updateRec, updateReq)
	require.Equal(t, http.StatusOK, updateRec.Code, updateRec.Body.String())

	var result watchResponse
	require.NoError(t, json.Unmarshal(updateRec.Body.Bytes(), &result))
	require.Equal(t, "PS5 mais barato ainda", result.Name)
	require.ElementsMatch(t, []string{"playstation 5"}, result.Keywords)
	require.Empty(t, result.BlockedWords)
	require.ElementsMatch(t, []string{"olx"}, result.Marketplaces)
}

func TestWatchHandler_SetActiveAndDelete(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

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

// TestWatchHandler_DeleteWithOffersAndPriceHistory reproduz o bug em que
// excluir um Watch com Offers/Histórico de Preço retornava 500: as FKs
// offers.first_seen_scan_id/last_checked_scan_id e
// offer_price_points.scan_id -> scans não tinham ON DELETE CASCADE, então
// apagar os Scans (cascata de watches -> scans) violava essas constraints.
func TestWatchHandler_DeleteWithOffersAndPriceHistory(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	q := sqlcgen.New(pool)
	watch, err := q.GetWatchByID(context.Background(), parseUUID(created.ID))
	require.NoError(t, err)
	seedOfferAndScan(t, q, watch)

	deleteReq := withChiParam(newWatchRequest(t, http.MethodDelete, "/api/watches/"+created.ID, claims, nil), "id", created.ID)
	deleteRec := httptest.NewRecorder()
	h.Delete(deleteRec, deleteReq)
	require.Equal(t, http.StatusNoContent, deleteRec.Code, deleteRec.Body.String())
}

func TestWatchHandler_List(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

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

func TestWatchHandler_ListAllForAdmin(t *testing.T) {
	pool := newTestPool(t)
	owner := createTestUser(t, pool, "user")
	admin := createTestUser(t, pool, "admin")
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claimsFor(owner), sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	require.Equal(t, http.StatusCreated, createRec.Code)

	listReq := newWatchRequest(t, http.MethodGet, "/api/watches?all=true", claimsFor(admin), nil)
	listRec := httptest.NewRecorder()
	h.List(listRec, listReq)
	require.Equal(t, http.StatusOK, listRec.Code, listRec.Body.String())

	var watches []watchResponse
	require.NoError(t, json.Unmarshal(listRec.Body.Bytes(), &watches))
	require.Len(t, watches, 1)
	require.NotNil(t, watches[0].OwnerName)
	require.Equal(t, owner.Name, *watches[0].OwnerName)
	require.NotNil(t, watches[0].OwnerEmail)
	require.Equal(t, owner.Email, *watches[0].OwnerEmail)
}

func TestWatchHandler_CreateMergesDefaultBlockedWordsWithoutDuplicates(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	body := sampleWatchBody()
	// "Quebrado" (maiúsculo) e "sucata" já estão no seed global — a união
	// deve ser case-insensitive e não duplicar.
	body.BlockedWords = []string{"Quebrado", "sucata", "extra do usuário"}

	req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, body)
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created watchResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.Contains(t, created.BlockedWords, "Quebrado")
	require.Contains(t, created.BlockedWords, "extra do usuário")
	require.Contains(t, created.BlockedWords, "para peças")
	// "sucata" só aparece uma vez (do request, não duplicado pelo seed).
	count := 0
	for _, w := range created.BlockedWords {
		if w == "sucata" {
			count++
		}
	}
	require.Equal(t, 1, count)
}

func TestWatchHandler_UpdateDoesNotReapplyDefaultBlockedWordsSeed(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))
	require.Contains(t, created.BlockedWords, "sucata")

	updated := sampleWatchBody()
	updated.BlockedWords = []string{"palavra específica"}

	updateReq := withChiParam(newWatchRequest(t, http.MethodPut, "/api/watches/"+created.ID, claims, updated), "id", created.ID)
	updateRec := httptest.NewRecorder()
	h.Update(updateRec, updateReq)
	require.Equal(t, http.StatusOK, updateRec.Code, updateRec.Body.String())

	var result watchResponse
	require.NoError(t, json.Unmarshal(updateRec.Body.Bytes(), &result))
	// Update é replace completo, sem reaplicar o seed — só o que o usuário
	// mandou desta vez.
	require.ElementsMatch(t, []string{"palavra específica"}, result.BlockedWords)
}

func TestWatchHandler_CreateWithRegionOverridesGlobalDefault(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	city := "Curitiba"
	state := "PR"
	body := sampleWatchBody()
	body.City = &city
	body.State = &state

	req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, body)
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created watchResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.NotNil(t, created.City)
	require.Equal(t, "Curitiba", *created.City)
	require.NotNil(t, created.State)
	require.Equal(t, "PR", *created.State)
}

func TestWatchHandler_CreateWithoutRegionLeavesFieldsNil(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	req := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	rec := httptest.NewRecorder()
	h.Create(rec, req)
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())

	var created watchResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))
	require.Nil(t, created.City)
	require.Nil(t, created.State)
}

func TestWatchHandler_ListAllIgnoredForNonAdmin(t *testing.T) {
	pool := newTestPool(t)
	owner := createTestUser(t, pool, "user")
	other := createTestUser(t, pool, "user")
	h := NewWatchHandler(pool, scan.NewRunner(pool, nil))

	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claimsFor(owner), sampleWatchBody())
	createRec := httptest.NewRecorder()
	h.Create(createRec, createReq)
	require.Equal(t, http.StatusCreated, createRec.Code)

	// ?all=true só tem efeito para admin — um User comum continua vendo
	// apenas os próprios Watches, mesmo pedindo all=true.
	listReq := newWatchRequest(t, http.MethodGet, "/api/watches?all=true", claimsFor(other), nil)
	listRec := httptest.NewRecorder()
	h.List(listRec, listReq)
	require.Equal(t, http.StatusOK, listRec.Code)

	var watches []watchResponse
	require.NoError(t, json.Unmarshal(listRec.Body.Bytes(), &watches))
	require.Len(t, watches, 0)
}
