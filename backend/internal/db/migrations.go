package db

import (
	"embed"
	"errors"
	"fmt"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
)

// migrationFiles embute os .sql no binário: o schema viaja junto com a imagem,
// sem depender de um `migrate` CLI instalado nem de arquivos montados no host.
//
//go:embed migrations/*.sql
var migrationFiles embed.FS

// Migrate aplica todas as migrations pendentes. Idempotente: sem nada pendente
// devolve nil (ErrNoChange não é erro). Roda no boot da API, antes de qualquer
// query — um banco recém-criado não tem tabela alguma, e o bootstrap do admin
// falharia com `relation "users" does not exist`.
func Migrate(databaseURL string) error {
	source, err := iofs.New(migrationFiles, "migrations")
	if err != nil {
		return fmt.Errorf("failed to open embedded migrations: %w", err)
	}

	m, err := migrate.NewWithSourceInstance("iofs", source, migrationURL(databaseURL))
	if err != nil {
		return fmt.Errorf("failed to init migrator: %w", err)
	}
	// Fecha só o handle do migrator (o source é fechado junto); o pool da
	// aplicação é criado à parte e não é afetado.
	defer m.Close()

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		return fmt.Errorf("failed to apply migrations: %w", err)
	}
	return nil
}

// migrationURL adapta a DATABASE_URL para o driver de migration. O pgx/v5 do
// golang-migrate se registra no scheme "pgx5", enquanto a aplicação usa
// "postgres://" com o pgxpool.
func migrationURL(databaseURL string) string {
	for _, scheme := range []string{"postgres://", "postgresql://"} {
		if len(databaseURL) >= len(scheme) && databaseURL[:len(scheme)] == scheme {
			return "pgx5://" + databaseURL[len(scheme):]
		}
	}
	return databaseURL
}

// _ garante que o driver pgx/v5 seja linkado (registra o scheme "pgx5").
var _ = pgx.Postgres{}
