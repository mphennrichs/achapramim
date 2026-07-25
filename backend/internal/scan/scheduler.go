package scan

import (
	"context"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

// Scheduler varre periodicamente os pares (Watch, marketplace) prontos
// para rodar (DueWatchMarketplaces — Watch ativo, dono ativo,
// next_scan_at daquele marketplace já passou) e dispara um Scan para cada
// um via Runner. O próximo Scan de cada (Watch, marketplace) é reagendado
// para um instante aleatório dentro do intervalo mín/máx configurado para
// aquele marketplace (marketplace_scan_settings, com fallback pro global
// em scan_settings).
type Scheduler struct {
	pool         *pgxpool.Pool
	runner       *Runner
	pollInterval time.Duration
}

func NewScheduler(pool *pgxpool.Pool, runner *Runner, pollInterval time.Duration) *Scheduler {
	return &Scheduler{pool: pool, runner: runner, pollInterval: pollInterval}
}

// Run bloqueia até o contexto ser cancelado, verificando Watches devidos a
// cada pollInterval. Cada Watch devido roda seu Scan em sua própria
// goroutine, para que um fetcher lento não atrase os demais Watches.
func (s *Scheduler) Run(ctx context.Context) {
	ticker := time.NewTicker(s.pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.tick(ctx)
		}
	}
}

func (s *Scheduler) tick(ctx context.Context) {
	q := sqlcgen.New(s.pool)

	due, err := q.DueWatchMarketplaces(ctx)
	if err != nil {
		slog.Error("failed to list due watch marketplaces", "error", err)
		return
	}

	for _, row := range due {
		watch := sqlcgen.Watch{
			ID:                        row.ID,
			UserID:                    row.UserID,
			Name:                      row.Name,
			TargetPriceCents:          row.TargetPriceCents,
			TolerancePercent:          row.TolerancePercent,
			MaxOffers:                 row.MaxOffers,
			PriceDropThresholdPercent: row.PriceDropThresholdPercent,
			Active:                    row.Active,
			NextScanAt:                row.NextScanAt,
			CreatedAt:                 row.CreatedAt,
			UpdatedAt:                 row.UpdatedAt,
			City:                      row.City,
			State:                     row.State,
			KeywordMatchMode:          row.KeywordMatchMode,
		}
		go s.runner.RunWatchMarketplaceAndReschedule(ctx, watch, row.MarketplaceSlug)
	}
}
