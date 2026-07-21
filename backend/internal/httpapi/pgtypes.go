package httpapi

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

func parseUUID(s string) pgtype.UUID {
	parsed := uuid.MustParse(s)
	return pgtype.UUID{Bytes: parsed, Valid: true}
}

func uuidString(u pgtype.UUID) string {
	return uuid.UUID(u.Bytes).String()
}

func pgTimestamptz(t time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: t, Valid: true}
}

// pgNumeric converte um percentual decimal (ex: "5.00") em pgtype.Numeric.
func pgNumeric(s string) (pgtype.Numeric, error) {
	var n pgtype.Numeric
	if err := n.Scan(s); err != nil {
		return n, fmt.Errorf("invalid decimal value %q: %w", s, err)
	}
	return n, nil
}

// numericString formata um pgtype.Numeric de volta como string decimal.
func numericString(n pgtype.Numeric) string {
	if !n.Valid {
		return ""
	}
	v, err := n.Value()
	if err != nil {
		return ""
	}
	return fmt.Sprintf("%v", v)
}
