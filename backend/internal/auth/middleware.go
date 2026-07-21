package auth

import (
	"context"
	"net/http"
	"strings"
)

type contextKey string

const claimsContextKey contextKey = "claims"

// Middleware valida o JWT do header Authorization e injeta as Claims no
// contexto da requisição. Toda rota autenticada deve passar por aqui —
// handlers nunca decodificam o token por conta própria.
func Middleware(issuer *TokenIssuer) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			token, ok := strings.CutPrefix(header, "Bearer ")
			if !ok || token == "" {
				http.Error(w, "missing bearer token", http.StatusUnauthorized)
				return
			}

			claims, err := issuer.ParseAccessToken(token)
			if err != nil {
				http.Error(w, "invalid or expired token", http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), claimsContextKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func FromContext(ctx context.Context) (*Claims, bool) {
	claims, ok := ctx.Value(claimsContextKey).(*Claims)
	return claims, ok
}

// WithClaims injeta Claims diretamente no contexto, pulando a validação de
// JWT. Uso em testes de handlers autenticados, que não precisam emitir um
// token real para exercitar a lógica de autorização.
func WithClaims(ctx context.Context, claims *Claims) context.Context {
	return context.WithValue(ctx, claimsContextKey, claims)
}

const RoleAdmin = "admin"

// IsAdmin verifica o Role vindo do JWT. Suficiente para gate de UI/leitura,
// mas rotas que modificam Watch de outro User devem sempre confirmar
// ownership contra o banco (o Role no token pode estar desatualizado se
// mudou entre a emissão do token e agora).
func IsAdmin(claims *Claims) bool {
	return claims.Role == RoleAdmin
}

// RequireAdmin bloqueia toda a rota para quem não for admin no JWT. Uso
// aceitável aqui porque nenhuma rota administrativa (gestão de Users) muda
// de comportamento por ownership — é admin ou não é, sem meio-termo — ao
// contrário de Watch, onde o Role do token não basta.
func RequireAdmin(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := FromContext(r.Context())
		if !ok || !IsAdmin(claims) {
			http.Error(w, "admin role required", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}
