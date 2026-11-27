package jwtauth_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"example.com/lean-tracker/apps/api/internal/kernel/requestuser"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth"
)

type fakeVerifier struct {
	validToken string
	called     bool
}

func (f *fakeVerifier) Verify(token string) (string, error) {
	f.called = true
	if token == f.validToken {
		return userID, nil
	}
	return "", jwtauth.ErrInvalidToken
}

func serve(t *testing.T, v *fakeVerifier, req *http.Request) (rec *httptest.ResponseRecorder, nextCalled bool, gotUser string) {
	t.Helper()
	isPublic := func(r *http.Request) bool { return r.Method == http.MethodGet && r.URL.Path == "/public" }
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		nextCalled = true
		gotUser, _ = requestuser.UserID(r.Context())
		w.WriteHeader(http.StatusNoContent)
	})
	rec = httptest.NewRecorder()
	jwtauth.Middleware(v, isPublic, next).ServeHTTP(rec, req)
	return rec, nextCalled, gotUser
}

func assertUnauthorized(t *testing.T, rec *httptest.ResponseRecorder, nextCalled bool) {
	t.Helper()
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("status = %d, want 401", rec.Code)
	}
	if got := rec.Header().Get("WWW-Authenticate"); got != "Bearer" {
		t.Errorf("WWW-Authenticate = %q, want Bearer", got)
	}
	var body struct{ Code, Message string }
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil || body.Code != "UNAUTHORIZED" || body.Message == "" {
		t.Errorf("body = %q (%v), want JSON with code UNAUTHORIZED and a message", rec.Body.String(), err)
	}
	if nextCalled {
		t.Error("next handler was called")
	}
}

func TestMiddlewarePublicRequestPassesWithoutHeader(t *testing.T) { // NFR-004: health check is public
	v := &fakeVerifier{}

	rec, nextCalled, _ := serve(t, v, httptest.NewRequest(http.MethodGet, "/public", nil))

	if rec.Code != http.StatusNoContent || !nextCalled || v.called {
		t.Fatalf("status %d, next called %v, verifier called %v; want 204, true, false", rec.Code, nextCalled, v.called)
	}
}

func TestMiddlewareRejectsRequestsWithoutAValidBearerToken(t *testing.T) { // NFR-004
	tests := []struct {
		name   string
		method string
		path   string
		header string
	}{
		{"no header", http.MethodGet, "/private", ""},
		{"basic scheme", http.MethodGet, "/private", "Basic dXNlcjpwYXNz"},
		{"bearer without token", http.MethodGet, "/private", "Bearer "},
		{"verifier rejects token", http.MethodGet, "/private", "Bearer bad"},
		{"same path other method is not public", http.MethodPost, "/public", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, tt.path, nil)
			if tt.header != "" {
				req.Header.Set("Authorization", tt.header)
			}

			rec, nextCalled, _ := serve(t, &fakeVerifier{validToken: "good"}, req)

			assertUnauthorized(t, rec, nextCalled)
		})
	}
}

func TestMiddlewareValidTokenCallsNextWithUserID(t *testing.T) { // PRD §14: user_id comes from sub
	req := httptest.NewRequest(http.MethodGet, "/private", nil)
	req.Header.Set("Authorization", "bearer good") // scheme is case-insensitive (RFC 7235)

	rec, nextCalled, gotUser := serve(t, &fakeVerifier{validToken: "good"}, req)

	if rec.Code != http.StatusNoContent || !nextCalled || gotUser != userID {
		t.Fatalf("status %d, next called %v, user %q; want 204, true, %q", rec.Code, nextCalled, gotUser, userID)
	}
}
