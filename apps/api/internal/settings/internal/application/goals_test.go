package application_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"example.com/lean-tracker/apps/api/internal/settings/internal/application"
	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
)

type fixedClock struct{ now time.Time }

func (c fixedClock) Now() time.Time { return c.now }

// fakeRepo is an in-memory domain.Repository keyed by user id, like the real one (BR-001).
type fakeRepo struct {
	rows    map[string]domain.Goals
	stamps  map[string]time.Time
	upserts int
}

func newFakeRepo() *fakeRepo {
	return &fakeRepo{rows: map[string]domain.Goals{}, stamps: map[string]time.Time{}}
}

func (r *fakeRepo) Get(_ context.Context, userID string) (domain.Goals, error) {
	g, ok := r.rows[userID]
	if !ok {
		return domain.Goals{}, domain.ErrNotFound
	}
	return g, nil
}

func (r *fakeRepo) Upsert(_ context.Context, userID string, g domain.Goals, at time.Time) error {
	r.upserts++
	r.rows[userID] = g
	r.stamps[userID] = at
	return nil
}

func TestSaveGoalsStampsUpdatedAtFromClockInUTC(t *testing.T) {
	repo := newFakeRepo()
	warsaw := time.FixedZone("CET", 3600)
	now := time.Date(2026, 11, 27, 12, 0, 0, 0, warsaw)
	save := application.NewSaveGoals(repo, fixedClock{now: now})

	if _, err := save.Execute(context.Background(), "user-a", 2000, 100, 60, 250); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	got := repo.stamps["user-a"]
	if !got.Equal(now) || got.Location() != time.UTC {
		t.Errorf("updated_at = %v, want %v in UTC", got, now.UTC())
	}
}

func TestSaveGoalsInvalidNeverReachesRepository(t *testing.T) {
	// BR-003: kcal 499 is rejected before any write.
	repo := newFakeRepo()
	save := application.NewSaveGoals(repo, fixedClock{})

	_, err := save.Execute(context.Background(), "user-a", 499, 100, 60, 250)
	var outOfRange *domain.OutOfRangeError
	if !errors.As(err, &outOfRange) {
		t.Fatalf("want *OutOfRangeError, got %v", err)
	}
	if repo.upserts != 0 {
		t.Errorf("repository was called %d times, want 0", repo.upserts)
	}
}

func TestGetGoalsUnknownUserIsNotFound(t *testing.T) {
	get := application.NewGetGoals(newFakeRepo())

	_, err := get.Execute(context.Background(), "nobody")
	if !errors.Is(err, domain.ErrNotFound) {
		t.Fatalf("want ErrNotFound, got %v", err)
	}
}

func TestSavedGoalsAreNotVisibleToAnotherUser(t *testing.T) {
	// BR-001: user A's goals are never returned for user B.
	repo := newFakeRepo()
	save := application.NewSaveGoals(repo, fixedClock{})
	get := application.NewGetGoals(repo)

	if _, err := save.Execute(context.Background(), "user-a", 2000, 100, 60, 250); err != nil {
		t.Fatalf("save: %v", err)
	}
	if _, err := get.Execute(context.Background(), "user-b"); !errors.Is(err, domain.ErrNotFound) {
		t.Fatalf("user B read: want ErrNotFound, got %v", err)
	}
	got, err := get.Execute(context.Background(), "user-a")
	if err != nil || got.KCal != 2000 {
		t.Fatalf("user A read: got %+v, %v", got, err)
	}
}
