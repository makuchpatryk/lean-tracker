package domain_test

import (
	"errors"
	"testing"

	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
)

// valid returns goals that pass NewGoals; a test overrides the one value under test.
func valid() [4]int { return [4]int{2000, 100, 60, 250} }

func TestNewGoalsRanges(t *testing.T) {
	// BR-003: kcal is 500..10000, protein, fat and carbs are 0..1000.
	tests := []struct {
		name      string
		index     int
		value     int
		field     domain.Field
		wantError bool
	}{
		{"kcal 499 rejected", 0, 499, domain.FieldKCal, true},
		{"kcal 500 accepted", 0, 500, domain.FieldKCal, false},
		{"kcal 10000 accepted", 0, 10000, domain.FieldKCal, false},
		{"kcal 10001 rejected", 0, 10001, domain.FieldKCal, true},
		{"protein -1 rejected", 1, -1, domain.FieldProteinG, true},
		{"protein 0 accepted", 1, 0, domain.FieldProteinG, false},
		{"protein 1000 accepted", 1, 1000, domain.FieldProteinG, false},
		{"protein 1001 rejected", 1, 1001, domain.FieldProteinG, true},
		{"fat -1 rejected", 2, -1, domain.FieldFatG, true},
		{"fat 0 accepted", 2, 0, domain.FieldFatG, false},
		{"fat 1000 accepted", 2, 1000, domain.FieldFatG, false},
		{"fat 1001 rejected", 2, 1001, domain.FieldFatG, true},
		{"carbs -1 rejected", 3, -1, domain.FieldCarbsG, true},
		{"carbs 0 accepted", 3, 0, domain.FieldCarbsG, false},
		{"carbs 1000 accepted", 3, 1000, domain.FieldCarbsG, false},
		{"carbs 1001 rejected", 3, 1001, domain.FieldCarbsG, true},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			v := valid()
			v[tc.index] = tc.value
			_, err := domain.NewGoals(v[0], v[1], v[2], v[3])
			if !tc.wantError {
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}
				return
			}
			var outOfRange *domain.OutOfRangeError
			if !errors.As(err, &outOfRange) {
				t.Fatalf("want *OutOfRangeError, got %v", err)
			}
			if outOfRange.Field != tc.field {
				t.Errorf("field = %s, want %s", outOfRange.Field, tc.field)
			}
		})
	}
}

func TestNewGoalsReturnsAllValues(t *testing.T) {
	got, err := domain.NewGoals(2000, 100, 60, 250)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := domain.Goals{KCal: 2000, ProteinG: 100, FatG: 60, CarbsG: 250}
	if got != want {
		t.Errorf("goals = %+v, want %+v", got, want)
	}
}

func TestNewGoalsReportsFirstFailingField(t *testing.T) {
	_, err := domain.NewGoals(499, -1, 0, 0)
	var outOfRange *domain.OutOfRangeError
	if !errors.As(err, &outOfRange) || outOfRange.Field != domain.FieldKCal {
		t.Fatalf("want kcal reported first, got %v", err)
	}
	if outOfRange.Min != 500 || outOfRange.Max != 10000 {
		t.Errorf("range = %d..%d, want 500..10000", outOfRange.Min, outOfRange.Max)
	}
}
