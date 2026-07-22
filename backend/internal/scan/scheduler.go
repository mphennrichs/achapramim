package scan

import (
	"context"
	"log/slog"
	"math/rand/v2"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

// Scheduler varre periodicamente os Watches prontos para rodar (DueWatches
// — ativos, dono ativo, next_scan_at já passou) e dispara um Scan para
// cada um via Runner. O próximo Scan de cada Watch é reagendado para um
// instante aleatório dentro do intervalo mín/máx global (scan_settings).
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

	watches, err := q.DueWatches(ctx)
	if err != nil {
		slog.Error("failed to list due watches", "error", err)
		return
	}

	settings, err := q.GetScanSettings(ctx)
	if err != nil {
		slog.Error("failed to load scan settings", "error", err)
		return
	}

	for _, watch := range watches {
		go s.runAndReschedule(ctx, watch, settings)
	}
}

func (s *Scheduler) runAndReschedule(ctx context.Context, watch sqlcgen.Watch, settings sqlcgen.ScanSetting) {
	if err := s.runner.RunWatch(ctx, watch); err != nil {
		slog.Error("scan run failed", "watch_id", watch.ID, "error", err)
	}

	next := nextScanTime(settings.MinIntervalMinutes, settings.MaxIntervalMinutes)
	q := sqlcgen.New(s.pool)
	if err := q.RescheduleWatch(ctx, sqlcgen.RescheduleWatchParams{
		ID:         watch.ID,
		NextScanAt: pgtype.Timestamptz{Time: next, Valid: true},
	}); err != nil {
		slog.Error("failed to reschedule watch", "watch_id", watch.ID, "error", err)
	}
}

func nextScanTime(minMinutes, maxMinutes int32) time.Time {
	span := maxMinutes - minMinutes
	offset := minMinutes
	if span > 0 {
		offset += rand.Int32N(span + 1)
	}
	return time.Now().Add(time.Duration(offset) * time.Minute)
}
