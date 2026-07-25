package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
	"github.com/mphennrichs/achapramim/backend/internal/scan"
)

func seedOfferAndScan(t *testing.T, q *sqlcgen.Queries, watch sqlcgen.Watch) (sqlcgen.Scan, sqlcgen.Offer) {
	t.Helper()
	ctx := context.Background()

	marketplaceSlug := "olx"
	scan, err := q.CreateScan(ctx, sqlcgen.CreateScanParams{WatchID: watch.ID, MarketplaceSlug: &marketplaceSlug})
	require.NoError(t, err)

	_, err = q.FinishScan(ctx, sqlcgen.FinishScanParams{ID: scan.ID, Status: sqlcgen.ScanStatusSuccess, OffersFound: 1, NewOffersCount: 1})
	require.NoError(t, err)

	var classification pgtype.Numeric
	require.NoError(t, classification.Scan("0.9000"))

	upserted, err := q.UpsertOffer(ctx, sqlcgen.UpsertOfferParams{
		WatchID:         watch.ID,
		MarketplaceSlug: "olx",
		ExternalID:      "abc123",
		Url:             "https://olx.com.br/abc123",
		Title:           "PlayStation 5 novo lacrado",
		ImageUrl:        "https://img/1.jpg",
		PriceCents:      250000,
		Classification:  classification,
		FirstSeenScanID: scan.ID,
	})
	require.NoError(t, err)

	require.NoError(t, q.InsertOfferPricePointIfChanged(ctx, sqlcgen.InsertOfferPricePointIfChangedParams{
		OfferID:    upserted.ID,
		PriceCents: 250000,
		ScanID:     scan.ID,
	}))

	offer, err := q.GetOfferByID(ctx, upserted.ID)
	require.NoError(t, err)
	return scan, offer
}

func TestOfferHandler_ListOffers(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)

	watchHandler := NewWatchHandler(pool, scan.NewRunner(pool, nil))
	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	watchHandler.Create(createRec, createReq)
	require.Equal(t, http.StatusCreated, createRec.Code)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	q := sqlcgen.New(pool)
	watch, err := q.GetWatchByID(context.Background(), parseUUID(created.ID))
	require.NoError(t, err)
	seedOfferAndScan(t, q, watch)

	offerHandler := NewOfferHandler(pool)
	listReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID+"/offers", claims, nil), "id", created.ID)
	listRec := httptest.NewRecorder()
	offerHandler.List(listRec, listReq)
	require.Equal(t, http.StatusOK, listRec.Code, listRec.Body.String())

	var offers []offerResponse
	require.NoError(t, json.Unmarshal(listRec.Body.Bytes(), &offers))
	require.Len(t, offers, 1)
	require.Equal(t, "PlayStation 5 novo lacrado", offers[0].Title)
}

func TestOfferHandler_ListOffersDeniedForOtherUser(t *testing.T) {
	pool := newTestPool(t)
	owner := createTestUser(t, pool, "user")
	other := createTestUser(t, pool, "user")

	watchHandler := NewWatchHandler(pool, scan.NewRunner(pool, nil))
	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claimsFor(owner), sampleWatchBody())
	createRec := httptest.NewRecorder()
	watchHandler.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	offerHandler := NewOfferHandler(pool)
	listReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID+"/offers", claimsFor(other), nil), "id", created.ID)
	listRec := httptest.NewRecorder()
	offerHandler.List(listRec, listReq)
	require.Equal(t, http.StatusNotFound, listRec.Code)
}

func TestOfferHandler_PriceHistory(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)

	watchHandler := NewWatchHandler(pool, scan.NewRunner(pool, nil))
	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	watchHandler.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	q := sqlcgen.New(pool)
	watch, err := q.GetWatchByID(context.Background(), parseUUID(created.ID))
	require.NoError(t, err)
	_, offer := seedOfferAndScan(t, q, watch)

	offerHandler := NewOfferHandler(pool)
	req := withChiParams(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID+"/offers/"+uuidString(offer.ID)+"/price-history", claims, nil), map[string]string{
		"id":      created.ID,
		"offerId": uuidString(offer.ID),
	})
	rec := httptest.NewRecorder()
	offerHandler.PriceHistory(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var points []pricePointResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &points))
	require.Len(t, points, 1)
	require.Equal(t, int64(250000), points[0].PriceCents)
}

func TestOfferHandler_SetMonitored(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)

	watchHandler := NewWatchHandler(pool, scan.NewRunner(pool, nil))
	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	watchHandler.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	q := sqlcgen.New(pool)
	watch, err := q.GetWatchByID(context.Background(), parseUUID(created.ID))
	require.NoError(t, err)
	_, offer := seedOfferAndScan(t, q, watch)

	offerHandler := NewOfferHandler(pool)
	body := map[string]bool{"monitored": true}
	req := withChiParams(newWatchRequest(t, http.MethodPatch, "/api/watches/"+created.ID+"/offers/"+uuidString(offer.ID)+"/monitored", claims, body), map[string]string{
		"id":      created.ID,
		"offerId": uuidString(offer.ID),
	})
	rec := httptest.NewRecorder()
	offerHandler.SetMonitored(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var resp offerResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.True(t, resp.Monitored)

	listReq := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID+"/offers", claims, nil), "id", created.ID)
	listRec := httptest.NewRecorder()
	offerHandler.List(listRec, listReq)
	var offers []offerResponse
	require.NoError(t, json.Unmarshal(listRec.Body.Bytes(), &offers))
	require.Len(t, offers, 1)
	require.True(t, offers[0].Monitored)
}

func TestOfferHandler_SetMonitoredDeniedForOtherUser(t *testing.T) {
	pool := newTestPool(t)
	owner := createTestUser(t, pool, "user")
	other := createTestUser(t, pool, "user")

	watchHandler := NewWatchHandler(pool, scan.NewRunner(pool, nil))
	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claimsFor(owner), sampleWatchBody())
	createRec := httptest.NewRecorder()
	watchHandler.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	q := sqlcgen.New(pool)
	watch, err := q.GetWatchByID(context.Background(), parseUUID(created.ID))
	require.NoError(t, err)
	_, offer := seedOfferAndScan(t, q, watch)

	offerHandler := NewOfferHandler(pool)
	body := map[string]bool{"monitored": true}
	req := withChiParams(newWatchRequest(t, http.MethodPatch, "/api/watches/"+created.ID+"/offers/"+uuidString(offer.ID)+"/monitored", claimsFor(other), body), map[string]string{
		"id":      created.ID,
		"offerId": uuidString(offer.ID),
	})
	rec := httptest.NewRecorder()
	offerHandler.SetMonitored(rec, req)
	require.Equal(t, http.StatusNotFound, rec.Code)
}

func TestOfferHandler_ListScans(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	claims := claimsFor(user)

	watchHandler := NewWatchHandler(pool, scan.NewRunner(pool, nil))
	createReq := newWatchRequest(t, http.MethodPost, "/api/watches", claims, sampleWatchBody())
	createRec := httptest.NewRecorder()
	watchHandler.Create(createRec, createReq)
	var created watchResponse
	require.NoError(t, json.Unmarshal(createRec.Body.Bytes(), &created))

	q := sqlcgen.New(pool)
	watch, err := q.GetWatchByID(context.Background(), parseUUID(created.ID))
	require.NoError(t, err)
	seedOfferAndScan(t, q, watch)

	offerHandler := NewOfferHandler(pool)
	req := withChiParam(newWatchRequest(t, http.MethodGet, "/api/watches/"+created.ID+"/scans", claims, nil), "id", created.ID)
	rec := httptest.NewRecorder()
	offerHandler.ListScans(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var scans []scanResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &scans))
	require.Len(t, scans, 1)
	require.Equal(t, "success", scans[0].Status)
	require.Equal(t, int32(1), scans[0].OffersFound)
	require.Empty(t, scans[0].Failures)
}
