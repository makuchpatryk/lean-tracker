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
make up          # start local Postgres, Supabase Auth, the Auth gateway and Mailpit
make auth-keys   # create the local Auth signing key (also run by make up)
make db-reset    # drop local data, apply auth stub and migrations, restart the Auth stack
make run-api     # build and run the API in Docker (port 8080)
make lint        # contract check, Go lint, Dart format and analyze
make test        # Go and Flutter unit tests
make gen         # regenerate API clients and server code
make sync-contract   # copy apps/api/openapi.yaml to apps/mobile/openapi.yaml
```

`make check-contract` (run by `make lint`) fails if the mobile copy of the contract differs from the API's. After changing the contract, run `make sync-contract`, then `make gen`.

## Configuration

- API: copy `apps/api/.env.example` and `.env.example` (root, used by `compose.yaml`) and fill `SUPABASE_JWKS_URL`. Leaving it empty starts the API, which then rejects every token.
- Mobile: copy `apps/mobile/env/example.json` to `apps/mobile/env/local.json` (git-ignored) and fill `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `API_BASE_URL`; run with `flutter run --dart-define-from-file=env/local.json`. Nothing secret goes in the repo.

## Local sign-in stack

`make up` starts Postgres, Supabase Auth (GoTrue), an nginx gateway on `http://127.0.0.1:54321/auth/v1` and Mailpit.

- Confirmation and reset emails land in Mailpit: <http://127.0.0.1:8025>.
- On the Android emulator the host is `10.0.2.2`: `SUPABASE_URL=http://10.0.2.2:54321`, `API_BASE_URL=http://10.0.2.2:8080`. On the iOS simulator use `127.0.0.1`.
- The Supabase anon key for the local stack is any non-empty value; the local Auth does not check it.
- Run the API against it on the host with `SUPABASE_JWKS_URL=http://127.0.0.1:54321/auth/v1/.well-known/jwks.json`; in compose the default already points at the gateway.
- Keep the local Auth paired with the local database: a user from another Auth instance has no row in the local `auth.users`, so saving goals fails.
- Google and Apple sign-in work only against the hosted Supabase project.

## Docs

- [PRD](docs/PRD.md)
