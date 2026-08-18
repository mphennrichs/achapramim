package httpapi

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/linkpreview"
	"github.com/mphennrichs/achapramim/backend/internal/observability"
	"github.com/mphennrichs/achapramim/backend/internal/scan"
)

type Deps struct {
	Pool            *pgxpool.Pool
	Issuer          *auth.TokenIssuer
	RefreshTokenTTL time.Duration
	Proposer        *linkpreview.Proposer
	ApifyAPIToken   string
	Runner          *scan.Runner
	// Logger é o slog JSON do processo. Injetado (em vez de slog.Default())
	// para os testes poderem capturar a saída sem mexer em estado global.
	Logger *slog.Logger
}

func NewRouter(deps Deps) http.Handler {
	// Os testes de handler constroem Deps sem Logger; sem este fallback o
	// middleware receberia nil e quebraria em toda requisição de teste.
	if deps.Logger == nil {
		deps.Logger = slog.Default()
	}

	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	// Substitui o middleware.Logger do chi (linha de texto, não filtrável no
	// Loki) por log JSON com trace id, ator, bodies redigidos e duração.
	// O healthcheck do Docker deixa de ser logado — era ~8.6k linhas/dia.
	r.Use(observability.HTTPLogger(deps.Logger))
	r.Use(middleware.Recoverer)
	r.Use(corsMiddleware())

	r.Get("/api/health", handleHealth)

	authHandler := NewAuthHandler(deps.Pool, deps.Issuer, deps.RefreshTokenTTL)
	r.Post("/api/auth/login", authHandler.Login)
	r.Post("/api/auth/refresh", authHandler.Refresh)

	r.Group(func(r chi.Router) {
		r.Use(auth.Middleware(deps.Issuer))

		meHandler := NewMeHandler(deps.Pool)
		r.Get("/api/me", meHandler.Get)
		r.Put("/api/me/username", meHandler.SetUsername)
		r.Put("/api/me/password", meHandler.ChangePassword)
		r.Put("/api/me/profile", meHandler.UpdateProfile)

		watchHandler := NewWatchHandler(deps.Pool, deps.Runner)
		r.Post("/api/watches", watchHandler.Create)
		r.Get("/api/watches", watchHandler.List)
		r.Get("/api/watches/{id}", watchHandler.Get)
		r.Put("/api/watches/{id}", watchHandler.Update)
		r.Patch("/api/watches/{id}/active", watchHandler.SetActive)
		r.Delete("/api/watches/{id}", watchHandler.Delete)

		offerHandler := NewOfferHandler(deps.Pool)
		r.Get("/api/watches/{id}/offers", offerHandler.List)
		r.Patch("/api/watches/{id}/offers/{offerId}/monitored", offerHandler.SetMonitored)
		r.Get("/api/watches/{id}/offers/{offerId}/price-history", offerHandler.PriceHistory)
		r.Get("/api/watches/{id}/scans", offerHandler.ListScans)

		scanSettingsHandler := NewScanSettingsHandler(deps.Pool)
		r.Get("/api/scan-settings", scanSettingsHandler.Get)

		notificationHandler := NewNotificationHandler(deps.Pool)
		r.Get("/api/notifications", notificationHandler.List)
		r.Get("/api/notifications/unread-count", notificationHandler.UnreadCount)
		r.Patch("/api/notifications/{id}/read", notificationHandler.MarkRead)
		r.Post("/api/notifications/read-all", notificationHandler.MarkAllRead)

		linkPreviewHandler := NewLinkPreviewHandler(deps.Proposer)
		r.Post("/api/watches/link-preview", linkPreviewHandler.Preview)

		r.Group(func(r chi.Router) {
			r.Use(auth.RequireAdmin)

			userHandler := NewUserHandler(deps.Pool)
			r.Post("/api/users", userHandler.Create)
			r.Get("/api/users", userHandler.List)
			r.Get("/api/users/username-available", userHandler.UsernameAvailable)
			r.Patch("/api/users/{id}/role", userHandler.SetRole)
			r.Patch("/api/users/{id}/active", userHandler.SetActive)
			r.Patch("/api/users/{id}/username", userHandler.SetUsername)

			r.Put("/api/scan-settings", scanSettingsHandler.Update)

			apifyUsageHandler := NewApifyUsageHandler(deps.ApifyAPIToken)
			r.Get("/api/admin/apify-usage", apifyUsageHandler.List)

			r.Post("/api/watches/{id}/scan", watchHandler.TriggerScan)
		})
	})

	return r
}

// corsMiddleware libera o frontend web (origem distinta em desenvolvimento
// local, ou quando o deploy não coloca frontend e backend sob o mesmo
// domínio) a chamar a API. CORS_ALLOWED_ORIGINS é uma lista separada por
// vírgula; sem configuração, cai no padrão permissivo de desenvolvimento
// (qualquer localhost).
func corsMiddleware() func(http.Handler) http.Handler {
	origins := []string{"http://localhost:*", "http://127.0.0.1:*"}
	if raw := os.Getenv("CORS_ALLOWED_ORIGINS"); raw != "" {
		origins = strings.Split(raw, ",")
	}

	return cors.Handler(cors.Options{
		AllowedOrigins:   origins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Authorization", "Content-Type"},
		AllowCredentials: false,
		MaxAge:           300,
	})
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
