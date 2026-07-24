# --- Build stage ---
FROM golang:1.26-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o /out/api ./cmd/api

# --- Runtime stage ---
# glibc (não Alpine/musl) porque o Playwright assume glibc para o Chromium
# que baixa via `playwright install` — necessário em runtime (não só build)
# porque o backend controla um browser real via sidecar Python/Playwright
# para contornar bloqueio anti-bot de fingerprint no OLXFetcher e no
# link-preview (ver docs/adr/0002 e o ADR sobre a migração de chromedp).
FROM python:3.13-slim-bookworm
WORKDIR /app

# wget: usado pelo healthcheck do stack (compose.yml) para checar
# /api/health — a imagem base não traz nenhum client HTTP por padrão.
RUN apt-get update && apt-get install -y --no-install-recommends wget \
    && rm -rf /var/lib/apt/lists/*

COPY sidecar/requirements.txt ./sidecar/requirements.txt
RUN pip install --no-cache-dir -r sidecar/requirements.txt \
    && playwright install --with-deps chromium

COPY sidecar/ ./sidecar/
COPY --from=builder /out/api ./api
COPY internal/db/migrations ./internal/db/migrations

ENV SIDECAR_SCRIPT_DIR=/app/sidecar

EXPOSE 8080

CMD ["./api"]
