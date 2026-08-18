package observability

import (
	"strings"
	"testing"
)

// A garantia mais importante deste pacote: nenhuma senha pode chegar ao Loki.
// O body de /api/me/password carrega as duas em texto puro.
func TestRedactJSON_RedigeSenhas(t *testing.T) {
	body := []byte(`{"current_password":"segredo123","new_password":"outro456"}`)

	got := RedactJSON(body)

	if strings.Contains(got, "segredo123") || strings.Contains(got, "outro456") {
		t.Fatalf("senha vazou no log: %s", got)
	}
	if !strings.Contains(got, redacted) {
		t.Fatalf("esperava marcador %s, veio: %s", redacted, got)
	}
}

func TestRedactJSON_RedigeEmProfundidade(t *testing.T) {
	// Campos sensíveis aninhados (e dentro de arrays) são o caso que uma
	// verificação só no nível raiz deixaria passar.
	body := []byte(`{"user":{"name":"mario","api_key":"sk-123"},"list":[{"token":"abc"}]}`)

	got := RedactJSON(body)

	if strings.Contains(got, "sk-123") || strings.Contains(got, "abc") {
		t.Fatalf("credencial aninhada vazou: %s", got)
	}
	// O que não é sensível continua legível — senão o log perde utilidade.
	if !strings.Contains(got, "mario") {
		t.Fatalf("campo não-sensível foi perdido: %s", got)
	}
}

func TestRedactJSON_NaoVazaBodyNaoJSON(t *testing.T) {
	// Um POST de login em form-encoding não é JSON. Se o fallback fosse
	// "loga como veio", a senha apareceria inteira no Loki.
	body := []byte("username=mario&password=segredo123")

	got := RedactJSON(body)

	if strings.Contains(got, "segredo123") {
		t.Fatalf("body não-JSON vazou credencial: %s", got)
	}
}

func TestRedactJSON_Trunca(t *testing.T) {
	// Um Scan pode devolver centenas de KB de Offers; o log tem que parar
	// no limite e dizer que parou.
	large := `{"data":"` + strings.Repeat("x", MaxBodyBytes*2) + `"}`

	got := RedactJSON([]byte(large))

	if len(got) > MaxBodyBytes+len("...[truncated]") {
		t.Fatalf("body não foi truncado: %d bytes", len(got))
	}
	if !strings.HasSuffix(got, "...[truncated]") {
		t.Fatal("truncamento não foi sinalizado")
	}
}

func TestRedactJSON_BodyVazio(t *testing.T) {
	if got := RedactJSON(nil); got != "" {
		t.Fatalf("body vazio deveria virar string vazia, veio: %q", got)
	}
}

func TestIsSensitive_PegaVariacoes(t *testing.T) {
	// A checagem é por substring justamente para cobrir os nomes reais que
	// aparecem no código (current_password, PasswordHash, X-Api-Key...).
	sensitive := []string{"password", "current_password", "PasswordHash", "api_key", "Authorization", "jwt"}
	for _, k := range sensitive {
		if !isSensitive(k) {
			t.Errorf("%q deveria ser tratado como sensível", k)
		}
	}

	safe := []string{"username", "email", "keywords", "price"}
	for _, k := range safe {
		if isSensitive(k) {
			t.Errorf("%q não é sensível e foi redigido à toa", k)
		}
	}
}
