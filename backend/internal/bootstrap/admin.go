package bootstrap

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

// EnsureAdmin cria o primeiro admin do sistema se, e somente se, a tabela de
// Users estiver vazia. Idempotente: em boots subsequentes, com usuários já
// existentes, não faz nada — não há endpoint público de bootstrap.
func EnsureAdmin(ctx context.Context, pool *pgxpool.Pool, adminEmail, adminPassword string) error {
	queries := sqlcgen.New(pool)

	users, err := queries.ListUsers(ctx)
	if err != nil {
		return fmt.Errorf("failed to check existing users: %w", err)
	}
	if len(users) > 0 {
		return nil
	}

	if adminEmail == "" || adminPassword == "" {
		return fmt.Errorf("no users exist yet and ADMIN_EMAIL/ADMIN_PASSWORD are not set")
	}
	if len(adminPassword) < auth.MinPasswordLength {
		return fmt.Errorf("ADMIN_PASSWORD must be at least %d characters", auth.MinPasswordLength)
	}

	hash, err := auth.HashPassword(adminPassword)
	if err != nil {
		return fmt.Errorf("failed to hash admin password: %w", err)
	}

	_, err = queries.CreateUser(ctx, sqlcgen.CreateUserParams{
		Name:         "Admin",
		Email:        adminEmail,
		PasswordHash: hash,
		Role:         auth.RoleAdmin,
	})
	if err != nil {
		return fmt.Errorf("failed to create initial admin: %w", err)
	}

	return nil
}
