package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

type Config struct {
	HTTPPort string

	DatabaseURL string

	JWTSecret       string
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration

	AnthropicAPIKey string

	MercadoLivreAppID     string
	MercadoLivreAppSecret string

	IbexBotBaseURL string
	IbexBotToken   string

	TelegramBotToken string

	// Bootstrap do primeiro admin: se não houver nenhum User no banco no
	// boot, um admin é criado automaticamente com essas credenciais.
	AdminEmail    string
	AdminPassword string
}

func Load() (Config, error) {
	cfg := Config{
		HTTPPort:              getEnv("HTTP_PORT", "8080"),
		DatabaseURL:           os.Getenv("DATABASE_URL"),
		JWTSecret:             os.Getenv("JWT_SECRET"),
		AnthropicAPIKey:       os.Getenv("ANTHROPIC_API_KEY"),
		MercadoLivreAppID:     os.Getenv("MERCADO_LIVRE_APP_ID"),
		MercadoLivreAppSecret: os.Getenv("MERCADO_LIVRE_APP_SECRET"),
		IbexBotBaseURL:        os.Getenv("IBEX_BOT_BASE_URL"),
		IbexBotToken:          os.Getenv("IBEX_BOT_TOKEN"),
		TelegramBotToken:      os.Getenv("TELEGRAM_BOT_TOKEN"),
		AdminEmail:            os.Getenv("ADMIN_EMAIL"),
		AdminPassword:         os.Getenv("ADMIN_PASSWORD"),
	}

	accessTTL, err := getDurationMinutes("ACCESS_TOKEN_TTL_MINUTES", 30)
	if err != nil {
		return Config{}, err
	}
	cfg.AccessTokenTTL = accessTTL

	refreshTTL, err := getDurationMinutes("REFRESH_TOKEN_TTL_MINUTES", 30*24*60)
	if err != nil {
		return Config{}, err
	}
	cfg.RefreshTokenTTL = refreshTTL

	if cfg.DatabaseURL == "" {
		return Config{}, fmt.Errorf("DATABASE_URL is required")
	}
	if cfg.JWTSecret == "" {
		return Config{}, fmt.Errorf("JWT_SECRET is required")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getDurationMinutes(key string, fallbackMinutes int) (time.Duration, error) {
	v := os.Getenv(key)
	if v == "" {
		return time.Duration(fallbackMinutes) * time.Minute, nil
	}
	minutes, err := strconv.Atoi(v)
	if err != nil {
		return 0, fmt.Errorf("%s must be an integer number of minutes: %w", key, err)
	}
	return time.Duration(minutes) * time.Minute, nil
}
