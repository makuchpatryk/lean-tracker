package requestuser_test

import (
	"context"
	"testing"

	"example.com/lean-tracker/apps/api/internal/kernel/requestuser"
)

func TestUserIDRoundTrip(t *testing.T) {
	const id = "0b6a1d3c-6c6e-4f0e-9d5e-6f6c5d8f3a11"

	got, ok := requestuser.UserID(requestuser.WithUserID(context.Background(), id))

	if !ok || got != id {
		t.Fatalf("UserID() = %q, %v; want %q, true", got, ok, id)
	}
}

func TestUserIDMissingFromEmptyContext(t *testing.T) {
	if got, ok := requestuser.UserID(context.Background()); ok {
		t.Fatalf("UserID() = %q, true; want false on a context without a user", got)
	}
}

func TestUserIDEmptyStringIsNotAUser(t *testing.T) {
	if _, ok := requestuser.UserID(requestuser.WithUserID(context.Background(), "")); ok {
		t.Fatal("UserID() = true for an empty id; want false")
	}
}
