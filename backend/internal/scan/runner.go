package scan

import (
	"context"
	"fmt"
	"log/slog"
	"math/rand/v2"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
	"github.com/mphennrichs/achapramim/backend/internal/scan/marketplace"
)

// Runner executa um Scan por (Watch, marketplace): consulta o Fetcher do
// marketplace configurado, filtra por palavra bloqueada, calcula
// Classificação, persiste Offers e Histórico de Preço. Cada marketplace de
// um Watch roda e é reagendado independentemente (ver
// watch_marketplaces.next_scan_at) — não mais todos juntos num único Scan
// por Watch.
type Runner struct {
	pool     *pgxpool.Pool
	fetchers map[string]marketplace.Fetcher
}

func NewRunner(pool *pgxpool.Pool, fetchers []marketplace.Fetcher) *Runner {
	byslug := make(map[string]marketplace.Fetcher, len(fetchers))
	for _, f := range fetchers {
		byslug[f.Slug()] = f
	}
	return &Runner{pool: pool, fetchers: byslug}
}

// RunWatchMarketplace executa um único Scan de um marketplace específico do
// Watch informado.
func (r *Runner) RunWatchMarketplace(ctx context.Context, watch sqlcgen.Watch, marketplaceSlug string) error {
	q := sqlcgen.New(r.pool)

	scan, err := q.CreateScan(ctx, sqlcgen.CreateScanParams{WatchID: watch.ID, MarketplaceSlug: &marketplaceSlug})
	if err != nil {
		return err
	}

	keywordRows, err := q.ListWatchKeywords(ctx, watch.ID)
	if err != nil {
		return err
	}
	blockedRows, err := q.ListWatchBlockedWords(ctx, watch.ID)
	if err != nil {
		return err
	}

	city, state, err := resolveRegion(ctx, q, watch)
	if err != nil {
		return err
	}

	keywords := make([]string, len(keywordRows))
	for i, k := range keywordRows {
		keywords[i] = k.Term
	}
	blockedWords := make([]string, len(blockedRows))
	for i, b := range blockedRows {
		blockedWords[i] = b.Term
	}

	targetPriceCents := watch.TargetPriceCents
	tolerancePercent := numericToFloat(watch.TolerancePercent)

	seenExternalIDs := make([]string, 0)
	totalOffersFound := 0
	newOffersCount := 0
	seenOffersCount := 0
	status := sqlcgen.ScanStatusSuccess

	fetcher, ok := r.fetchers[marketplaceSlug]
	if !ok {
		slog.Warn("no fetcher registered for marketplace", "marketplace", marketplaceSlug)
	} else {
		listings, err := fetcher.Fetch(ctx, marketplace.Query{
			Keywords:     keywords,
			BlockedWords: blockedWords,
			City:         city,
			State:        state,
		})
		if err != nil {
			status = sqlcgen.ScanStatusFailed
			errMsg := err.Error()
			if recErr := q.RecordScanMarketplaceFailure(ctx, sqlcgen.RecordScanMarketplaceFailureParams{
				ScanID:          scan.ID,
				MarketplaceSlug: marketplaceSlug,
				ErrorMessage:    &errMsg,
			}); recErr != nil {
				slog.Error("failed to record scan marketplace failure", "error", recErr)
			}
		}

		for _, listing := range listings {
			if containsBlockedWord(listing.Title, blockedWords) {
				continue
			}
			if watch.KeywordMatchMode == sqlcgen.KeywordMatchModeAll {
				if !matchesAllKeywords(listing.Title, keywords) {
					continue
				}
			} else if !matchesAnyKeyword(listing.Title, keywords) {
				continue
			}

			score := classify(listing.Title, keywords, targetPriceCents, tolerancePercent, listing.PriceCents)
			classification, err := floatToNumeric(score)
			if err != nil {
				slog.Error("failed to encode classification", "error", err)
				continue
			}

			// Preço anterior precisa ser lido antes do Upsert (que já
			// sobrescreve price_cents) — só busca quando existe uma Offer
			// prévia monitorada, para não pagar essa consulta extra no caso
			// comum (Offer nova ou não monitorada).
			var previous sqlcgen.Offer
			hasPrevious := false
			if existing, err := q.GetOfferByExternalID(ctx, sqlcgen.GetOfferByExternalIDParams{
				WatchID:         watch.ID,
				MarketplaceSlug: marketplaceSlug,
				ExternalID:      listing.ExternalID,
			}); err == nil {
				previous = existing
				hasPrevious = true
			}

			row, err := q.UpsertOffer(ctx, sqlcgen.UpsertOfferParams{
				WatchID:         watch.ID,
				MarketplaceSlug: marketplaceSlug,
				ExternalID:      listing.ExternalID,
				Url:             listing.URL,
				Title:           listing.Title,
				ImageUrl:        listing.ImageURL,
				PriceCents:      listing.PriceCents,
				Classification:  classification,
				FirstSeenScanID: scan.ID,
			})
			if err != nil {
				slog.Error("failed to upsert offer", "error", err)
				continue
			}

			if err := q.InsertOfferPricePointIfChanged(ctx, sqlcgen.InsertOfferPricePointIfChangedParams{
				OfferID:    row.ID,
				PriceCents: listing.PriceCents,
				ScanID:     scan.ID,
			}); err != nil {
				slog.Error("failed to insert price point", "error", err)
			}

			if row.IsNew {
				newOffersCount++
			} else {
				seenOffersCount++
			}

			// Dispara notificação de queda de preço só quando a Offer é
			// monitorada, já existia antes (queda pressupõe um preço
			// anterior pra comparar) e cruzou de acima para dentro/abaixo
			// do preço-alvo do Watch — evita repetir a cada Scan reverificado
			// sem mudança real de faixa.
			if hasPrevious && row.Monitored &&
				previous.PriceCents > targetPriceCents &&
				listing.PriceCents <= targetPriceCents {
				if _, err := q.CreatePriceDropNotification(ctx, sqlcgen.CreatePriceDropNotificationParams{
					UserID:  watch.UserID,
					OfferID: row.ID,
				}); err != nil {
					slog.Error("failed to create price drop notification", "error", err)
				}
			}

			seenExternalIDs = append(seenExternalIDs, listing.ExternalID)
			totalOffersFound++
		}
	}

	if err := q.MarkOffersUnavailableNotInForMarketplace(ctx, sqlcgen.MarkOffersUnavailableNotInForMarketplaceParams{
		WatchID:         watch.ID,
		MarketplaceSlug: marketplaceSlug,
		SeenExternalIds: seenExternalIDs,
	}); err != nil {
		slog.Error("failed to mark offers unavailable", "error", err)
	}

	if _, err := q.FinishScan(ctx, sqlcgen.FinishScanParams{
		ID:              scan.ID,
		Status:          status,
		OffersFound:     int32(totalOffersFound),
		NewOffersCount:  int32(newOffersCount),
		SeenOffersCount: int32(seenOffersCount),
	}); err != nil {
		return err
	}

	return nil
}

// resolveRegion retorna a região de busca do Watch (city/state), caindo
// para o padrão global (scan_settings.default_city/default_state) quando o
// Watch não define os seus — ver CreateWatch, onde city/state ficam NULL a
// menos que o usuário informe explicitamente.
func resolveRegion(ctx context.Context, q *sqlcgen.Queries, watch sqlcgen.Watch) (city, state string, err error) {
	if watch.City != nil && watch.State != nil {
		return *watch.City, *watch.State, nil
	}
	settings, err := q.GetScanSettings(ctx)
	if err != nil {
		return "", "", err
	}
	return settings.DefaultCity, settings.DefaultState, nil
}

func numericToFloat(n pgtype.Numeric) float64 {
	f, err := n.Float64Value()
	if err != nil || !f.Valid {
		return 0
	}
	return f.Float64
}

func floatToNumeric(f float64) (pgtype.Numeric, error) {
	var n pgtype.Numeric
	err := n.Scan(strconv.FormatFloat(f, 'f', 4, 64))
	return n, err
}

// RunWatchMarketplaceAndReschedule executa um Scan de um marketplace do
// Watch e agenda o próximo para um instante aleatório dentro do intervalo
// mín/máx configurado para aquele marketplace (ver
// resolveMarketplaceInterval) — mesma lógica usada pelo Scheduler a cada
// tick, reaproveitada aqui para a primeira execução de cada marketplace
// (disparada direto na criação do Watch, ver WatchHandler.Create, em vez
// de esperar o próximo tick do Scheduler).
func (r *Runner) RunWatchMarketplaceAndReschedule(ctx context.Context, watch sqlcgen.Watch, marketplaceSlug string) {
	if err := r.RunWatchMarketplace(ctx, watch, marketplaceSlug); err != nil {
		slog.Error("scan run failed", "watch_id", watch.ID, "marketplace", marketplaceSlug, "error", err)
	}

	q := sqlcgen.New(r.pool)
	minMinutes, maxMinutes, err := resolveMarketplaceInterval(ctx, q, marketplaceSlug)
	if err != nil {
		slog.Error("failed to resolve scan interval for reschedule", "watch_id", watch.ID, "marketplace", marketplaceSlug, "error", err)
		return
	}

	next := nextScanTime(minMinutes, maxMinutes)
	if err := q.RescheduleWatchMarketplace(ctx, sqlcgen.RescheduleWatchMarketplaceParams{
		WatchID:         watch.ID,
		MarketplaceSlug: marketplaceSlug,
		NextScanAt:      pgtype.Timestamptz{Time: next, Valid: true},
	}); err != nil {
		slog.Error("failed to reschedule watch marketplace", "watch_id", watch.ID, "marketplace", marketplaceSlug, "error", err)
	}
}

// resolveMarketplaceInterval retorna o intervalo mín/máx configurado para
// um marketplace específico (marketplace_scan_settings) — todo marketplace
// em availableMarketplaces (frontend) sempre tem uma linha própria aqui,
// gravada pelo admin em Configurações; não há mais fallback para um
// intervalo global (ver migration 000011).
func resolveMarketplaceInterval(ctx context.Context, q *sqlcgen.Queries, marketplaceSlug string) (min, max int32, err error) {
	settings, err := q.ListMarketplaceScanSettings(ctx)
	if err != nil {
		return 0, 0, err
	}
	for _, s := range settings {
		if s.MarketplaceSlug == marketplaceSlug {
			return s.MinIntervalMinutes, s.MaxIntervalMinutes, nil
		}
	}
	return 0, 0, fmt.Errorf("no scan interval configured for marketplace %q", marketplaceSlug)
}

func nextScanTime(minMinutes, maxMinutes int32) time.Time {
	span := maxMinutes - minMinutes
	offset := minMinutes
	if span > 0 {
		offset += rand.Int32N(span + 1)
	}
	return time.Now().Add(time.Duration(offset) * time.Minute)
}
