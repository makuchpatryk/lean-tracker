package httpapi_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"example.com/lean-tracker/apps/api/internal/platform/httpapi"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth/jwttest"
)

func TestRouterRequiresJWTOnEverythingExceptHealth(t *testing.T) { // NFR-004, M1 definition of done
	jwksURL, sign := jwttest.NewIssuer(t)
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)
	verifier, err := jwtauth.NewVerifier(ctx, jwksURL)
	if err != nil {
		t.Fatalf("NewVerifier() error = %v", err)
	}
	handler := httpapi.NewHandler(verifier, httpapi.NewHealthServer(fakePinger{}))

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
