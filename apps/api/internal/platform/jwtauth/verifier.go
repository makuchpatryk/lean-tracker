// Package jwtauth verifies Supabase access tokens and guards HTTP routes with them (PRD §14, NFR-004).
package jwtauth

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"regexp"
	"time"

	"github.com/MicahParks/keyfunc/v3"
	"github.com/golang-jwt/jwt/v5"
)

// audience is the `aud` of Supabase access tokens (PRD §14).
const audience = "authenticated"

// jwksTimeout bounds the one fetch NewVerifier makes, so a hanging Auth host cannot stall startup.
const jwksTimeout = 5 * time.Second

// ErrInvalidToken is returned for every token that must be rejected.
var ErrInvalidToken = errors.New("jwtauth: invalid token")

var uuidPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

// Verifier checks access tokens against the project's JWKS.
type Verifier struct {
	keys   keyfunc.Keyfunc
	parser *jwt.Parser
}

// NewVerifier never fails because the JWKS is unreachable: a failed first fetch is logged, the key set is
// retried when a token with an unknown `kid` arrives and refreshed in the background. Local runs have no
// Auth server; every token is then rejected and /v1/health still works.
func NewVerifier(ctx context.Context, jwksURL string) (*Verifier, error) {
	keys, err := keyfunc.NewDefaultOverrideCtx(ctx, []string{jwksURL}, keyfunc.Override{
		HTTPTimeout: jwksTimeout,
		RefreshErrorHandlerFunc: func(string) func(context.Context, error) {
			return func(ctx context.Context, err error) {
				slog.WarnContext(ctx, "jwks refresh failed", "error", err)
			}
		},
	})
	if err != nil {
		return nil, fmt.Errorf("jwtauth: create key set: %w", err)
	}
	return &Verifier{
		keys: keys,
		parser: jwt.NewParser(
			jwt.WithValidMethods([]string{"ES256", "RS256"}),
			jwt.WithAudience(audience),
			jwt.WithExpirationRequired(),
		),
	}, nil
}

// Verify checks signature (ES256 or RS256 only), exp (required), aud, and that sub is a UUID. It returns sub.
func (v *Verifier) Verify(token string) (string, error) {
	claims := &jwt.RegisteredClaims{}
	if _, err := v.parser.ParseWithClaims(token, claims, v.keys.Keyfunc); err != nil {
		return "", fmt.Errorf("%w: %w", ErrInvalidToken, err)
	}
	if !uuidPattern.MatchString(claims.Subject) {
		return "", fmt.Errorf("%w: sub is not a UUID", ErrInvalidToken)
	}
	return claims.Subject, nil
}
