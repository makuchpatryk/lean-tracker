// Package requestuser carries the authenticated user id through a request context, so a module's
// transport layer can read it without importing platform/ (ARCHITECTURE AD8).
package requestuser

import "context"

type contextKey struct{}

// WithUserID returns a context holding the authenticated user's id (the JWT sub).
func WithUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, contextKey{}, userID)
}

// UserID returns the authenticated user's id, or false when the request carries none.
func UserID(ctx context.Context) (string, bool) {
	userID, ok := ctx.Value(contextKey{}).(string)
	return userID, ok && userID != ""
}
