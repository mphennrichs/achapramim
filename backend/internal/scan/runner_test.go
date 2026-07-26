package scan

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
	"github.com/mphennrichs/achapramim/backend/internal/scan/marketplace"
)

type fakeFetcher struct {
	slug      string
	listings  []marketplace.Listing
	err       error
	lastQuery marketplace.Query
}

func (f *fakeFetcher) Slug() string { return f.slug }

func (f *fakeFetcher) Fetch(ctx context.Context, query marketplace.Query) ([]marketplace.Listing, error) {
	f.lastQuery = query
	if f.err != nil {
		return nil, f.err
	}
	return f.listings, nil
}

func createTestUserAndWatch(t *testing.T, pool *pgxpool.Pool, marketplaceSlugs []string, keywords, blockedWords []string) sqlcgen.Watch {
	return createTestUserAndWatchWithRegion(t, pool, marketplaceSlugs, keywords, blockedWords, nil, nil)
}

func createTestUserAndWatchWithRegion(t *testing.T, pool *pgxpool.Pool, marketplaceSlugs []string, keywords, blockedWords []string, city, state *string) sqlcgen.Watch {
	return createTestUserAndWatchWithMode(t, pool, marketplaceSlugs, keywords, blockedWords, city, state, sqlcgen.KeywordMatchModeAny)
}

func createTestUserAndWatchWithMode(t *testing.T, pool *pgxpool.Pool, marketplaceSlugs []string, keywords, blockedWords []string, city, state *string, keywordMatchMode sqlcgen.KeywordMatchMode) sqlcgen.Watch {
	t.Helper()
	ctx := context.Background()
	q := sqlcgen.New(pool)

	user, err := q.CreateUser(ctx, sqlcgen.CreateUserParams{
		Name:         "Test User",
		Email:        "user-" + uuid.NewString() + "@example.com",
		PasswordHash: "hash",
		Role:         "user",
	})
	require.NoError(t, err)

	tolerance, err := pgNumericHelper("10.00")
	require.NoError(t, err)
	threshold, err := pgNumericHelper("5.00")
	require.NoError(t, err)

	watch, err := q.CreateWatch(ctx, sqlcgen.CreateWatchParams{
		UserID:                    user.ID,
		Name:                      "Test Watch",
		TargetPriceCents:          250000,
		TolerancePercent:          tolerance,
		MaxOffers:                 20,
		PriceDropThresholdPercent: threshold,
		City:                      city,
		State:                     state,
		KeywordMatchMode:          keywordMatchMode,
	})
	require.NoError(t, err)

	for _, slug := range marketplaceSlugs {
		require.NoError(t, q.AddWatchMarketplace(ctx, sqlcgen.AddWatchMarketplaceParams{
			WatchID:         watch.ID,
			MarketplaceSlug: slug,
		}))
	}
	for _, kw := range keywords {
		_, err := q.AddWatchKeyword(ctx, sqlcgen.AddWatchKeywordParams{WatchID: watch.ID, Term: kw})
		require.NoError(t, err)
	}
	for _, bw := range blockedWords {
		_, err := q.AddWatchBlockedWord(ctx, sqlcgen.AddWatchBlockedWordParams{WatchID: watch.ID, Term: bw})
		require.NoError(t, err)
	}

	return watch
}

func pgNumericHelper(s string) (pgtype.Numeric, error) {
	var n pgtype.Numeric
	err := n.Scan(s)
	return n, err
}

func TestRunner_RunWatch_PersistsOffersAndPricePoint(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, []string{"playstation"}, []string{"quebrado"})

	fetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "PlayStation 5 novo lacrado", ImageURL: "https://img/1.jpg", PriceCents: 250000},
			{ExternalID: "456", URL: "https://olx.com.br/456", Title: "PlayStation 5 quebrado para peças", ImageURL: "https://img/2.jpg", PriceCents: 100000},
		},
	}
	runner := NewRunner(pool, []marketplace.Fetcher{fetcher})

	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, offers, 1, "blocked word listing should be excluded")
	require.Equal(t, "PlayStation 5 novo lacrado", offers[0].Title)
	require.True(t, offers[0].Available)
}

// TestRunner_RunWatch_FailsScanWhenOnlyFetcherErrors cobre o caso de falha
// total: hoje só existe um marketplace (OLX) disponível, então um Watch tem
// no máximo um slug configurado — "sucesso parcial" (um marketplace falha,
// outro funciona) fica inatingível na prática enquanto isso for verdade; o
// enum ScanStatusPartial permanece no código para quando um segundo
// marketplace real existir, mas sem cobertura de teste ativa por ora.
func TestRunner_RunWatch_FailsScanWhenOnlyFetcherErrors(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, []string{"playstation"}, nil)

	failingFetcher := &fakeFetcher{slug: "olx", err: errors.New("blocked by anti-bot")}

	runner := NewRunner(pool, []marketplace.Fetcher{failingFetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Empty(t, offers)

	scans, err := q.ListScansByWatch(context.Background(), sqlcgen.ListScansByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, scans, 1)
	require.Equal(t, sqlcgen.ScanStatusFailed, scans[0].Status)
}

func TestRunner_RunWatch_MarksMissingOfferUnavailable(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, nil, nil)

	firstRunFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "Item A", ImageURL: "https://img/a.jpg", PriceCents: 250000},
		},
	}
	runner := NewRunner(pool, []marketplace.Fetcher{firstRunFetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	secondRunFetcher := &fakeFetcher{slug: "olx", listings: nil}
	runner2 := NewRunner(pool, []marketplace.Fetcher{secondRunFetcher})
	require.NoError(t, runner2.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Empty(t, offers, "offer no longer returned by fetcher should become unavailable")
}

func TestRunner_RunWatch_TracksNewAndSeenOfferCounts(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, nil, nil)

	firstRunFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "Item A", ImageURL: "https://img/a.jpg", PriceCents: 250000},
		},
	}
	runner := NewRunner(pool, []marketplace.Fetcher{firstRunFetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	scans, err := q.ListScansByWatch(context.Background(), sqlcgen.ListScansByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, scans, 1)
	require.Equal(t, int32(1), scans[0].NewOffersCount)
	require.Equal(t, int32(0), scans[0].SeenOffersCount)

	secondRunFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "Item A", ImageURL: "https://img/a.jpg", PriceCents: 250000},
			{ExternalID: "456", URL: "https://olx.com.br/456", Title: "Item B", ImageURL: "https://img/b.jpg", PriceCents: 300000},
		},
	}
	runner2 := NewRunner(pool, []marketplace.Fetcher{secondRunFetcher})
	require.NoError(t, runner2.RunWatchMarketplace(context.Background(), watch, "olx"))

	scans, err = q.ListScansByWatch(context.Background(), sqlcgen.ListScansByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, scans, 2)
	require.Equal(t, int32(1), scans[0].NewOffersCount, "item B is new in the second scan")
	require.Equal(t, int32(1), scans[0].SeenOffersCount, "item A was already known")
}

func TestRunner_RunWatch_NotifiesPriceDropForMonitoredOfferBelowTarget(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, nil, nil) // target_price_cents = 250000

	firstRunFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "Item A", ImageURL: "https://img/a.jpg", PriceCents: 300000},
		},
	}
	runner := NewRunner(pool, []marketplace.Fetcher{firstRunFetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, offers, 1)

	_, err = q.SetOfferMonitored(context.Background(), sqlcgen.SetOfferMonitoredParams{ID: offers[0].ID, Monitored: true})
	require.NoError(t, err)

	secondRunFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "Item A", ImageURL: "https://img/a.jpg", PriceCents: 200000},
		},
	}
	runner2 := NewRunner(pool, []marketplace.Fetcher{secondRunFetcher})
	require.NoError(t, runner2.RunWatchMarketplace(context.Background(), watch, "olx"))

	notifications, err := q.ListNotificationsByUser(context.Background(), sqlcgen.ListNotificationsByUserParams{UserID: watch.UserID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, notifications, 1)
	require.Equal(t, sqlcgen.NotificationTriggerPriceDrop, notifications[0].Trigger)
	require.Equal(t, "Item A", notifications[0].OfferTitle)
}

func TestRunner_RunWatch_DoesNotNotifyWhenOfferNotMonitored(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, nil, nil)

	firstRunFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "Item A", ImageURL: "https://img/a.jpg", PriceCents: 300000},
		},
	}
	runner := NewRunner(pool, []marketplace.Fetcher{firstRunFetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	secondRunFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "Item A", ImageURL: "https://img/a.jpg", PriceCents: 200000},
		},
	}
	runner2 := NewRunner(pool, []marketplace.Fetcher{secondRunFetcher})
	require.NoError(t, runner2.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	notifications, err := q.ListNotificationsByUser(context.Background(), sqlcgen.ListNotificationsByUserParams{UserID: watch.UserID, Limit: 20})
	require.NoError(t, err)
	require.Empty(t, notifications)
}

func TestRunner_RunWatch_AllModeFiltersOutOffersMissingAnyKeyword(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatchWithMode(t, pool, []string{"olx"}, []string{"playstation", "5"}, nil, nil, nil, sqlcgen.KeywordMatchModeAll)

	fetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "PlayStation 5 novo lacrado", ImageURL: "https://img/1.jpg", PriceCents: 250000},
			{ExternalID: "456", URL: "https://olx.com.br/456", Title: "PlayStation 4 usado", ImageURL: "https://img/2.jpg", PriceCents: 250000},
		},
	}
	runner := NewRunner(pool, []marketplace.Fetcher{fetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, offers, 1, "only the listing matching all keywords should be kept")
	require.Equal(t, "PlayStation 5 novo lacrado", offers[0].Title)
}

func TestRunner_RunWatch_AnyModeKeepsOffersMatchingAtLeastOneKeyword(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatchWithMode(t, pool, []string{"olx"}, []string{"playstation", "5"}, nil, nil, nil, sqlcgen.KeywordMatchModeAny)

	fetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "PlayStation 5 novo lacrado", ImageURL: "https://img/1.jpg", PriceCents: 250000},
			{ExternalID: "456", URL: "https://olx.com.br/456", Title: "PlayStation 4 usado", ImageURL: "https://img/2.jpg", PriceCents: 250000},
			{ExternalID: "789", URL: "https://olx.com.br/789", Title: "Xbox Series X novo", ImageURL: "https://img/3.jpg", PriceCents: 250000},
		},
	}
	runner := NewRunner(pool, []marketplace.Fetcher{fetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, offers, 2, "'any' mode should keep offers matching at least one keyword, and drop offers matching none")
}

func TestRunner_RunWatch_UsesGlobalDefaultRegionWhenWatchHasNone(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, nil, nil)

	fetcher := &fakeFetcher{slug: "olx"}
	runner := NewRunner(pool, []marketplace.Fetcher{fetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	// scan_settings.default_city/default_state (seed da migration) — ver
	// resolveRegion.
	require.Equal(t, "Belo Horizonte", fetcher.lastQuery.City)
	require.Equal(t, "MG", fetcher.lastQuery.State)
}

func TestRunner_RunWatch_UsesWatchOwnRegionOverGlobalDefault(t *testing.T) {
	pool := newTestPool(t)
	city := "Curitiba"
	state := "PR"
	watch := createTestUserAndWatchWithRegion(t, pool, []string{"olx"}, nil, nil, &city, &state)

	fetcher := &fakeFetcher{slug: "olx"}
	runner := NewRunner(pool, []marketplace.Fetcher{fetcher})
	require.NoError(t, runner.RunWatchMarketplace(context.Background(), watch, "olx"))

	require.Equal(t, "Curitiba", fetcher.lastQuery.City)
	require.Equal(t, "PR", fetcher.lastQuery.State)
}

func TestRunner_RunWatchMarketplaceAndReschedule_UsesPerMarketplaceInterval(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx", "facebook_marketplace"}, nil, nil)

	q := sqlcgen.New(pool)
	_, err := q.UpsertMarketplaceScanSetting(context.Background(), sqlcgen.UpsertMarketplaceScanSettingParams{
		MarketplaceSlug:    "facebook_marketplace",
		MinIntervalMinutes: 1440,
		MaxIntervalMinutes: 1440,
	})
	require.NoError(t, err)

	runner := NewRunner(pool, []marketplace.Fetcher{
		&fakeFetcher{slug: "olx"},
		&fakeFetcher{slug: "facebook_marketplace"},
	})

	before := time.Now()
	runner.RunWatchMarketplaceAndReschedule(context.Background(), watch, "olx")
	runner.RunWatchMarketplaceAndReschedule(context.Background(), watch, "facebook_marketplace")

	rows, err := q.DueWatchMarketplaces(context.Background())
	require.NoError(t, err)
	require.Empty(t, rows, "both marketplaces should be rescheduled into the future, not due immediately")

	olxNext := watchMarketplaceNextScanAt(t, pool, watch.ID, "olx")
	fbNext := watchMarketplaceNextScanAt(t, pool, watch.ID, "facebook_marketplace")

	// OLX cai no fallback global (scan_settings: 30-120min); Facebook tem
	// override próprio de 1440min — a diferença precisa refletir isso,
	// não apenas "ambos no futuro".
	require.True(t, fbNext.Sub(before) > olxNext.Sub(before),
		"facebook_marketplace (1440min override) should be scheduled much further out than olx (global default)")
}

func watchMarketplaceNextScanAt(t *testing.T, pool *pgxpool.Pool, watchID pgtype.UUID, marketplaceSlug string) time.Time {
	t.Helper()
	var nextScanAt time.Time
	err := pool.QueryRow(context.Background(),
		"SELECT next_scan_at FROM watch_marketplaces WHERE watch_id = $1 AND marketplace_slug = $2",
		watchID, marketplaceSlug,
	).Scan(&nextScanAt)
	require.NoError(t, err)
	return nextScanAt
}
