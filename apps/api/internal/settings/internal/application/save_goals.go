package application

import (
	"context"

	"example.com/lean-tracker/apps/api/internal/kernel/clock"
	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
)

// SaveGoals validates and stores the goals of one user.
type SaveGoals struct {
	repo  domain.Repository
	clock clock.Clock
}

// NewSaveGoals returns the use case writing to repo and stamping rows from clk.
func NewSaveGoals(repo domain.Repository, clk clock.Clock) *SaveGoals {
	return &SaveGoals{repo: repo, clock: clk}
}

// Execute validates the goals first (BR-003) and only then upserts, stamping updated_at in UTC.
// Invalid goals return *domain.OutOfRangeError and never reach the repository.
func (u *SaveGoals) Execute(ctx context.Context, userID string, kcal, protein, fat, carbs int) (domain.Goals, error) {
	goals, err := domain.NewGoals(kcal, protein, fat, carbs)
	if err != nil {
		return domain.Goals{}, err
	}
	if err := u.repo.Upsert(ctx, userID, goals, u.clock.Now().UTC()); err != nil {
		return domain.Goals{}, err
	}
	return goals, nil
}
