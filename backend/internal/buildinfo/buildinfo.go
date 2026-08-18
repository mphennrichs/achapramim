// Package buildinfo expõe a versão do binário em execução, para que "o que
// está rodando agora?" seja respondido pelo próprio serviço em vez de inferido
// do pipeline de deploy — que pode ter sido disparado e não ter concluído (ou
// ter entrado em crash-loop) sem que nada indique isso.
package buildinfo

// Version e Commit são preenchidos no build da imagem via `-ldflags -X`
// (ver backend/Dockerfile). Os valores abaixo valem para qualquer execução
// fora daquele build (`go run`, `go test`) — e é esse o objetivo: um binário
// local deve reportar "dev" honestamente, nunca fingir ser uma versão real.
var (
	Version = "dev"
	Commit  = "unknown"
)
