package observability

import (
	"bytes"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

// skipRoutes não geram log de acesso. O healthcheck do Docker bate a cada 10s
// (~8.6k linhas/dia) e não diz nada que o próprio healthcheck já não diga —
// era ele que enterrava os logs reais em `docker logs`/Loki.
var skipRoutes = map[string]bool{
	"/api/health": true,
	"/health":     true,
	"/metrics":    true,
}

// bodyCapture guarda o que foi escrito na resposta para poder logar o body de
// saída. Envolve o WrapResponseWriter do chi (que já rastreia status e bytes),
// então status/tamanho continuam corretos.
type bodyCapture struct {
	middleware.WrapResponseWriter
	buf bytes.Buffer
}

func (c *bodyCapture) Write(b []byte) (int, error) {
	// Só guardamos até o limite: a resposta segue inteira para o cliente,
	// mas o log nunca cresce além de MaxBodyBytes.
	if remaining := MaxBodyBytes - c.buf.Len(); remaining > 0 {
		if len(b) <= remaining {
			c.buf.Write(b)
		} else {
			c.buf.Write(b[:remaining])
		}
	}
	return c.WrapResponseWriter.Write(b)
}

// HTTPLogger substitui o middleware.Logger do chi. Aquele escreve uma linha de
// texto ("GET http://localhost:8080/api/health ... 200 16B in 27µs") que no
// Loki é só uma string — não dá para filtrar por status, rota ou usuário.
//
// Aqui cada requisição vira UM objeto JSON com: trace id, quem chamou, rota,
// status, duração e os bodies de entrada e saída (com campos sensíveis
// redigidos e truncados em 4KB).
//
// A rota é registrada como PADRÃO do chi (/api/alerts/{id}), não como URL
// crua: o path real carrega ids que explodiriam a cardinalidade do Loki e
// tornariam impossível agregar "quanto custa esse endpoint".
func HTTPLogger(base *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if skipRoutes[r.URL.Path] {
				next.ServeHTTP(w, r)
				return
			}

			// O trace vem do chamador quando existe (mantendo a correlação
			// entre serviços) e é criado aqui quando a requisição nasce nesta
			// borda.
			traceID := traceIDFromHeader(r.Header.Get(TraceparentHeader))
			if traceID == "" {
				traceID = newTraceID()
			}
			ctx := WithTrace(r.Context(), traceID)
			r = r.WithContext(ctx)

			// Devolver o trace id ao cliente permite que um usuário relate um
			// erro citando o id, e a busca no Grafana cair direto na requisição.
			w.Header().Set("X-Trace-Id", traceID)

			// O body é consumível uma única vez; lemos, guardamos e repomos
			// para o handler receber tudo normalmente.
			var reqBody []byte
			if r.Body != nil {
				limited := io.LimitReader(r.Body, MaxBodyBytes+1)
				reqBody, _ = io.ReadAll(limited)
				rest, _ := io.ReadAll(r.Body)
				r.Body.Close()
				r.Body = io.NopCloser(bytes.NewReader(append(reqBody, rest...)))
			}

			capture := &bodyCapture{WrapResponseWriter: middleware.NewWrapResponseWriter(w, r.ProtoMajor)}
			start := time.Now()

			defer func() {
				route := chi.RouteContext(r.Context()).RoutePattern()
				if route == "" {
					// Sem padrão casado (404): o path cru é controlado por
					// quem chama e teria cardinalidade ilimitada.
					route = "unmatched"
				}

				status := capture.Status()

				attrs := []any{
					LogTraceKey, traceID,
					"method", r.Method,
					"route", route,
					"path", r.URL.Path,
					"status", status,
					"duration_ms", time.Since(start).Milliseconds(),
					"bytes_out", capture.BytesWritten(),
					"request_id", middleware.GetReqID(r.Context()),
					"remote_ip", r.RemoteAddr,
					"user_agent", r.UserAgent(),
					"request_body", RedactJSON(reqBody),
					"response_body", RedactJSON(capture.buf.Bytes()),
				}

				// O ator é resolvido pelo middleware de auth, que roda DEPOIS
				// deste; por isso lemos do contexto só agora, no defer.
				if actor, ok := ActorFromContext(r.Context()); ok {
					attrs = append(attrs, "user_id", actor.UserID, "user_role", actor.Role)
				} else {
					attrs = append(attrs, "user_id", "anonymous")
				}

				// A severidade espelha a triagem de quem opera: 5xx é problema
				// nosso, 4xx é do chamador. É o que faz um alerta por
				// `level="ERROR"` significar a mesma coisa em todos os apps.
				switch {
				case status >= 500:
					base.Error("http request failed", attrs...)
				case status >= 400:
					base.Warn("http request rejected", attrs...)
				default:
					base.Info("http request", attrs...)
				}
			}()

			next.ServeHTTP(capture, r)
		})
	}
}
