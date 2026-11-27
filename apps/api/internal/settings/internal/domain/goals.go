// Package domain holds the settings rules: daily goals and their ranges (BR-003).
package domain

import (
	"context"
	"errors"
	"fmt"
	"time"

	"example.com/lean-tracker/apps/api/internal/kernel/limits"
)

// Goals are the four daily goals of one user.
type Goals struct {
	KCal, ProteinG, FatG, CarbsG int
}

// Field names a goal in the contract (the Settings schema property).
type Field string

// Goal fields, named as in the contract.
const (
	FieldKCal     Field = "goal_kcal"
	FieldProteinG Field = "goal_protein_g"
	FieldFatG     Field = "goal_fat_g"
	FieldCarbsG   Field = "goal_carbs_g"
)

// OutOfRangeError reports the first goal outside its allowed range.
type OutOfRangeError struct {
	Field    Field
	Min, Max int
}

func (e *OutOfRangeError) Error() string {
	return fmt.Sprintf("%s must be from %d to %d", e.Field, e.Min, e.Max)
}

// ErrNotFound means the user has saved no goals yet.
var ErrNotFound = errors.New("settings: not found")

// NewGoals validates the four goals (BR-003) and returns the first failing field as *OutOfRangeError.
func NewGoals(kcal, protein, fat, carbs int) (Goals, error) {
	checks := []struct {
		field    Field
		value    int
		min, max int
	}{
		{FieldKCal, kcal, limits.GoalKcalMin, limits.GoalKcalMax},
		{FieldProteinG, protein, limits.GoalMacroMin, limits.GoalMacroMax},
		{FieldFatG, fat, limits.GoalMacroMin, limits.GoalMacroMax},
		{FieldCarbsG, carbs, limits.GoalMacroMin, limits.GoalMacroMax},
	}
	for _, c := range checks {
		if c.value < c.min || c.value > c.max {
			return Goals{}, &OutOfRangeError{Field: c.field, Min: c.min, Max: c.max}
		}
	}
	return Goals{KCal: kcal, ProteinG: protein, FatG: fat, CarbsG: carbs}, nil
}

// Repository stores goals. Every method takes the user id and touches only that user's row (BR-001).
type Repository interface {
	// Get returns the user's goals, or ErrNotFound when none are saved.
	Get(ctx context.Context, userID string) (Goals, error)
	// Upsert creates or replaces the user's goals and stamps updated_at with at.
	Upsert(ctx context.Context, userID string, g Goals, at time.Time) error
}
