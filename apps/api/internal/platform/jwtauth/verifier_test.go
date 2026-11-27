package jwtauth_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"example.com/lean-tracker/apps/api/internal/platform/jwtauth"
	"example.com/lean-tracker/apps/api/internal/platform/jwtauth/jwttest"
)

const userID = "0b6a1d3c-6c6e-4f0e-9d5e-6f6c5d8f3a11"

// claims returns valid Supabase access-token claims; mutate returns them changed for one rejection case.
func claims(mutate func(jwt.MapClaims)) jwt.MapClaims {
	c := jwt.MapClaims{
		"sub": userID,
		"aud": "authenticated",
		"exp": time.Now().Add(time.Hour).Unix(),
	}
	if mutate != nil {
		mutate(c)
	}
	return c
}

func newVerifier(t *testing.T, jwksURL string) *jwtauth.Verifier {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)
	v, err := jwtauth.NewVerifier(ctx, jwksURL)
	if err != nil {
		t.Fatalf("NewVerifier() error = %v", err)
	}
	return v
}

func TestVerifyAcceptsValidTokenAndReturnsSub(t *testing.T) { // PRD §14, NFR-004
	jwksURL, sign := jwttest.NewIssuer(t)

	got, err := newVerifier(t, jwksURL).Verify(sign(claims(nil)))

	if err != nil || got != userID {
		t.Fatalf("Verify() = %q, %v; want %q, nil", got, err, userID)
	}
}

func TestVerifyRejectsInvalidTokens(t *testing.T) { // NFR-004
	jwksURL, sign := jwttest.NewIssuer(t)
	_, otherIssuerSign := jwttest.NewIssuer(t) // same kid, different key

	unsigned := func() string {
		tok := jwt.NewWithClaims(jwt.SigningMethodNone, claims(nil))
		tok.Header["kid"] = jwttest.KeyID
		s, err := tok.SignedString(jwt.UnsafeAllowNoneSignatureType)
		if err != nil {
			t.Fatal(err)
		}
		return s
	}()
	hs256 := func() string {
		tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims(nil))
		tok.Header["kid"] = jwttest.KeyID
		s, err := tok.SignedString([]byte("shared-secret-shared-secret-1234"))
		if err != nil {
			t.Fatal(err)
		}
		return s
	}()

	tests := []struct {
		name  string
		token string
	}{
		{"expired", sign(claims(func(c jwt.MapClaims) { c["exp"] = time.Now().Add(-time.Minute).Unix() }))},
		{"missing exp", sign(claims(func(c jwt.MapClaims) { delete(c, "exp") }))},
		{"wrong audience", sign(claims(func(c jwt.MapClaims) { c["aud"] = "anon" }))},
		{"missing audience", sign(claims(func(c jwt.MapClaims) { delete(c, "aud") }))},
		{"signed by another key", otherIssuerSign(claims(nil))},
		{"alg none", unsigned},
		{"alg HS256", hs256},
		{"missing sub", sign(claims(func(c jwt.MapClaims) { delete(c, "sub") }))},
		{"sub is not a UUID", sign(claims(func(c jwt.MapClaims) { c["sub"] = "user-1" }))},
		{"malformed string", "not-a-jwt"},
		{"empty string", ""},
	}
	v := newVerifier(t, jwksURL)
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := v.Verify(tt.token)

			if !errors.Is(err, jwtauth.ErrInvalidToken) || got != "" {
				t.Fatalf("Verify() = %q, %v; want empty sub and ErrInvalidToken", got, err)
			}
		})
	}
}

func TestNewVerifierStartsWithUnreachableJWKS(t *testing.T) { // local runs have no Auth server
	_, sign := jwttest.NewIssuer(t)

	v := newVerifier(t, "http://127.0.0.1:9/auth/v1/.well-known/jwks.json")

	if _, err := v.Verify(sign(claims(nil))); !errors.Is(err, jwtauth.ErrInvalidToken) {
		t.Fatalf("Verify() error = %v; want ErrInvalidToken when no key can be fetched", err)
	}
}
