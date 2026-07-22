package httpapi

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
)

// TestRouter_RequireAdminBlocksRegularUser confirma, no nível de
// integração real (JWT emitido de verdade, roteamento real do chi), que
// RequireAdmin bloqueia um User comum em uma rota admin-only — o handler
// isolado não checa Role sozinho, então isso só é observável passando
// pelo router completo.
func TestRouter_RequireAdminBlocksRegularUser(t *testing.T) {
	pool := newTestPool(t)
	user := createTestUser(t, pool, "user")
	admin := createTestUser(t, pool, "admin")

	issuer := auth.NewTokenIssuer("test-secret", time.Hour)
	router := NewRouter(Deps{
		Pool:            pool,
		Issuer:          issuer,
		RefreshTokenTTL: time.Hour,
	})

	userToken, err := issuer.IssueAccessToken(uuidString(user.ID), user.Role)
	require.NoError(t, err)
	adminToken, err := issuer.IssueAccessToken(uuidString(admin.ID), admin.Role)
	require.NoError(t, err)

	body := `{"min_interval_minutes": 15, "max_interval_minutes": 60}`

	userReq := httptest.NewRequest(http.MethodPut, "/api/scan-settings", strings.NewReader(body))
	userReq.Header.Set("Authorization", "Bearer "+userToken)
	userRec := httptest.NewRecorder()
	router.ServeHTTP(userRec, userReq)
	require.Equal(t, http.StatusForbidden, userRec.Code, userRec.Body.String())

	adminReq := httptest.NewRequest(http.MethodPut, "/api/scan-settings", strings.NewReader(body))
	adminReq.Header.Set("Authorization", "Bearer "+adminToken)
	adminRec := httptest.NewRecorder()
	router.ServeHTTP(adminRec, adminReq)
	require.Equal(t, http.StatusOK, adminRec.Code, adminRec.Body.String())
}
