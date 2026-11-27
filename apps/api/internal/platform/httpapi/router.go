package httpapi

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth"
)

// NewHandler returns the API handler. The JWT gate wraps the whole mux, so every request except
// GET /v1/health needs a valid token (NFR-004): unknown paths answer 401 without one and 404 with one.
// A body the generated server cannot decode and a handler error answer with the contract's JSON error,
// never the default text/plain.
func NewHandler(v jwtauth.TokenVerifier, api openapi.StrictServerInterface) http.Handler {
	mux := http.NewServeMux()
	strict := openapi.NewStrictHandlerWithOptions(api, nil, openapi.StrictHTTPServerOptions{
		RequestErrorHandlerFunc:  badRequest,
		ResponseErrorHandlerFunc: internalError,
	})
	openapi.HandlerWithOptions(strict, openapi.StdHTTPServerOptions{BaseRouter: mux})
	isPublic := func(r *http.Request) bool { return r.Method == http.MethodGet && r.URL.Path == "/v1/health" }
	return jwtauth.Middleware(v, isPublic, mux)
}

// badRequest answers 400 VALIDATION_ERROR. It never echoes the input or the decoder error.
func badRequest(w http.ResponseWriter, r *http.Request, _ error) {
	writeError(w, r, http.StatusBadRequest, openapi.Error{Code: openapi.ErrorCodeVALIDATIONERROR, Message: "Request body is not valid."})
}

// internalError answers 500 INTERNAL_ERROR with a fixed message and logs the cause.
func internalError(w http.ResponseWriter, r *http.Request, err error) {
	slog.ErrorContext(r.Context(), "request failed", "error", err)
	writeError(w, r, http.StatusInternalServerError, openapi.Error{Code: openapi.ErrorCodeINTERNALERROR, Message: "Unexpected error."})
}

func writeError(w http.ResponseWriter, r *http.Request, status int, body openapi.Error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		slog.WarnContext(r.Context(), "write error body failed", "error", err)
	}
}
