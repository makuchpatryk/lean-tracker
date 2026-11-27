// Package httpapi wires the generated OpenAPI server to its handlers and the JWT gate.
package httpapi

import (
	"context"
	"log/slog"
	"time"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
)

const pingTimeout = 2 * time.Second

// Pinger is what health needs from the database; *pgxpool.Pool satisfies it.
type Pinger interface {
	Ping(ctx context.Context) error
}

// HealthServer implements GET /v1/health.
type HealthServer struct{ db Pinger }

// NewHealthServer returns a HealthServer that pings db.
func NewHealthServer(db Pinger) *HealthServer { return &HealthServer{db: db} }

// GetHealth implements openapi.StrictServerInterface: 200 when the database answers a ping within 2 s,
// 503 otherwise. The ping error is logged without the DSN.
func (s *HealthServer) GetHealth(ctx context.Context, _ openapi.GetHealthRequestObject) (openapi.GetHealthResponseObject, error) {
	ctx, cancel := context.WithTimeout(ctx, pingTimeout)
	defer cancel()
	if err := s.db.Ping(ctx); err != nil {
		slog.WarnContext(ctx, "health: database ping failed", "error", err)
		return openapi.GetHealth503JSONResponse{Status: openapi.HealthStatusUnavailable}, nil
	}
	return openapi.GetHealth200JSONResponse{Status: openapi.HealthStatusOk}, nil
}
