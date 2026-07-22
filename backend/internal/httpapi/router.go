package httpapi

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
)

type Deps struct {
	Pool            *pgxpool.Pool
	Issuer          *auth.TokenIssuer
	RefreshTokenTTL time.Duration
}

func NewRouter(deps Deps) http.Handler {
	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Get("/api/health", handleHealth)

	authHandler := NewAuthHandler(deps.Pool, deps.Issuer, deps.RefreshTokenTTL)
	r.Post("/api/auth/login", authHandler.Login)
	r.Post("/api/auth/refresh", authHandler.Refresh)

	r.Group(func(r chi.Router) {
		r.Use(auth.Middleware(deps.Issuer))

		watchHandler := NewWatchHandler(deps.Pool)
		r.Post("/api/watches", watchHandler.Create)
		r.Get("/api/watches", watchHandler.List)
		r.Get("/api/watches/{id}", watchHandler.Get)
		r.Put("/api/watches/{id}", watchHandler.Update)
		r.Patch("/api/watches/{id}/active", watchHandler.SetActive)
		r.Delete("/api/watches/{id}", watchHandler.Delete)

		offerHandler := NewOfferHandler(deps.Pool)
		r.Get("/api/watches/{id}/offers", offerHandler.List)
		r.Get("/api/watches/{id}/offers/{offerId}/price-history", offerHandler.PriceHistory)
		r.Get("/api/watches/{id}/scans", offerHandler.ListScans)

		r.Group(func(r chi.Router) {
			r.Use(auth.RequireAdmin)

			userHandler := NewUserHandler(deps.Pool)
			r.Post("/api/users", userHandler.Create)
			r.Get("/api/users", userHandler.List)
			r.Patch("/api/users/{id}/role", userHandler.SetRole)
			r.Patch("/api/users/{id}/active", userHandler.SetActive)
		})
	})

	return r
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
