// Package limits holds the rule values the API enforces. Each value is mirrored in
// apps/mobile/lib/kernel/limits and held equal to apps/api/openapi.yaml by a test (ARCHITECTURE AD6).
package limits

// Daily goal ranges (BR-003): kcal is an integer from 500 to 10000; protein, fat and carbs are
// integers from 0 to 1000 grams.
const (
	GoalKcalMin  = 500
	GoalKcalMax  = 10000
	GoalMacroMin = 0
	GoalMacroMax = 1000
)
