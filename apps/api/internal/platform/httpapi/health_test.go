package httpapi_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/platform/httpapi"
)

type fakePinger struct{ err error }

func (f fakePinger) Ping(context.Context) error { return f.err }

// getHealth calls GET /v1/health through the generated strict handler, as the router does.
func getHealth(t *testing.T, db httpapi.Pinger) *httptest.ResponseRecorder {
	t.Helper()
	mux := http.NewServeMux()
	openapi.HandlerWithOptions(openapi.NewStrictHandler(newTestAPI(db), nil), openapi.StdHTTPServerOptions{BaseRouter: mux})
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequestWithContext(t.Context(), http.MethodGet, "/v1/health", nil))
	return rec
}

func TestHealthReturns200WhenDatabaseAnswers(t *testing.T) {
	rec := getHealth(t, fakePinger{})

	if rec.Code != http.StatusOK || strings.TrimSpace(rec.Body.String()) != `{"status":"ok"}` {
		t.Fatalf("got %d %q; want 200 {\"status\":\"ok\"}", rec.Code, rec.Body.String())
	}
}

func TestHealthReturns503WhenDatabasePingFails(t *testing.T) {
	rec := getHealth(t, fakePinger{err: errors.New("connection refused")})

	if rec.Code != http.StatusServiceUnavailable || strings.TrimSpace(rec.Body.String()) != `{"status":"unavailable"}` {
		t.Fatalf("got %d %q; want 503 {\"status\":\"unavailable\"}", rec.Code, rec.Body.String())
	}
}
