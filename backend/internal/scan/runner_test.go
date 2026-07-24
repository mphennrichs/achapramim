package scan

import (
	"context"
	"errors"
	"testing"

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

	require.NoError(t, runner.RunWatch(context.Background(), watch))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, offers, 1, "blocked word listing should be excluded")
	require.Equal(t, "PlayStation 5 novo lacrado", offers[0].Title)
	require.True(t, offers[0].Available)
}

func TestRunner_RunWatch_PartialSuccessOnFetcherError(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx", "mercado_livre"}, []string{"playstation"}, nil)

	workingFetcher := &fakeFetcher{
		slug: "olx",
		listings: []marketplace.Listing{
			{ExternalID: "123", URL: "https://olx.com.br/123", Title: "PlayStation 5", ImageURL: "https://img/1.jpg", PriceCents: 250000},
		},
	}
	failingFetcher := &fakeFetcher{slug: "mercado_livre", err: errors.New("blocked by anti-bot")}

	runner := NewRunner(pool, []marketplace.Fetcher{workingFetcher, failingFetcher})
	require.NoError(t, runner.RunWatch(context.Background(), watch))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Len(t, offers, 1)
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
	require.NoError(t, runner.RunWatch(context.Background(), watch))

	secondRunFetcher := &fakeFetcher{slug: "olx", listings: nil}
	runner2 := NewRunner(pool, []marketplace.Fetcher{secondRunFetcher})
	require.NoError(t, runner2.RunWatch(context.Background(), watch))

	q := sqlcgen.New(pool)
	offers, err := q.TopOffersByWatch(context.Background(), sqlcgen.TopOffersByWatchParams{WatchID: watch.ID, Limit: 20})
	require.NoError(t, err)
	require.Empty(t, offers, "offer no longer returned by fetcher should become unavailable")
}

func TestRunner_RunWatch_UsesGlobalDefaultRegionWhenWatchHasNone(t *testing.T) {
	pool := newTestPool(t)
	watch := createTestUserAndWatch(t, pool, []string{"olx"}, nil, nil)

	fetcher := &fakeFetcher{slug: "olx"}
	runner := NewRunner(pool, []marketplace.Fetcher{fetcher})
	require.NoError(t, runner.RunWatch(context.Background(), watch))

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
	require.NoError(t, runner.RunWatch(context.Background(), watch))

	require.Equal(t, "Curitiba", fetcher.lastQuery.City)
	require.Equal(t, "PR", fetcher.lastQuery.State)
}
