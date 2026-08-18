// Package observability concentra o logging estruturado do backend: trace id,
// identidade de quem chamou, bodies de request/response e os passos
// intermediários de processamento — tudo em JSON, para ser filtrável no
// Grafana/Loki por campo em vez de busca textual.
package observability

import (
	"encoding/json"
	"strings"
)

// MaxBodyBytes limita o que vai para o log de cada body. Um Scan pode devolver
// centenas de KB de Offers, e o Loki cobra isso em retenção e ingest. 4KB
// preserva a forma do payload (e o começo do conteúdo) sem transformar uma
// requisição em vários KB de log.
const MaxBodyBytes = 4096

// sensitiveKeys são os campos cujo VALOR nunca pode chegar ao Loki. O log de
// body existe para depurar formato e conteúdo de negócio; credencial não é
// nenhum dos dois, e o Grafana é acessível na rede com retenção de 14 dias.
//
// A comparação é por substring em minúsculas, então "current_password",
// "new_password" e "passwordHash" caem todos em "password".
var sensitiveKeys = []string{
	"password",
	"senha",
	"token",
	"secret",
	"authorization",
	"apikey",
	"api_key",
	"credential",
	"jwt",
	"cookie",
}

const redacted = "[REDACTED]"

// isSensitive decide se uma chave de JSON tem seu valor suprimido.
func isSensitive(key string) bool {
	k := strings.ToLower(key)
	for _, s := range sensitiveKeys {
		if strings.Contains(k, s) {
			return true
		}
	}
	return false
}

// RedactJSON recebe um body cru e devolve uma versão segura para log: os
// valores de campos sensíveis viram [REDACTED], em qualquer profundidade
// (objetos aninhados e itens de array inclusive).
//
// Quando o body não é JSON válido (upload binário, form urlencoded, corpo
// truncado no meio), NÃO devolvemos o conteúdo cru: um body não-parseável pode
// ser justamente um POST de login em form-encoding, e cair no fallback
// "loga como veio" vazaria a senha. Nesse caso devolvemos só um marcador.
func RedactJSON(body []byte) string {
	if len(body) == 0 {
		return ""
	}

	var parsed any
	if err := json.Unmarshal(body, &parsed); err != nil {
		return "[non-json body omitted]"
	}

	safe := redactValue(parsed)

	out, err := json.Marshal(safe)
	if err != nil {
		return "[unserializable body omitted]"
	}

	return truncate(string(out))
}

// redactValue percorre a árvore do JSON substituindo valores sensíveis.
func redactValue(v any) any {
	switch val := v.(type) {
	case map[string]any:
		out := make(map[string]any, len(val))
		for k, inner := range val {
			if isSensitive(k) {
				out[k] = redacted
				continue
			}
			out[k] = redactValue(inner)
		}
		return out
	case []any:
		out := make([]any, len(val))
		for i, inner := range val {
			out[i] = redactValue(inner)
		}
		return out
	default:
		return val
	}
}

// truncate corta em MaxBodyBytes e sinaliza o corte, para que ninguém leia um
// payload cortado achando que é o payload inteiro.
func truncate(s string) string {
	if len(s) <= MaxBodyBytes {
		return s
	}
	return s[:MaxBodyBytes] + "...[truncated]"
}
