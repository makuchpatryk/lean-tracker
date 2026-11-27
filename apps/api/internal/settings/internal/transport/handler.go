// Package transport maps the generated OpenAPI settings routes to the settings use cases and maps
// domain errors to contract status and error codes (ARCHITECTURE AD5).
package transport

import (
	"context"
	"errors"
	"log/slog"

	"example.com/lean-tracker/apps/api/internal/gen/openapi"
	"example.com/lean-tracker/apps/api/internal/kernel/requestuser"
	"example.com/lean-tracker/apps/api/internal/settings/internal/application"
	"example.com/lean-tracker/apps/api/internal/settings/internal/domain"
)

// Handler implements GET and PUT /v1/settings of the generated strict server.
type Handler struct {
	get  *application.GetGoals
	save *application.SaveGoals
}

// NewHandler returns a Handler calling the given use cases.
func NewHandler(get *application.GetGoals, save *application.SaveGoals) *Handler {
	return &Handler{get: get, save: save}
}

// GetSettings returns the caller's goals: 200, 404 SETTINGS_NOT_FOUND when none are saved.
func (h *Handler) GetSettings(ctx context.Context, _ openapi.GetSettingsRequestObject) (openapi.GetSettingsResponseObject, error) {
	userID, ok := requestuser.UserID(ctx)
	if !ok {
		return openapi.GetSettings401JSONResponse{UnauthorizedJSONResponse: unauthorized()}, nil
	}
	goals, err := h.get.Execute(ctx, userID)
	switch {
	case err == nil:
		return openapi.GetSettings200JSONResponse(toSettings(goals)), nil
	case errors.Is(err, domain.ErrNotFound):
		return openapi.GetSettings404JSONResponse{Code: openapi.ErrorCodeSETTINGSNOTFOUND, Message: "Goals are not set yet."}, nil
	default:
		return openapi.GetSettings500JSONResponse{InternalErrorJSONResponse: internalError(ctx, err)}, nil
	}
}

// PutSettings validates and stores the caller's goals: 200 with the stored goals, 400 VALIDATION_ERROR
// for a value outside its range (BR-003).
func (h *Handler) PutSettings(ctx context.Context, request openapi.PutSettingsRequestObject) (openapi.PutSettingsResponseObject, error) {
	userID, ok := requestuser.UserID(ctx)
	if !ok {
		return openapi.PutSettings401JSONResponse{UnauthorizedJSONResponse: unauthorized()}, nil
	}
	if request.Body == nil {
		return openapi.PutSettings400JSONResponse{Code: openapi.ErrorCodeVALIDATIONERROR, Message: "Request body is not valid."}, nil
	}
	b := request.Body
	goals, err := h.save.Execute(ctx, userID, b.GoalKcal, b.GoalProteinG, b.GoalFatG, b.GoalCarbsG)
	var outOfRange *domain.OutOfRangeError
	switch {
	case err == nil:
		return openapi.PutSettings200JSONResponse(toSettings(goals)), nil
	case errors.As(err, &outOfRange):
		// The app maps the code to its own text; this message is for API clients and logs.
		return openapi.PutSettings400JSONResponse{Code: openapi.ErrorCodeVALIDATIONERROR, Message: outOfRange.Error() + "."}, nil
	default:
		return openapi.PutSettings500JSONResponse{InternalErrorJSONResponse: internalError(ctx, err)}, nil
	}
}

func toSettings(g domain.Goals) openapi.Settings {
	return openapi.Settings{GoalKcal: g.KCal, GoalProteinG: g.ProteinG, GoalFatG: g.FatG, GoalCarbsG: g.CarbsG}
}

// unauthorized is a defensive answer: the JWT middleware already rejects requests without a user.
func unauthorized() openapi.UnauthorizedJSONResponse {
	return openapi.UnauthorizedJSONResponse{Code: openapi.ErrorCodeUNAUTHORIZED, Message: "Sign in required."}
}

// internalError logs the cause (never the request body) and returns a fixed body that leaks nothing.
func internalError(ctx context.Context, err error) openapi.InternalErrorJSONResponse {
	slog.ErrorContext(ctx, "settings: request failed", "error", err)
	return openapi.InternalErrorJSONResponse{Code: openapi.ErrorCodeINTERNALERROR, Message: "Unexpected error."}
}
