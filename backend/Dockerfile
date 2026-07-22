# --- Build stage ---
FROM golang:1.26-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o /out/api ./cmd/api

# --- Runtime stage ---
FROM alpine:3.20
WORKDIR /app

# chromium: necessário em runtime (não só build) porque o backend controla
# um browser real via chromedp/CDP para contornar bloqueio anti-bot de
# fingerprint no OLXFetcher e no link-preview (ver docs/adr/0002).
RUN apk add --no-cache ca-certificates chromium

ENV CHROME_EXEC_PATH=/usr/bin/chromium-browser

COPY --from=builder /out/api ./api
COPY internal/db/migrations ./internal/db/migrations

EXPOSE 8080

CMD ["./api"]
