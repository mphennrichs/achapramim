.PHONY: deps build run test sqlc migrate-up migrate-down

deps:
	go mod tidy

build:
	go build ./...

run:
	go run ./cmd/api

# Testes de integração sobem Postgres via testcontainers-go. Em Colima (em
# vez de Docker Desktop), é preciso apontar o socket para dentro da VM:
#   export DOCKER_HOST="unix://$$HOME/.colima/default/docker.sock"
#   export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="/var/run/docker.sock"
test:
	go test ./...

sqlc:
	sqlc generate

migrate-up:
	migrate -database "$$DATABASE_URL" -path internal/db/migrations up

migrate-down:
	migrate -database "$$DATABASE_URL" -path internal/db/migrations down 1
