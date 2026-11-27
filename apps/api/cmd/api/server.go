package main

import (
	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/platform/httpapi"
	"example.com/lean-tracker/apps/api/internal/settings"
)

// apiServer is the whole generated API: each embedded handler brings its own routes, and the method
// names do not collide.
type apiServer struct {
	*httpapi.HealthServer
	*settings.Handler
}

var _ openapi.StrictServerInterface = apiServer{}
