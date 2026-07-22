package scan

import (
	"context"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

// newTestPool sobe um Postgres efêmero via testcontainers, aplica a
// migration inicial e retorna um pool pronto para uso. O container é
// derrubado automaticamente ao fim do teste (t.Cleanup). Espelha o helper
// equivalente em internal/httpapi/testdb_test.go — duplicado por
// simplicidade, já que os dois pacotes de teste são independentes.
func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	ctx := context.Background()

	_, thisFile, _, _ := runtime.Caller(0)
	migrationPath := filepath.Join(filepath.Dir(thisFile), "..", "db", "migrations", "000001_init.up.sql")

	container, err := postgres.Run(ctx, "postgres:16-alpine",
		postgres.WithDatabase("achapramim_test"),
		postgres.WithUsername("achapramim"),
		postgres.WithPassword("achapramim"),
		postgres.WithInitScripts(migrationPath),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").WithOccurrence(2),
		),
	)
	if err != nil {
		t.Fatalf("failed to start postgres container: %v", err)
	}
	t.Cleanup(func() {
		if err := container.Terminate(context.Background()); err != nil {
			t.Logf("failed to terminate postgres container: %v", err)
		}
	})

	connStr, err := container.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("failed to get connection string: %v", err)
	}

	pool, err := pgxpool.New(ctx, connStr)
	if err != nil {
		t.Fatalf("failed to connect to test database: %v", err)
	}
	t.Cleanup(pool.Close)

	return pool
}
