package httpapi

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

type NotificationHandler struct {
	pool *pgxpool.Pool
}

func NewNotificationHandler(pool *pgxpool.Pool) *NotificationHandler {
	return &NotificationHandler{pool: pool}
}

type notificationResponse struct {
	ID              string  `json:"id"`
	Trigger         string  `json:"trigger"`
	CreatedAt       string  `json:"created_at"`
	ReadAt          *string `json:"read_at"`
	OfferID         string  `json:"offer_id"`
	OfferTitle      string  `json:"offer_title"`
	OfferPriceCents int64   `json:"offer_price_cents"`
	OfferURL        string  `json:"offer_url"`
	WatchID         string  `json:"watch_id"`
	WatchName       string  `json:"watch_name"`
}

// List retorna as Notifications in-app do User autenticado, mais recentes
// primeiro.
func (h *NotificationHandler) List(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)

	limit := int32(50)
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 {
			limit = int32(parsed)
		}
	}

	rows, err := q.ListNotificationsByUser(ctx, sqlcgen.ListNotificationsByUserParams{
		UserID: parseUUID(claims.UserID),
		Limit:  limit,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	resp := make([]notificationResponse, len(rows))
	for i, n := range rows {
		var readAt *string
		if n.ReadAt.Valid {
			formatted := n.ReadAt.Time.Format("2006-01-02T15:04:05Z07:00")
			readAt = &formatted
		}
		resp[i] = notificationResponse{
			ID:              uuidString(n.ID),
			Trigger:         string(n.Trigger),
			CreatedAt:       n.CreatedAt.Time.Format("2006-01-02T15:04:05Z07:00"),
			ReadAt:          readAt,
			OfferID:         uuidString(n.OfferID),
			OfferTitle:      n.OfferTitle,
			OfferPriceCents: n.OfferPriceCents,
			OfferURL:        n.OfferUrl,
			WatchID:         uuidString(n.WatchID),
			WatchName:       n.WatchName,
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

type unreadCountResponse struct {
	Count int64 `json:"count"`
}

// UnreadCount retorna quantas Notifications ainda não foram lidas — usado
// pelo badge do sino na UI.
func (h *NotificationHandler) UnreadCount(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	count, err := sqlcgen.New(h.pool).CountUnreadNotifications(r.Context(), parseUUID(claims.UserID))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, unreadCountResponse{Count: count})
}

// MarkRead marca uma Notification específica como lida. Só o dono pode
// marcar a própria Notification — o filtro por user_id na query já garante
// isso (uma Notification de outro User simplesmente não é encontrada).
func (h *NotificationHandler) MarkRead(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	id := parseUUID(chi.URLParam(r, "id"))
	if _, err := sqlcgen.New(h.pool).MarkNotificationRead(r.Context(), sqlcgen.MarkNotificationReadParams{
		ID:     id,
		UserID: parseUUID(claims.UserID),
	}); err != nil {
		writeError(w, http.StatusNotFound, "notification not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// MarkAllRead marca todas as Notifications do User autenticado como lidas.
func (h *NotificationHandler) MarkAllRead(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	if err := sqlcgen.New(h.pool).MarkAllNotificationsRead(r.Context(), parseUUID(claims.UserID)); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
