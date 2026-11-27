# Lean Tracker

Calorie and macro diary: track kcal, protein, fat and carbs against your daily limits. Flutter mobile app, Go API, Supabase Postgres.

## Layout

- `apps/mobile` — Flutter app (Android, iOS)
- `apps/api` — Go API, owns the OpenAPI contract (`apps/api/openapi.yaml`) and the SQL migrations (`apps/api/db/`)
- `docs/` — PRD, architecture, code quality rules

## Requirements

- Docker (every tool runs in a pinned image through the `Makefile`)
- `make`

## Common commands

```sh
make up          # start local Postgres
make db-reset    # drop local data, apply auth stub and migrations
make run-api     # build and run the API in Docker (port 8080)
make lint        # contract check, Go lint, Dart format and analyze
make test        # Go and Flutter unit tests
make gen         # regenerate API clients and server code
make sync-contract   # copy apps/api/openapi.yaml to apps/mobile/openapi.yaml
```

`make check-contract` (run by `make lint`) fails if the mobile copy of the contract differs from the API's. After changing the contract, run `make sync-contract`, then `make gen`.

## Configuration

- API: copy `apps/api/.env.example` and `.env.example` (root, used by `compose.yaml`) and fill `SUPABASE_JWKS_URL`. Leaving it empty starts the API, which then rejects every token.
- Mobile: secrets come from `--dart-define-from-file`, never from the repo.

## Docs

- [PRD](docs/PRD.md)
