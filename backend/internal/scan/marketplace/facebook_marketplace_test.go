package marketplace

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

const facebookFixtureResponse = `[
	{
		"id": "111",
		"listingUrl": "https://www.facebook.com/marketplace/item/111",
		"marketplace_listing_title": "Frigobar novo",
		"listing_price": {"amount": "600.00"},
		"primary_listing_photo": {"photo_image_url": "https://example.com/111.jpg"}
	},
	{
		"id": "222",
		"listingUrl": "https://www.facebook.com/marketplace/item/222",
		"marketplace_listing_title": "Preço a combinar",
		"listing_price": {"amount": ""},
		"primary_listing_photo": {"photo_image_url": "https://example.com/222.jpg"}
	}
]`

func TestFacebookMarketplaceFetcher_Fetch_ParsesAndFiltersListings(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "test-token", r.URL.Query().Get("token"))
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(facebookFixtureResponse))
	}))
	defer server.Close()

	f := NewFacebookMarketplaceFetcher("test-token")
	f.runSyncURL = server.URL

	listings, err := f.Fetch(context.Background(), Query{Keywords: []string{"frigobar"}})
	require.NoError(t, err)

	// A segunda listing tem amount vazio ("Preço a combinar") — deve ser
	// filtrada, sobrando só a primeira.
	require.Len(t, listings, 1)
	require.Equal(t, "111", listings[0].ExternalID)
	require.Equal(t, "Frigobar novo", listings[0].Title)
	require.Equal(t, int64(60000), listings[0].PriceCents)
	require.Equal(t, "https://www.facebook.com/marketplace/item/111", listings[0].URL)
	require.Equal(t, "https://example.com/111.jpg", listings[0].ImageURL)
}

func TestFacebookMarketplaceFetcher_Fetch_ReturnsErrorOnApifyFailure(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte("internal error"))
	}))
	defer server.Close()

	f := NewFacebookMarketplaceFetcher("test-token")
	f.runSyncURL = server.URL

	_, err := f.Fetch(context.Background(), Query{Keywords: []string{"frigobar"}})
	require.Error(t, err)
	require.Contains(t, err.Error(), "status 500")
}

func TestFacebookMarketplaceFetcher_Fetch_ReturnsErrorWhenTokenMissing(t *testing.T) {
	f := NewFacebookMarketplaceFetcher("")
	_, err := f.Fetch(context.Background(), Query{Keywords: []string{"frigobar"}})
	require.Error(t, err)
	require.Contains(t, err.Error(), "APIFY_API_TOKEN not configured")
}

func TestBuildFacebookSearchURL(t *testing.T) {
	require.Equal(t,
		"https://www.facebook.com/marketplace/belohorizonte/search/?query=frigobar",
		buildFacebookSearchURL(Query{Keywords: []string{"frigobar"}, State: "MG"}),
	)
	require.Equal(t,
		"https://www.facebook.com/marketplace/belohorizonte/search/?query=frigobar",
		buildFacebookSearchURL(Query{Keywords: []string{"frigobar"}}),
	)
}
