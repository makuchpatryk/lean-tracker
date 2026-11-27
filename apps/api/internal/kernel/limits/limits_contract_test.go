package limits_test

import (
	"testing"

	"github.com/getkin/kin-openapi/openapi3"

	"example.com/lean-tracker/apps/api/internal/kernel/limits"
)

// TestGoalLimitsEqualContract holds the Go constants equal to the Settings schema in the
// contract (AD6, BR-003).
func TestGoalLimitsEqualContract(t *testing.T) {
	doc, err := openapi3.NewLoader().LoadFromFile("../../../openapi.yaml")
	if err != nil {
		t.Fatalf("load contract: %v", err)
	}
	schema := doc.Components.Schemas["Settings"]
	if schema == nil || schema.Value == nil {
		t.Fatal("schema Settings missing from the contract")
	}
	tests := []struct {
		property string
		min, max int
	}{
		{"goal_kcal", limits.GoalKcalMin, limits.GoalKcalMax},
		{"goal_protein_g", limits.GoalMacroMin, limits.GoalMacroMax},
		{"goal_fat_g", limits.GoalMacroMin, limits.GoalMacroMax},
		{"goal_carbs_g", limits.GoalMacroMin, limits.GoalMacroMax},
	}
	for _, tc := range tests {
		t.Run(tc.property, func(t *testing.T) {
			prop := schema.Value.Properties[tc.property]
			if prop == nil || prop.Value == nil {
				t.Fatalf("property %s missing from Settings", tc.property)
			}
			if prop.Value.Min == nil || prop.Value.Max == nil {
				t.Fatalf("%s has no minimum/maximum in the contract", tc.property)
			}
			if got := int(*prop.Value.Min); got != tc.min {
				t.Errorf("%s minimum: contract %d, limits %d", tc.property, got, tc.min)
			}
			if got := int(*prop.Value.Max); got != tc.max {
				t.Errorf("%s maximum: contract %d, limits %d", tc.property, got, tc.max)
			}
		})
	}
}
