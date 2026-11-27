package jwtauth

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/kernel/requestuser"
)

// TokenVerifier checks an access token and returns the user id (the JWT sub).
type TokenVerifier interface {
	Verify(token string) (string, error)
}

// Middleware lets requests for which isPublic returns true through untouched; every other request needs
// "Authorization: Bearer <jwt>". Failure: 401, WWW-Authenticate: Bearer, JSON {"code":"UNAUTHORIZED","message":...}.
// Success: next runs with requestuser.WithUserID(ctx, sub). Tokens and headers are never logged.
func Middleware(v TokenVerifier, isPublic func(*http.Request) bool, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if isPublic(r) {
			next.ServeHTTP(w, r)
			return
		}
		token, ok := bearerToken(r)
		if !ok {
			unauthorized(w, r)
			return
		}
		userID, err := v.Verify(token)
		if err != nil {
			unauthorized(w, r)
			return
		}
		next.ServeHTTP(w, r.WithContext(requestuser.WithUserID(r.Context(), userID)))
	})
}

func bearerToken(r *http.Request) (string, bool) {
	scheme, token, found := strings.Cut(r.Header.Get("Authorization"), " ")
	token = strings.TrimSpace(token)
	if !found || !strings.EqualFold(scheme, "Bearer") || token == "" {
		return "", false
	}
	return token, true
}

func unauthorized(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("WWW-Authenticate", "Bearer")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	body := openapi.Error{Code: openapi.ErrorCodeUNAUTHORIZED, Message: "Sign in required."}
	if err := json.NewEncoder(w).Encode(body); err != nil {
		slog.WarnContext(r.Context(), "write 401 body failed", "error", err)
	}
}
