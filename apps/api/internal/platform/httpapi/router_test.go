package httpapi_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/platform/httpapi"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth/jwttest"
)

// testAPI is the whole generated server interface for router tests: real health, stub settings.
type testAPI struct{ health *httpapi.HealthServer }

func newTestAPI(db httpapi.Pinger) testAPI { return testAPI{health: httpapi.NewHealthServer(db)} }

func (a testAPI) GetHealth(ctx context.Context, r openapi.GetHealthRequestObject) (openapi.GetHealthResponseObject, error) {
	return a.health.GetHealth(ctx, r)
}

func (testAPI) GetSettings(context.Context, openapi.GetSettingsRequestObject) (openapi.GetSettingsResponseObject, error) {
	return openapi.GetSettings200JSONResponse{}, nil
}

func (testAPI) PutSettings(context.Context, openapi.PutSettingsRequestObject) (openapi.PutSettingsResponseObject, error) {
	return openapi.PutSettings200JSONResponse{}, nil
}

func newRouter(t *testing.T) (handler http.Handler, validToken string) {
	t.Helper()
	jwksURL, sign := jwttest.NewIssuer(t)
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)
	verifier, err := jwtauth.NewVerifier(ctx, jwksURL)
	if err != nil {
		t.Fatalf("NewVerifier() error = %v", err)
	}
	valid := sign(jwt.MapClaims{
		"sub": "0b6a1d3c-6c6e-4f0e-9d5e-6f6c5d8f3a11",
		"aud": "authenticated",
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	return httpapi.NewHandler(verifier, newTestAPI(fakePinger{})), valid
}

func TestRouterRequiresJWTOnEverythingExceptHealth(t *testing.T) { // NFR-004, M1 definition of done
	jwksURL, sign := jwttest.NewIssuer(t)
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)
	verifier, err := jwtauth.NewVerifier(ctx, jwksURL)
	if err != nil {
		t.Fatalf("NewVerifier() error = %v", err)
	}
	handler := httpapi.NewHandler(verifier, newTestAPI(fakePinger{}))

	valid := sign(jwt.MapClaims{
		"sub": "0b6a1d3c-6c6e-4f0e-9d5e-6f6c5d8f3a11",
		"aud": "authenticated",
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	expired := sign(jwt.MapClaims{
		"sub": "0b6a1d3c-6c6e-4f0e-9d5e-6f6c5d8f3a11",
		"aud": "authenticated",
		"exp": time.Now().Add(-time.Minute).Unix(),
	})

	tests := []struct {
		name   string
		method string
		path   string
		token  string
		want   int
	}{
		{"health without token", http.MethodGet, "/v1/health", "", http.StatusOK},
		{"other method on health without token", http.MethodPost, "/v1/health", "", http.StatusUnauthorized},
		{"unknown path without token", http.MethodGet, "/v1/unknown", "", http.StatusUnauthorized},
		{"root without token", http.MethodGet, "/", "", http.StatusUnauthorized},
		{"unknown path with valid token", http.MethodGet, "/v1/unknown", valid, http.StatusNotFound},
		{"unknown path with expired token", http.MethodGet, "/v1/unknown", expired, http.StatusUnauthorized},
		{"GET settings without token", http.MethodGet, "/v1/settings", "", http.StatusUnauthorized},
		{"PUT settings without token", http.MethodPut, "/v1/settings", "", http.StatusUnauthorized},
		{"GET settings with expired token", http.MethodGet, "/v1/settings", expired, http.StatusUnauthorized},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequestWithContext(t.Context(), tt.method, tt.path, nil)
			if tt.token != "" {
				req.Header.Set("Authorization", "Bearer "+tt.token)
			}
			rec := httptest.NewRecorder()

			handler.ServeHTTP(rec, req)

			if rec.Code != tt.want {
				t.Fatalf("%s %s = %d, want %d", tt.method, tt.path, rec.Code, tt.want)
			}
		})
	}
}

func TestRouterAnswersMalformedJSONWithJSONValidationError(t *testing.T) {
	handler, token := newRouter(t)
	req := httptest.NewRequestWithContext(t.Context(), http.MethodPut, "/v1/settings", strings.NewReader(`{"goal_kcal":`))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", rec.Code)
	}
	if ct := rec.Header().Get("Content-Type"); ct != "application/json" {
		t.Errorf("Content-Type = %q, want application/json", ct)
	}
	var body openapi.Error
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("body %q is not JSON: %v", rec.Body.String(), err)
	}
	if body.Code != openapi.ErrorCodeVALIDATIONERROR {
		t.Errorf("code = %s, want VALIDATION_ERROR", body.Code)
	}
	if strings.Contains(rec.Body.String(), "goal_kcal") {
		t.Errorf("body echoes the input: %s", rec.Body.String())
	}
}
