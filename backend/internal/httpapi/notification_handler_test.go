package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
	"github.com/mphennrichs/achapramim/backend/internal/scan"
)

func seedPriceDropNotification(t *testing.T, q *sqlcgen.Queries, watch sqlcgen.Watch) sqlcgen.Notification {
	t.Helper()
	ctx := context.Background()
	_, offer := seedOfferAndScan(t, q, watch)

	n, err := q.CreatePriceDropNotification(ctx, sqlcgen.CreatePriceDropNotificationParams{
		UserID:  watch.UserID,
		OfferID: offer.ID,
	})
	require.NoError(t, err)
	return n
}

func TestNotificationHandler_List(t *testing.T) {
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
	seedPriceDropNotification(t, q, watch)

	notificationHandler := NewNotificationHandler(pool)
	req := newWatchRequest(t, http.MethodGet, "/api/notifications", claims, nil)
	rec := httptest.NewRecorder()
	notificationHandler.List(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var notifications []notificationResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &notifications))
	require.Len(t, notifications, 1)
	require.Equal(t, "price_drop", notifications[0].Trigger)
	require.Equal(t, "PlayStation 5 novo lacrado", notifications[0].OfferTitle)
	require.Nil(t, notifications[0].ReadAt)
}

func TestNotificationHandler_ListOnlyReturnsOwnNotifications(t *testing.T) {
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
	seedPriceDropNotification(t, q, watch)

	notificationHandler := NewNotificationHandler(pool)
	req := newWatchRequest(t, http.MethodGet, "/api/notifications", claimsFor(other), nil)
	rec := httptest.NewRecorder()
	notificationHandler.List(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var notifications []notificationResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &notifications))
	require.Empty(t, notifications)
}

func TestNotificationHandler_MarkReadAndUnreadCount(t *testing.T) {
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
	notification := seedPriceDropNotification(t, q, watch)

	notificationHandler := NewNotificationHandler(pool)

	countReq := newWatchRequest(t, http.MethodGet, "/api/notifications/unread-count", claims, nil)
	countRec := httptest.NewRecorder()
	notificationHandler.UnreadCount(countRec, countReq)
	require.Equal(t, http.StatusOK, countRec.Code)
	var count unreadCountResponse
	require.NoError(t, json.Unmarshal(countRec.Body.Bytes(), &count))
	require.Equal(t, int64(1), count.Count)

	markReq := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/notifications/"+uuidString(notification.ID)+"/read", claims, nil), "id", uuidString(notification.ID))
	markRec := httptest.NewRecorder()
	notificationHandler.MarkRead(markRec, markReq)
	require.Equal(t, http.StatusNoContent, markRec.Code)

	countRec2 := httptest.NewRecorder()
	notificationHandler.UnreadCount(countRec2, countReq)
	var count2 unreadCountResponse
	require.NoError(t, json.Unmarshal(countRec2.Body.Bytes(), &count2))
	require.Equal(t, int64(0), count2.Count)
}

func TestNotificationHandler_MarkReadDeniedForOtherUser(t *testing.T) {
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
	notification := seedPriceDropNotification(t, q, watch)

	notificationHandler := NewNotificationHandler(pool)
	markReq := withChiParam(newWatchRequest(t, http.MethodPatch, "/api/notifications/"+uuidString(notification.ID)+"/read", claimsFor(other), nil), "id", uuidString(notification.ID))
	markRec := httptest.NewRecorder()
	notificationHandler.MarkRead(markRec, markReq)
	require.Equal(t, http.StatusNotFound, markRec.Code)
}
