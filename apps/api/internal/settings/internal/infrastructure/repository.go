// Package infrastructure adapts the settings ports to Postgres. It holds the only SQL of the module.
package infrastructure

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
)

// Querier is the part of the connection pool the repository needs; *pgxpool.Pool satisfies it.
type Querier interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
}

// Repository implements domain.Repository on public.user_settings.
type Repository struct{ db Querier }

// NewRepository returns a Repository running its statements on db.
func NewRepository(db Querier) *Repository { return &Repository{db: db} }

const selectGoals = `select goal_kcal, goal_protein_g, goal_fat_g, goal_carbs_g
from public.user_settings
where user_id = $1`

// Get returns the goals of userID, or domain.ErrNotFound. It never reads another user's row (BR-001).
func (r *Repository) Get(ctx context.Context, userID string) (domain.Goals, error) {
	var g domain.Goals
	err := r.db.QueryRow(ctx, selectGoals, userID).Scan(&g.KCal, &g.ProteinG, &g.FatG, &g.CarbsG)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Goals{}, domain.ErrNotFound
	}
	if err != nil {
		return domain.Goals{}, err
	}
	return g, nil
}

const upsertGoals = `insert into public.user_settings (user_id, goal_kcal, goal_protein_g, goal_fat_g, goal_carbs_g, updated_at)
values ($1, $2, $3, $4, $5, $6)
on conflict (user_id) do update set
  goal_kcal = excluded.goal_kcal,
  goal_protein_g = excluded.goal_protein_g,
  goal_fat_g = excluded.goal_fat_g,
  goal_carbs_g = excluded.goal_carbs_g,
  updated_at = excluded.updated_at`

// Upsert writes the goals of userID, creating the row or replacing its values. The conflict target is
// user_id, so a call for one user can never change another user's row (BR-001).
func (r *Repository) Upsert(ctx context.Context, userID string, g domain.Goals, at time.Time) error {
	_, err := r.db.Exec(ctx, upsertGoals, userID, g.KCal, g.ProteinG, g.FatG, g.CarbsG, at)
	return err
}
