// Package sidecar invoca os scripts Python em backend/sidecar/ (Playwright)
// como subprocessos — substitui o antigo pacote browser (chromedp), que
// passou a ser bloqueado pela detecção anti-bot da Cloudflare no OLX.
package sidecar

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"syscall"
)

// scriptDir aponta para o diretório com os scripts Python. Overridable via
// SIDECAR_SCRIPT_DIR (usado nos testes, que apontam para fixtures em vez
// dos scripts reais); em produção aponta para o path fixo copiado no
// Dockerfile.
func scriptDir() string {
	if dir := os.Getenv("SIDECAR_SCRIPT_DIR"); dir != "" {
		return dir
	}
	return "/app/sidecar"
}

// pythonBin permite trocar o interpretador (ex: apontar para /bin/sh nos
// testes, rodando fixtures shell script em vez de Python de verdade — evita
// depender de Python instalado no runner de CI para testes hermáticos).
func pythonBin() string {
	if bin := os.Getenv("SIDECAR_PYTHON_BIN"); bin != "" {
		return bin
	}
	return "python3"
}

// Run executa o script informado (ex: "olx_search.py"), envia input como
// JSON no stdin e decodifica um único objeto JSON do stdout em output.
// Respeita cancelamento/timeout do ctx (exec.CommandContext mata o
// subprocesso automaticamente). Retorna erro só para falhas de
// infraestrutura (processo não rodou, saída não é JSON válido) — falhas de
// scraping esperadas (ok=false no JSON decodificado) são responsabilidade
// do chamador interpretar a partir do output.
func Run(ctx context.Context, script string, input, output any) error {
	inBytes, err := json.Marshal(input)
	if err != nil {
		return fmt.Errorf("sidecar: marshal input: %w", err)
	}

	cmd := exec.CommandContext(ctx, pythonBin(), scriptDir()+"/"+script)
	cmd.Stdin = bytes.NewReader(inBytes)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// python3/sh podem gerar processos filhos (o próprio Playwright sobe o
	// Chromium como subprocesso) — matar só o processo direto no cancelamento
	// do ctx deixaria esses filhos órfãos e presos. Colocar num process group
	// próprio e matar o grupo inteiro garante que tudo morre junto.
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd.Cancel = func() error {
		return syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
	}

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("sidecar: %s failed: %w (stderr: %s)", script, err, stderr.String())
	}

	if err := json.Unmarshal(stdout.Bytes(), output); err != nil {
		return fmt.Errorf("sidecar: %s produced invalid JSON output: %w (stdout: %s, stderr: %s)", script, err, stdout.String(), stderr.String())
	}
	return nil
}
