package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/bootstrap"
	"github.com/mphennrichs/achapramim/backend/internal/config"
	"github.com/mphennrichs/achapramim/backend/internal/httpapi"
	"github.com/mphennrichs/achapramim/backend/internal/scan"
	"github.com/mphennrichs/achapramim/backend/internal/scan/marketplace"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	cfg, err := config.Load()
	if err != nil {
		logger.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		logger.Error("failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	if err := bootstrap.EnsureAdmin(ctx, pool, cfg.AdminEmail, cfg.AdminPassword); err != nil {
		logger.Error("failed to bootstrap initial admin", "error", err)
		os.Exit(1)
	}

	issuer := auth.NewTokenIssuer(cfg.JWTSecret, cfg.AccessTokenTTL)

	runner := scan.NewRunner(pool, []marketplace.Fetcher{
		marketplace.NewOLXFetcher(),
	})
	scheduler := scan.NewScheduler(pool, runner, cfg.ScanPollInterval)
	go scheduler.Run(ctx)

	router := httpapi.NewRouter(httpapi.Deps{
		Pool:            pool,
		Issuer:          issuer,
		RefreshTokenTTL: cfg.RefreshTokenTTL,
	})

	server := &http.Server{
		Addr:    ":" + cfg.HTTPPort,
		Handler: router,
	}

	go func() {
		logger.Info("starting http server", "port", cfg.HTTPPort)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("http server error", "error", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	logger.Info("shutting down")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Error("graceful shutdown failed", "error", err)
	}
}
