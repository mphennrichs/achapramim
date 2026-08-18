package observability

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"log/slog"
	"net/http"
	"strings"
)

// Header W3C Trace Context. Usamos o padrão (em vez de um X-Trace-Id próprio)
// porque é o que qualquer proxy/serviço externo já entende e propaga — se um
// dia entrar Tempo/OTel na stack, o mesmo id continua valendo sem migração.
const TraceparentHeader = "traceparent"

// LogTraceKey é o nome do campo no log. Fixo e igual em todos os serviços:
// é o que permite `{app="achapramim"} | json | trace_id="abc..."` no Grafana
// e, principalmente, seguir a MESMA requisição de um serviço para outro.
const LogTraceKey = "trace_id"

type contextKey string

const (
	traceContextKey contextKey = "trace_id"
	actorContextKey contextKey = "actor"
)

// Actor é quem originou a requisição — a resposta para "quem disparou isso?"
// quando um erro aparece no Grafana. Anônimo até o middleware de auth resolver
// as claims do JWT.
type Actor struct {
	UserID string
	Role   string
}

// newTraceID gera um id de 16 bytes no formato do trace-id do W3C.
func newTraceID() string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		// rand.Read só falha em situação catastrófica; um id vazio quebraria
		// a correlação, então é melhor um marcador explícito que um pânico.
		return "0000000000000000"
	}
	return hex.EncodeToString(b[:])
}

// traceIDFromHeader extrai o trace-id de um traceparent W3C
// ("00-<trace-id>-<span-id>-<flags>"). Devolve "" se o header não vier ou
// estiver malformado — nesse caso o chamador gera um id novo.
func traceIDFromHeader(h string) string {
	parts := strings.Split(h, "-")
	if len(parts) < 3 || len(parts[1]) != 32 {
		return ""
	}
	return parts[1]
}

// WithTrace guarda o trace id no contexto.
func WithTrace(ctx context.Context, traceID string) context.Context {
	return context.WithValue(ctx, traceContextKey, traceID)
}

// TraceFromContext lê o trace id corrente. Vazio se a chamada não passou pelo
// middleware (ex.: o scheduler, que roda fora de qualquer requisição HTTP).
func TraceFromContext(ctx context.Context) string {
	id, _ := ctx.Value(traceContextKey).(string)
	return id
}

// WithActor guarda quem está chamando. Usado pelo middleware de auth assim que
// o JWT é validado.
func WithActor(ctx context.Context, a Actor) context.Context {
	return context.WithValue(ctx, actorContextKey, a)
}

// ActorFromContext devolve quem chamou, e se havia alguém autenticado.
func ActorFromContext(ctx context.Context) (Actor, bool) {
	a, ok := ctx.Value(actorContextKey).(Actor)
	return a, ok
}

// InjectTraceparent carimba o trace atual numa requisição de SAÍDA. É o que
// fecha o ciclo distribuído: a chamada ao Anthropic/Apify/OLX carrega o mesmo
// trace id da requisição que a originou, então o Grafana consegue mostrar a
// cadeia inteira filtrando por um único valor.
func InjectTraceparent(ctx context.Context, req *http.Request) {
	traceID := TraceFromContext(ctx)
	if traceID == "" {
		return
	}
	// span-id é obrigatório no formato; sem tracing real ainda, geramos um
	// valor por chamada apenas para manter o header válido.
	spanID := newTraceID()[:16]
	req.Header.Set(TraceparentHeader, "00-"+traceID+"-"+spanID+"-01")
}

// Logger devolve um slog.Logger já carimbado com trace id e ator, para os
// passos intermediários logarem sem repetir esses campos em cada chamada.
// É assim que um log lá de dentro do Scan continua correlacionável.
func Logger(ctx context.Context, base *slog.Logger) *slog.Logger {
	l := base
	if traceID := TraceFromContext(ctx); traceID != "" {
		l = l.With(LogTraceKey, traceID)
	}
	if actor, ok := ActorFromContext(ctx); ok {
		l = l.With("user_id", actor.UserID, "user_role", actor.Role)
	}
	return l
}
