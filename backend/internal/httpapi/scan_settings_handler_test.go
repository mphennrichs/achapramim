package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestScanSettingsHandler_GetDefaults(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	h := NewScanSettingsHandler(pool)

	req := newWatchRequest(t, http.MethodGet, "/api/scan-settings", claimsFor(user), nil)
	rec := httptest.NewRecorder()
	h.Get(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var settings scanSettingsResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &settings))
	require.Equal(t, int32(30), settings.MinIntervalMinutes)
	require.Equal(t, int32(120), settings.MaxIntervalMinutes)
	require.Equal(t, "Belo Horizonte", settings.DefaultCity)
	require.Equal(t, "MG", settings.DefaultState)
	require.ElementsMatch(t, []string{
		"quebrado", "quebrada", "sucata", "para peças", "para peca", "para pecas",
		"no estado", "avariado", "avariada", "danificado", "danificada",
		"defeito", "com defeito", "não funciona", "nao funciona",
	}, settings.DefaultBlockedWords)
}

func TestScanSettingsHandler_Update(t *testing.T) {
	pool := newTestPool(t)
	admin := createTestUser(t, pool, "admin")
	h := NewScanSettingsHandler(pool)

	req := newWatchRequest(t, http.MethodPut, "/api/scan-settings", claimsFor(admin), scanSettingsRequest{
		MinIntervalMinutes:  15,
		MaxIntervalMinutes:  60,
		DefaultCity:         "Curitiba",
		DefaultState:        "PR",
		DefaultBlockedWords: []string{"quebrado", "Quebrado", "sucata"},
	})
	rec := httptest.NewRecorder()
	h.Update(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var updated scanSettingsResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &updated))
	require.Equal(t, int32(15), updated.MinIntervalMinutes)
	require.Equal(t, int32(60), updated.MaxIntervalMinutes)
	require.Equal(t, "Curitiba", updated.DefaultCity)
	require.Equal(t, "PR", updated.DefaultState)
	require.ElementsMatch(t, []string{"quebrado", "sucata"}, updated.DefaultBlockedWords)

	getReq := newWatchRequest(t, http.MethodGet, "/api/scan-settings", claimsFor(admin), nil)
	getRec := httptest.NewRecorder()
	h.Get(getRec, getReq)
	var fetched scanSettingsResponse
	require.NoError(t, json.Unmarshal(getRec.Body.Bytes(), &fetched))
	require.Equal(t, int32(15), fetched.MinIntervalMinutes)
	require.ElementsMatch(t, []string{"quebrado", "sucata"}, fetched.DefaultBlockedWords)
}

func TestScanSettingsHandler_UpdateRejectsMaxBelowMin(t *testing.T) {
	pool := newTestPool(t)
	admin := createTestUser(t, pool, "admin")
	h := NewScanSettingsHandler(pool)

	req := newWatchRequest(t, http.MethodPut, "/api/scan-settings", claimsFor(admin), scanSettingsRequest{
		MinIntervalMinutes: 60,
		MaxIntervalMinutes: 30,
	})
	rec := httptest.NewRecorder()
	h.Update(rec, req)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}
