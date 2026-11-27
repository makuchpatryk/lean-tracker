// Package settings is the public entry of the settings module: the daily goals of a user
// (GET and PUT /v1/settings, BR-003).
package settings

import (
	"example.com/lean-tracker/apps/api/internal/kernel/clock"
	"example.com/lean-tracker/apps/api/internal/settings/internal/application"
	"example.com/lean-tracker/apps/api/internal/settings/internal/infrastructure"
	"example.com/lean-tracker/apps/api/internal/settings/internal/transport"
)

// Handler implements the settings routes of the generated strict server.
type Handler = transport.Handler

// Querier is what the module needs from the database; *pgxpool.Pool satisfies it.
type Querier = infrastructure.Querier

// New builds the module from a database handle and a clock. The module builds its own Postgres
// adapter because Go's internal/ rule hides settings/internal/infrastructure from cmd/api, which stays
// the composition root by creating the pool and the clock and passing them in (ARCHITECTURE AD11).
func New(db Querier, clk clock.Clock) *Handler {
	repo := infrastructure.NewRepository(db)
	return transport.NewHandler(application.NewGetGoals(repo), application.NewSaveGoals(repo, clk))
}
