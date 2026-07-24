package apify

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

const runsFixtureResponse = `{
	"data": {
		"total": 2,
		"items": [
			{"id": "run2", "actId": "abc", "status": "SUCCEEDED", "startedAt": "2026-07-24T15:00:00.000Z", "finishedAt": "2026-07-24T15:00:05.000Z", "usageTotalUsd": 0.02},
			{"id": "run1", "actId": "abc", "status": "SUCCEEDED", "startedAt": "2026-07-24T10:00:00.000Z", "finishedAt": "2026-07-24T10:00:05.000Z", "usageTotalUsd": 0.01}
		]
	}
}`

func TestUsageClient_RecentRuns_ParsesResponse(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "test-token", r.URL.Query().Get("token"))
		require.Equal(t, "10", r.URL.Query().Get("limit"))
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(runsFixtureResponse))
	}))
	defer server.Close()

	c := NewUsageClient("test-token")
	c.baseURL = server.URL

	runs, err := c.RecentRuns(context.Background(), 10)
	require.NoError(t, err)
	require.Len(t, runs, 2)
	require.Equal(t, "run2", runs[0].ID)
	require.Equal(t, 0.02, runs[0].UsageUSD)
}

func TestUsageClient_RecentRuns_ReturnsErrorOnApifyFailure(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte("internal error"))
	}))
	defer server.Close()

	c := NewUsageClient("test-token")
	c.baseURL = server.URL

	_, err := c.RecentRuns(context.Background(), 10)
	require.Error(t, err)
	require.Contains(t, err.Error(), "status 500")
}

func TestUsageClient_RecentRuns_ReturnsErrorWhenTokenMissing(t *testing.T) {
	c := NewUsageClient("")
	_, err := c.RecentRuns(context.Background(), 10)
	require.Error(t, err)
	require.Contains(t, err.Error(), "APIFY_API_TOKEN not configured")
}
