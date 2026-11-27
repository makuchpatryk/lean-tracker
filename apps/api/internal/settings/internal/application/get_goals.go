// Package application holds the settings use cases, one user intent each.
package application

import (
	"context"

	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
)

// GetGoals returns the goals of one user.
type GetGoals struct {
	repo domain.Repository
}

// NewGetGoals returns the use case reading from repo.
func NewGetGoals(repo domain.Repository) *GetGoals { return &GetGoals{repo: repo} }

// Execute returns the user's goals, or domain.ErrNotFound when none are saved.
func (u *GetGoals) Execute(ctx context.Context, userID string) (domain.Goals, error) {
	return u.repo.Get(ctx, userID)
}
