package httpapi

import (
	"context"
	"errors"
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

// getOwnedWatch busca um Watch por ID e confirma que claims é o dono ou é
// admin. Se ok=false, a resposta de erro já foi escrita em w e o chamador
// deve retornar imediatamente. Acesso negado também vira 404 (não 403),
// para não vazar a existência do recurso a quem não tem acesso — mesma
// regra usada em todos os endpoints de Watch.
func getOwnedWatch(ctx context.Context, w http.ResponseWriter, q *sqlcgen.Queries, watchID pgtype.UUID, claims *auth.Claims) (sqlcgen.Watch, bool) {
	watch, err := q.GetWatchByID(ctx, watchID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusNotFound, "watch not found")
			return sqlcgen.Watch{}, false
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return sqlcgen.Watch{}, false
	}
	if uuidString(watch.UserID) != claims.UserID && !auth.IsAdmin(claims) {
		writeError(w, http.StatusNotFound, "watch not found")
		return sqlcgen.Watch{}, false
	}
	return watch, true
}
