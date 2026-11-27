// Package database opens the Postgres connection pool.
package database

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Open creates the pool without pinging: pgxpool connects lazily, so the API starts while the database
// is down and /v1/health reports 503 until it is back.
func Open(ctx context.Context, url string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		// The pgx error can quote the DSN; keep only a fixed message.
		return nil, errors.New("database: invalid DATABASE_URL")
	}
	return pool, nil
}
