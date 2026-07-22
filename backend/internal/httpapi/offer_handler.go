package httpapi

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

type OfferHandler struct {
	pool *pgxpool.Pool
}

func NewOfferHandler(pool *pgxpool.Pool) *OfferHandler {
	return &OfferHandler{pool: pool}
}

type offerResponse struct {
	ID              string `json:"id"`
	MarketplaceSlug string `json:"marketplace_slug"`
	URL             string `json:"url"`
	Title           string `json:"title"`
	ImageURL        string `json:"image_url"`
	PriceCents      int64  `json:"price_cents"`
	Classification  string `json:"classification"`
	Available       bool   `json:"available"`
}

type pricePointResponse struct {
	PriceCents int64  `json:"price_cents"`
	ObservedAt string `json:"observed_at"`
}

// List retorna as Offers atualmente exibidas (disponíveis, dentro do
// top-N) de um Watch, ordenadas por Classificação — as únicas
// reverificadas a cada Scan, conforme o domínio.
func (h *OfferHandler) List(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)
	watchID := parseUUID(chi.URLParam(r, "id"))

	watch, ok := getOwnedWatch(ctx, w, q, watchID, claims)
	if !ok {
		return
	}

	offers, err := q.TopOffersByWatch(ctx, sqlcgen.TopOffersByWatchParams{
		WatchID: watchID,
		Limit:   watch.MaxOffers,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	resp := make([]offerResponse, len(offers))
	for i, o := range offers {
		resp[i] = offerResponse{
			ID:              uuidString(o.ID),
			MarketplaceSlug: o.MarketplaceSlug,
			URL:             o.Url,
			Title:           o.Title,
			ImageURL:        o.ImageUrl,
			PriceCents:      o.PriceCents,
			Classification:  numericString(o.Classification),
			Available:       o.Available,
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

// PriceHistory retorna o Histórico de Preço de uma Offer específica. A
// Offer precisa pertencer ao Watch informado na URL, e o Watch precisa
// pertencer ao User autenticado (ou o User ser admin) — evita que alguém
// acesse o histórico de uma Offer de outro Watch só adivinhando o ID.
func (h *OfferHandler) PriceHistory(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)
	watchID := parseUUID(chi.URLParam(r, "id"))

	if _, ok := getOwnedWatch(ctx, w, q, watchID, claims); !ok {
		return
	}

	offerID := parseUUID(chi.URLParam(r, "offerId"))
	offer, err := q.GetOfferByID(ctx, offerID)
	if err != nil {
		writeError(w, http.StatusNotFound, "offer not found")
		return
	}
	if uuidString(offer.WatchID) != chi.URLParam(r, "id") {
		writeError(w, http.StatusNotFound, "offer not found")
		return
	}

	points, err := q.ListOfferPricePoints(ctx, offerID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	resp := make([]pricePointResponse, len(points))
	for i, p := range points {
		resp[i] = pricePointResponse{
			PriceCents: p.PriceCents,
			ObservedAt: p.ObservedAt.Time.Format("2006-01-02T15:04:05Z07:00"),
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

type scanResponse struct {
	ID          string   `json:"id"`
	Status      string   `json:"status"`
	StartedAt   string   `json:"started_at"`
	FinishedAt  *string  `json:"finished_at"`
	OffersFound int32    `json:"offers_found"`
	Failures    []string `json:"failed_marketplaces"`
}

// ListScans retorna o histórico de Scans de um Watch, mais recentes
// primeiro, com os marketplaces que falharam em cada um (sucesso parcial).
func (h *OfferHandler) ListScans(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)
	watchID := parseUUID(chi.URLParam(r, "id"))

	if _, ok := getOwnedWatch(ctx, w, q, watchID, claims); !ok {
		return
	}

	limit := int32(50)
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 {
			limit = int32(parsed)
		}
	}

	scans, err := q.ListScansByWatch(ctx, sqlcgen.ListScansByWatchParams{WatchID: watchID, Limit: limit})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	resp := make([]scanResponse, len(scans))
	for i, s := range scans {
		failures, err := q.ListScanMarketplaceFailures(ctx, s.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "internal error")
			return
		}
		failedSlugs := make([]string, len(failures))
		for j, f := range failures {
			failedSlugs[j] = f.MarketplaceSlug
		}

		var finishedAt *string
		if s.FinishedAt.Valid {
			formatted := s.FinishedAt.Time.Format("2006-01-02T15:04:05Z07:00")
			finishedAt = &formatted
		}

		resp[i] = scanResponse{
			ID:          uuidString(s.ID),
			Status:      string(s.Status),
			StartedAt:   s.StartedAt.Time.Format("2006-01-02T15:04:05Z07:00"),
			FinishedAt:  finishedAt,
			OffersFound: s.OffersFound,
			Failures:    failedSlugs,
		}
	}
	writeJSON(w, http.StatusOK, resp)
}
