package httpapi

import (
	"net/http"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth"
)

// NewHandler returns the API handler. The JWT gate wraps the whole mux, so every request except
// GET /v1/health needs a valid token (NFR-004): unknown paths answer 401 without one and 404 with one.
func NewHandler(v jwtauth.TokenVerifier, health *HealthServer) http.Handler {
	mux := http.NewServeMux()
	openapi.HandlerWithOptions(openapi.NewStrictHandler(health, nil), openapi.StdHTTPServerOptions{BaseRouter: mux})
	isPublic := func(r *http.Request) bool { return r.Method == http.MethodGet && r.URL.Path == "/v1/health" }
	return jwtauth.Middleware(v, isPublic, mux)
}
