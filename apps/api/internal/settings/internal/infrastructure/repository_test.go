package infrastructure_test

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
	"example.com/lean-tracker/apps/api/internal/settings/internal/infrastructure"
)

// openDB connects to the local Postgres named by TEST_DATABASE_URL (make db-reset first). The test is
// skipped when the variable is unset, so CI and a plain `make test` stay database-free.
func openDB(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	pool, err := pgxpool.New(context.Background(), url)
	if err != nil {
		t.Fatalf("open pool: %v", err)
	}
	t.Cleanup(pool.Close)
	return pool
}

// newUser inserts a row into auth.users (the FK target of user_settings) and removes it with its
// settings row when the test ends.
func newUser(t *testing.T, pool *pgxpool.Pool) string {
	t.Helper()
	var id string
	if err := pool.QueryRow(context.Background(), `insert into auth.users (id) values (gen_random_uuid()) returning id::text`).Scan(&id); err != nil {
		t.Fatalf("insert auth user: %v", err)
	}
	t.Cleanup(func() {
		// on delete cascade removes the user_settings row.
		_, _ = pool.Exec(context.Background(), `delete from auth.users where id = $1`, id)
	})
	return id
}

func TestRepositoryIsolatesUsers(t *testing.T) {
	// BR-001: user B cannot read or overwrite user A's goals.
	ctx := context.Background()
	pool := openDB(t)
	repo := infrastructure.NewRepository(pool)
	userA, userB := newUser(t, pool), newUser(t, pool)
	at := time.Date(2026, 11, 27, 12, 0, 0, 0, time.UTC)
	goalsA := domain.Goals{KCal: 2000, ProteinG: 100, FatG: 60, CarbsG: 250}
	goalsB := domain.Goals{KCal: 1800, ProteinG: 90, FatG: 50, CarbsG: 200}

	if err := repo.Upsert(ctx, userA, goalsA, at); err != nil {
		t.Fatalf("upsert A: %v", err)
	}
	if _, err := repo.Get(ctx, userB); !errors.Is(err, domain.ErrNotFound) {
		t.Fatalf("B reads A: want ErrNotFound, got %v", err)
	}
	if err := repo.Upsert(ctx, userB, goalsB, at); err != nil {
		t.Fatalf("upsert B: %v", err)
	}
	gotA, err := repo.Get(ctx, userA)
	if err != nil || gotA != goalsA {
		t.Fatalf("A after B's upsert: got %+v, %v; want %+v", gotA, err, goalsA)
	}
}

func TestRepositoryUpsertUpdatesTheSameRow(t *testing.T) {
	ctx := context.Background()
	pool := openDB(t)
	repo := infrastructure.NewRepository(pool)
	user := newUser(t, pool)
	at := time.Date(2026, 11, 27, 12, 0, 0, 0, time.UTC)

	if err := repo.Upsert(ctx, user, domain.Goals{KCal: 2000, ProteinG: 100, FatG: 60, CarbsG: 250}, at); err != nil {
		t.Fatalf("first upsert: %v", err)
	}
	want := domain.Goals{KCal: 2500, ProteinG: 120, FatG: 70, CarbsG: 300}
	if err := repo.Upsert(ctx, user, want, at.Add(time.Hour)); err != nil {
		t.Fatalf("second upsert: %v", err)
	}

	got, err := repo.Get(ctx, user)
	if err != nil || got != want {
		t.Fatalf("get: got %+v, %v; want %+v", got, err, want)
	}
	var rows int
	if err := pool.QueryRow(ctx, `select count(*) from public.user_settings where user_id = $1`, user).Scan(&rows); err != nil || rows != 1 {
		t.Fatalf("rows for user = %d, %v; want 1", rows, err)
	}
}

func TestRepositoryGetForNewUserIsNotFound(t *testing.T) {
	pool := openDB(t)
	repo := infrastructure.NewRepository(pool)

	_, err := repo.Get(context.Background(), newUser(t, pool))
	if !errors.Is(err, domain.ErrNotFound) {
		t.Fatalf("want ErrNotFound, got %v", err)
	}
}
