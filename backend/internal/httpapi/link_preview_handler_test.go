package httpapi

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/linkpreview"
)

func TestLinkPreviewHandler_InvalidURLReturnsPartialFailure(t *testing.T) {
	h := NewLinkPreviewHandler(linkpreview.NewProposer("test-key"))

	body, err := json.Marshal(linkPreviewRequest{URL: "not-a-real-url-xyz://nope"})
	require.NoError(t, err)

	req := httptest.NewRequest(http.MethodPost, "/api/watches/link-preview", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	h.Preview(rec, req)

	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var resp linkPreviewResponse
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.True(t, resp.PartialFailure)
}

func TestLinkPreviewHandler_MissingURL(t *testing.T) {
	h := NewLinkPreviewHandler(linkpreview.NewProposer("test-key"))

	req := httptest.NewRequest(http.MethodPost, "/api/watches/link-preview", bytes.NewReader([]byte(`{}`)))
	rec := httptest.NewRecorder()
	h.Preview(rec, req)

	require.Equal(t, http.StatusBadRequest, rec.Code)
}
