package transport_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/kernel/requestuser"
	"example.com/lean-tracker/apps/api/internal/settings/internal/application"
	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
	"example.com/lean-tracker/apps/api/internal/settings/internal/transport"
)

type fixedClock struct{}

func (fixedClock) Now() time.Time { return time.Date(2026, 11, 27, 12, 0, 0, 0, time.UTC) }

// fakeRepo is an in-memory domain.Repository; err, when set, fails every call.
type fakeRepo struct {
	rows map[string]domain.Goals
	err  error
}

func (r *fakeRepo) Get(_ context.Context, userID string) (domain.Goals, error) {
	if r.err != nil {
		return domain.Goals{}, r.err
	}
	g, ok := r.rows[userID]
	if !ok {
		return domain.Goals{}, domain.ErrNotFound
	}
	return g, nil
}

func (r *fakeRepo) Upsert(_ context.Context, userID string, g domain.Goals, _ time.Time) error {
	if r.err != nil {
		return r.err
	}
	r.rows[userID] = g
	return nil
}

// newServer serves the generated strict handler. A request carrying the X-Test-User header gets that
// user id in its context, as the JWT middleware would set it; one without the header gets none.
func newServer(repo *fakeRepo) http.Handler {
	h := transport.NewHandler(application.NewGetGoals(repo), application.NewSaveGoals(repo, fixedClock{}))
	mux := http.NewServeMux()
	openapi.HandlerWithOptions(openapi.NewStrictHandler(h, nil), openapi.StdHTTPServerOptions{BaseRouter: mux})
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if user := r.Header.Get("X-Test-User"); user != "" {
			r = r.WithContext(requestuser.WithUserID(r.Context(), user))
		}
		mux.ServeHTTP(w, r)
	})
}

func do(t *testing.T, srv http.Handler, method, body, user string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequestWithContext(t.Context(), method, "/v1/settings", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if user != "" {
		req.Header.Set("X-Test-User", user)
	}
	rec := httptest.NewRecorder()
	srv.ServeHTTP(rec, req)
	return rec
}

func decodeError(t *testing.T, rec *httptest.ResponseRecorder) openapi.Error {
	t.Helper()
	var e openapi.Error
	if err := json.Unmarshal(rec.Body.Bytes(), &e); err != nil {
		t.Fatalf("decode error body %q: %v", rec.Body.String(), err)
	}
	return e
}

const validBody = `{"goal_kcal":2000,"goal_protein_g":100,"goal_fat_g":60,"goal_carbs_g":250}`

func TestGetWithoutRowIsNotFound(t *testing.T) {
	srv := newServer(&fakeRepo{rows: map[string]domain.Goals{}})

	rec := do(t, srv, http.MethodGet, "", "user-a")

	if rec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", rec.Code)
	}
	if e := decodeError(t, rec); e.Code != openapi.ErrorCodeSETTINGSNOTFOUND {
		t.Errorf("code = %s, want SETTINGS_NOT_FOUND", e.Code)
	}
}

func TestPutKcalBelowRangeIsValidationError(t *testing.T) { // BR-003, FR-002
	srv := newServer(&fakeRepo{rows: map[string]domain.Goals{}})

	rec := do(t, srv, http.MethodPut, `{"goal_kcal":499,"goal_protein_g":100,"goal_fat_g":60,"goal_carbs_g":250}`, "user-a")

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", rec.Code)
	}
	e := decodeError(t, rec)
	if e.Code != openapi.ErrorCodeVALIDATIONERROR || e.Message != "goal_kcal must be from 500 to 10000." {
		t.Errorf("error = %+v", e)
	}
}

func TestPutThenGetReturnsTheSameGoals(t *testing.T) {
	srv := newServer(&fakeRepo{rows: map[string]domain.Goals{}})

	put := do(t, srv, http.MethodPut, validBody, "user-a")
	if put.Code != http.StatusOK || strings.TrimSpace(put.Body.String()) != compact(t, validBody) {
		t.Fatalf("PUT = %d %s, want 200 echoing the goals", put.Code, put.Body.String())
	}
	get := do(t, srv, http.MethodGet, "", "user-a")
	if get.Code != http.StatusOK || strings.TrimSpace(get.Body.String()) != compact(t, validBody) {
		t.Fatalf("GET = %d %s, want 200 with the same goals", get.Code, get.Body.String())
	}
}

// compact re-encodes the body the way the generated response writes it (struct field order).
func compact(t *testing.T, body string) string {
	t.Helper()
	var s openapi.Settings
	if err := json.Unmarshal([]byte(body), &s); err != nil {
		t.Fatal(err)
	}
	out, err := json.Marshal(s)
	if err != nil {
		t.Fatal(err)
	}
	return string(out)
}

func TestAnotherUserDoesNotSeeTheGoals(t *testing.T) { // BR-001
	srv := newServer(&fakeRepo{rows: map[string]domain.Goals{}})
	do(t, srv, http.MethodPut, validBody, "user-a")

	rec := do(t, srv, http.MethodGet, "", "user-b")

	if rec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", rec.Code)
	}
}

func TestNoUserIdIsUnauthorized(t *testing.T) { // NFR-004, defensive: the middleware already gates
	srv := newServer(&fakeRepo{rows: map[string]domain.Goals{}})

	for _, tc := range []struct{ method, body string }{{http.MethodGet, ""}, {http.MethodPut, validBody}} {
		rec := do(t, srv, tc.method, tc.body, "")
		if rec.Code != http.StatusUnauthorized {
			t.Errorf("%s status = %d, want 401", tc.method, rec.Code)
		}
		if e := decodeError(t, rec); e.Code != openapi.ErrorCodeUNAUTHORIZED {
			t.Errorf("%s code = %s, want UNAUTHORIZED", tc.method, e.Code)
		}
	}
}

func TestRepositoryErrorIsInternalErrorWithoutLeak(t *testing.T) {
	srv := newServer(&fakeRepo{err: errors.New("connection to db.internal:5432 refused")})

	for _, tc := range []struct{ method, body string }{{http.MethodGet, ""}, {http.MethodPut, validBody}} {
		rec := do(t, srv, tc.method, tc.body, "user-a")
		if rec.Code != http.StatusInternalServerError {
			t.Fatalf("%s status = %d, want 500", tc.method, rec.Code)
		}
		if e := decodeError(t, rec); e.Code != openapi.ErrorCodeINTERNALERROR || e.Message != "Unexpected error." {
			t.Errorf("%s error = %+v", tc.method, e)
		}
		if strings.Contains(rec.Body.String(), "db.internal") {
			t.Errorf("%s body leaks the error text: %s", tc.method, rec.Body.String())
		}
	}
}
