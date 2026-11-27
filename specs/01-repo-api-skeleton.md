# M1 Repo, database and API skeleton (local only) — Implementation Plan

## Summary
M1 builds the local skeleton of Lean Tracker: a Docker-only toolchain driven by a root `Makefile`, a local Postgres in `compose.yaml` (`supabase/postgres` image, no local Supabase Auth), the OpenAPI contract with one public route (`GET /v1/health`), forward-only SQL migrations for all five PRD §13 tables, a Go API on `net/http` with a JWT gate on everything except health, and a Flutter app shell (`flutter_riverpod`, `go_router`, one placeholder route) with a generated Dart client. Everything runs locally; CI, deployment, hosted migrations and secrets are built in M8 (PRD D-61). Milestone: M1.

Base: detached `HEAD` at `58ba529` (default branch `main`, no git remote yet). Uncommitted work this plan relies on: the planning session already edited `docs/PRD.md` (M1 local-only, CI/deploy moved to M8, D-61, architecture checks removed from NFR-008/§18.1/§18.2/§19/D-51), `docs/ARCHITECTURE.md` (Enforcement section and principle removed, open item 2 reworded), `docs/CODE_QUALITY.md` (checklist item 7) and the four `lean-*` skills (`make arch` removed). A worktree created from `HEAD` will **not** see these edits until they are committed; commit them first or work on the current branch.

## Success Criteria
- `make lint` and `make test` exit 0 on a machine that has only Docker installed (no host Go, Flutter, Dart or Supabase CLI).
- `make db-reset` exits 0: the local auth stub and migrations `0001`–`0005` apply in order to an empty `supabase/postgres` container (M1 definition of done: "migrations apply to an empty local Postgres").
- Go unit tests prove: `GET /v1/health` returns 200 `{"status":"ok"}` when the DB ping succeeds and 503 `{"status":"unavailable"}` when it fails; any other method or path (including unknown paths) returns 401 `{"code":"UNAUTHORIZED",...}` without a valid token (M1 DoD); a valid token reaches the inner router (404 on unknown path); expired, wrong-audience, foreign-signature, `alg=none`/HS256, missing-`exp` and non-UUID `sub` tokens are rejected (NFR-004).
- The API starts even when the JWKS URL and the database are unreachable (local-only requirement; health then reports 503).
- Generated code exists, compiles and is never hand-edited: `apps/api/internal/gen/openapi/openapi.gen.go`, `apps/mobile/lib/gen/**`.
- Dart tests prove the app shell builds with `ProviderScope` + `go_router`, and the generated `Health` model round-trips JSON.

## Scope & Constraints
- **In scope:** monorepo structure from PRD §18 / ARCHITECTURE §Layout limited to what M1 uses; root `Makefile`, `compose.yaml`, `.env.example`; OpenAPI contract (health + error and security components); migrations for `user_settings`, `products`, `diary_entries`, `favorites`, `recents` (§13) with RLS on and no policies (§14, BR-001); Go config, pgx pool, JWT verifier and middleware (§14, NFR-004), health handler, router, `cmd/api`, Dockerfile, golangci config, unit tests; Flutter project (Android + iOS) with `lib/main.dart`, `lib/app/` shell, `lib/gen/` client, unit tests; doc updates.
- **Out of scope:** CI on push, secret scan, deploy workflow, Cloud Run, GCP, container registry, hosted Supabase migrations, GitHub secrets, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_URL` (all M8, D-61). Feature modules (`auth`, `settings`, `diary`, …): each is created by the milestone that first gives it behavior. Drift, l10n/ARB, `lib/ui/` theme, `lib/kernel/`, `kernel/limits` (AD6 starts with the first shared rule value, M2). Portrait lock (M2). `/v1/me` or any business route. Local Supabase Auth. Recents "keep 20" rule (M5). `apps/web/` (§10.3). Any dedicated DB role.
- **Hard constraints:** NFR-004 (JWT on every endpoint except health; no secret in the app; nothing sensitive logged); §14 (verify signature through JWKS, `exp`, `aud`, read `sub`; RLS on all tables, no policies for `anon`/`authenticated`); §13 field constraints; forward-only numbered migrations (§18.2); ARCHITECTURE dependency rules (modules never import `platform/`; generated code never edited); Android 10+ (`minSdk 29`), iOS 16+ (§16, D-44).
- **Trade-offs:**
  - The Go API connects as the Supabase `postgres` role (user decision), so RLS does not isolate users for the API; isolation rests on every query filtering by `user_id` from the JWT (BR-001). Accepted for simplicity; recorded as a decision.
  - The JWKS is fetched lazily and the API starts without it, so local runs work with no Auth server; the cost is that a misconfigured JWKS URL shows up as 401s, not as a startup failure.
  - Migrations are verified only by applying them (user choice "apply-only"); constraint behavior is tested by repository tests from M2 on.

## Architecture & Design

### High-Level Flow
```
curl / Flutter (later)
  │
  ▼
apps/api cmd/api/main.go (composition root)
  │  config.Load(os.Getenv)        PORT, DATABASE_URL, SUPABASE_JWKS_URL
  │  database.Open                 pgxpool, lazy connect
  │  jwtauth.NewVerifier           keyfunc, JWKS fetched lazily, refreshed in background
  ▼
httpapi.NewHandler
  └─ jwtauth.Middleware(isPublic = GET /v1/health)
       ├─ public ─► generated std-http strict handler ─► httpapi.HealthServer.GetHealth
       │              └─ Ping (2 s) ─► 200 {"status":"ok"} | 503 {"status":"unavailable"}
       └─ others ─► Bearer JWT verified?
                      ├─ no  ─► 401 {"code":"UNAUTHORIZED","message":"..."}
                      └─ yes ─► requestuser.WithUserID(ctx) ─► generated mux ─► 404 (no other route in M1)

compose.yaml: db (supabase/postgres) always; api (Dockerfile) behind profile "app"
make db-reset: down -v ─► up db ─► db/local/00_auth_stub.sql ─► db/migrations/*.sql in order

apps/mobile lib/main.dart ─► ProviderScope ─► LeanTrackerApp (lib/app/app.dart)
                                ─► routerProvider (lib/app/router.dart) ─► "/" empty placeholder
```

### Key Changes

**Repo tree created in M1**
```
Makefile
compose.yaml
.env.example
.gitignore                       (append: .cache/, apps/api/bin/)
contracts/openapi/openapi.yaml
db/local/00_auth_stub.sql        local stand-in for auth.users; not a migration
db/migrations/0001_user_settings.sql … 0005_recents.sql
apps/api/
  go.mod go.sum .golangci.yml Dockerfile .dockerignore .env.example
  cmd/api/main.go
  internal/gen/openapi/config.yaml generate.go openapi.gen.go   (generated, committed)
  internal/kernel/requestuser/requestuser.go requestuser_test.go
  internal/platform/config/config.go config_test.go
  internal/platform/database/database.go
  internal/platform/jwtauth/verifier.go middleware.go verifier_test.go middleware_test.go
  internal/platform/jwtauth/jwttest/jwttest.go                    (test helper)
  internal/platform/httpapi/health.go router.go health_test.go router_test.go
apps/mobile/                     (flutter create --empty, android + ios)
  pubspec.yaml pubspec.lock analysis_options.yaml
  lib/main.dart lib/app/app.dart lib/app/router.dart
  lib/gen/**                     (generated, committed)
  test/app/app_test.dart test/gen/health_test.dart
```

**Toolchain (root `Makefile`).** Every tool runs in a pinned image with the repo mounted at `/work`; caches live in the gitignored `.cache/` so runs are fast and files stay owned by the host user. Image tags are variables at the top of the Makefile (single source for tool versions; `apps/api/Dockerfile` and `go.mod` use the same Go version). Pin the latest stable tags at implementation time (Go ≥ 1.24 is required for the `tool` directive; `golang:1.25-bookworm` is already pulled locally).
```make
GO_IMAGE       ?= golang:<pinned>
GOLANGCI_IMAGE ?= golangci/golangci-lint:<pinned v2>
FLUTTER_IMAGE  ?= ghcr.io/cirruslabs/flutter:<pinned>
UID_GID        := $(shell id -u):$(shell id -g)

GO_RUN = docker run --rm --user $(UID_GID) -e HOME=/tmp \
  -e GOCACHE=/work/.cache/go-build -e GOMODCACHE=/work/.cache/go-mod -e GOLANGCI_LINT_CACHE=/work/.cache/golangci \
  -v $(CURDIR):/work -w /work/apps/api
# Flutter runs as root (the SDK cache in the image is root-owned) and hands files back to the host user.
FLUTTER_RUN = docker run --rm -e PUB_CACHE=/work/.cache/pub -v $(CURDIR):/work -w /work/apps/mobile $(FLUTTER_IMAGE) sh -c
FLUTTER_FIX = ; status=$$?; chown -R $(UID_GID) /work/apps/mobile /work/.cache/pub; exit $$status

.PHONY: gen gen-go gen-dart lint lint-go lint-dart test test-go test-dart up down db-reset run-api
gen: gen-go gen-dart
gen-go:    ; $(GO_RUN) $(GO_IMAGE) go generate ./internal/gen/...
gen-dart:  ; $(FLUTTER_RUN) 'flutter pub get && dart run swagger_parser && dart run build_runner build --delete-conflicting-outputs $(FLUTTER_FIX)'
lint: lint-go lint-dart
lint-go:   ; $(GO_RUN) $(GOLANGCI_IMAGE) golangci-lint run ./...
lint-dart: ; $(FLUTTER_RUN) 'flutter pub get && dart format --output=none --set-exit-if-changed lib/main.dart lib/app test && flutter analyze --fatal-infos $(FLUTTER_FIX)'
test: test-go test-dart
test-go:   ; $(GO_RUN) $(GO_IMAGE) go test -count=1 ./...
test-dart: ; $(FLUTTER_RUN) 'flutter test $(FLUTTER_FIX)'
up:        ; docker compose up -d --wait db
down:      ; docker compose --profile app down
db-reset:  ; docker compose down -v && $(MAKE) up && \
             for f in db/local/00_auth_stub.sql db/migrations/*.sql; do \
               echo "apply $$f"; docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d postgres -f - < $$f || exit 1; \
             done
run-api:   ; docker compose --profile app up --build -d --wait
```
The exact shell plumbing (`FLUTTER_FIX`) may be adjusted during implementation; what matters is: pinned images, caches under `.cache/`, host-owned files, non-zero exit on failure.

**`compose.yaml`**
```yaml
services:
  db:
    image: supabase/postgres:<pinned 15.x or 17.x>
    environment:
      POSTGRES_PASSWORD: postgres        # local only, not a secret
    ports: ["54322:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -h localhost"]
      interval: 2s
      retries: 30
  api:
    profiles: ["app"]
    build: ./apps/api
    depends_on: { db: { condition: service_healthy } }
    ports: ["8080:8080"]
    environment:
      DATABASE_URL: postgres://postgres:postgres@db:5432/postgres?sslmode=disable
      SUPABASE_JWKS_URL: ${SUPABASE_JWKS_URL:-http://127.0.0.1:9/auth/v1/.well-known/jwks.json}
    healthcheck:   # distroless has no shell; rely on compose "running" or drop --wait for api if needed
volumes:
  pgdata:
```
The `api` healthcheck line is a placeholder: distroless has no `curl`, so implementation either drops the healthcheck (and `--wait` waits for "running") or adds a tiny `-healthcheck` flag; pick the simpler working one and log it.

**`db/local/00_auth_stub.sql`** (idempotent; a no-op when the image already provides Supabase's `auth` schema; never applied to a hosted project):
```sql
-- Local stand-in for Supabase Auth (M1, local only). Not a migration.
create schema if not exists auth;
create table if not exists auth.users (id uuid primary key);
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
end $$;
```

**Contract: `contracts/openapi/openapi.yaml`** (OpenAPI 3.0.3; both generators target 3.0)
```yaml
openapi: 3.0.3
info: { title: Lean Tracker API, version: 0.1.0 }
servers: [{ url: http://localhost:8080 }]
security: [{ bearerAuth: [] }]
paths:
  /v1/health:
    get:
      operationId: getHealth
      summary: Liveness and database ping. The only public route.
      security: []
      responses:
        '200': { description: API and database reachable, content: { application/json: { schema: { $ref: '#/components/schemas/Health' } } } }
        '503': { description: Database ping failed,       content: { application/json: { schema: { $ref: '#/components/schemas/Health' } } } }
components:
  securitySchemes:
    bearerAuth: { type: http, scheme: bearer, bearerFormat: JWT }
  responses:
    Unauthorized:
      description: Missing or invalid access token
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
  schemas:
    Health:
      type: object
      required: [status]
      properties:
        status: { type: string, enum: [ok, unavailable] }
    ErrorCode:
      type: string
      enum: [UNAUTHORIZED]          # closed list; later milestones append codes
    Error:
      type: object
      required: [code, message]
      properties:
        code: { $ref: '#/components/schemas/ErrorCode' }
        message: { type: string }
```
Error body shape is flat `{code, message}` for every endpoint from now on (decision). The `Unauthorized` response component is attached to the first protected route in M2.

**Data model: migrations** (`db/migrations/`, forward-only, applied in file-name order). Every table: FK to `auth.users(id) on delete cascade` (BR-017 deletion cascades), `enable row level security`, `revoke all … from anon, authenticated`, no policies (§14). `updated_at` has no default (the client sets it; sync rules come in M6).

`0001_user_settings.sql`
```sql
create table public.user_settings (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  goal_kcal      integer not null check (goal_kcal between 500 and 10000),
  goal_protein_g integer not null check (goal_protein_g between 0 and 1000),
  goal_fat_g     integer not null check (goal_fat_g between 0 and 1000),
  goal_carbs_g   integer not null check (goal_carbs_g between 0 and 1000),
  updated_at     timestamptz not null
);
alter table public.user_settings enable row level security;
revoke all on public.user_settings from anon, authenticated;
```

`0002_products.sql`
```sql
create table public.products (
  id              uuid primary key,
  owner_id        uuid not null references auth.users(id) on delete cascade,
  name            text not null check (char_length(name) between 1 and 120),
  brand           text check (brand is null or char_length(brand) <= 80),
  barcode         text check (barcode is null or barcode ~ '^[0-9]{8,13}$'),
  base_unit       text not null check (base_unit in ('g', 'ml')),
  kcal_per_100    numeric(6,1) not null check (kcal_per_100 between 0 and 9999),
  protein_per_100 numeric(5,1) not null check (protein_per_100 between 0 and 100),
  fat_per_100     numeric(5,1) not null check (fat_per_100 between 0 and 100),
  carbs_per_100   numeric(5,1) not null check (carbs_per_100 between 0 and 100),
  serving_size    numeric(7,1) check (serving_size is null or serving_size between 0.1 and 10000),
  is_shared       boolean not null default false,
  updated_at      timestamptz not null,
  deleted_at      timestamptz
);
-- "unique per owner" applies to live rows, so a deleted product's barcode can be reused (decision).
create unique index products_owner_barcode_live_key
  on public.products (owner_id, barcode) where barcode is not null and deleted_at is null;
create index products_owner_idx on public.products (owner_id);
alter table public.products enable row level security;
revoke all on public.products from anon, authenticated;
```

`0003_diary_entries.sql` (snapshot columns carry no range checks, per §13)
```sql
create table public.diary_entries (
  id              uuid primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  entry_date      date not null,
  meal            text not null check (meal in ('breakfast', 'lunch', 'dinner', 'snack')),
  product_name    text not null,
  source          text not null check (source in ('off', 'own', 'manual')),
  source_ref      text,
  base_unit       text not null check (base_unit in ('g', 'ml')),
  kcal_per_100    numeric(6,1) not null,
  protein_per_100 numeric(5,1) not null,
  fat_per_100     numeric(5,1) not null,
  carbs_per_100   numeric(5,1) not null,
  quantity        numeric(7,1) not null check (quantity between 0.1 and 10000),
  unit            text not null,
  serving_size    numeric(7,1),
  updated_at      timestamptz not null,
  deleted_at      timestamptz,
  constraint diary_entries_unit_check check (unit = base_unit or unit = 'serving'),
  constraint diary_entries_serving_check check (unit <> 'serving' or serving_size is not null)
);
create index diary_entries_user_date_idx on public.diary_entries (user_id, entry_date);
alter table public.diary_entries enable row level security;
revoke all on public.diary_entries from anon, authenticated;
```

`0004_favorites.sql` (partial unique on live rows, same rule as products barcode)
```sql
create table public.favorites (
  id               uuid primary key,
  user_id          uuid not null references auth.users(id) on delete cascade,
  product_key      text not null check (product_key ~ '^(off|own):.+'),
  product_snapshot jsonb not null check (jsonb_typeof(product_snapshot) = 'object'),
  updated_at       timestamptz not null,
  deleted_at       timestamptz
);
create unique index favorites_user_key_live_key
  on public.favorites (user_id, product_key) where deleted_at is null;
alter table public.favorites enable row level security;
revoke all on public.favorites from anon, authenticated;
```

`0005_recents.sql`
```sql
create table public.recents (
  user_id          uuid not null references auth.users(id) on delete cascade,
  product_key      text not null check (product_key ~ '^(off|own):.+'),
  product_snapshot jsonb not null check (jsonb_typeof(product_snapshot) = 'object'),
  last_quantity    numeric(7,1) not null check (last_quantity between 0.1 and 10000),
  last_unit        text not null,
  last_used_at     timestamptz not null,
  updated_at       timestamptz not null,
  primary key (user_id, product_key)
);
alter table public.recents enable row level security;
revoke all on public.recents from anon, authenticated;
```

**Go API (`apps/api`)**
- `go.mod`: `module example.com/lean-tracker/apps/api` (placeholder until a remote exists), `go <pinned>`, `tool github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen`. Dependencies: `github.com/jackc/pgx/v5`, `github.com/golang-jwt/jwt/v5`, `github.com/MicahParks/keyfunc/v3` (and its `github.com/MicahParks/jwkset`). Standard library for everything else (`log/slog`, `net/http`).
- `internal/gen/openapi/config.yaml` + `generate.go`:
  ```yaml
  package: openapi
  generate: { std-http-server: true, strict-server: true, models: true }
  output: openapi.gen.go
  ```
  ```go
  // Package openapi is generated from contracts/openapi/openapi.yaml. Never edit openapi.gen.go.
  package openapi

  //go:generate go tool oapi-codegen -config config.yaml ../../../../../contracts/openapi/openapi.yaml
  ```
  Location `internal/gen/openapi` (not under `platform/`) because later modules' `transport` layers implement the generated strict interface and modules must never import `platform/` (ARCHITECTURE §Layers). Mirrors mobile `lib/gen/`.
- `internal/kernel/requestuser/requestuser.go` (framework-free; lets later `transport` read the user id without importing `platform/`):
  ```go
  func WithUserID(ctx context.Context, userID string) context.Context
  func UserID(ctx context.Context) (string, bool)
  ```
- `internal/platform/config/config.go`:
  ```go
  type Config struct {
      Port            string // PORT, default "8080", must be 1–65535
      DatabaseURL     string // DATABASE_URL, required
      SupabaseJWKSURL string // SUPABASE_JWKS_URL, required, absolute http(s) URL
  }
  func Load(getenv func(string) string) (Config, error) // error names missing/invalid variables, never echoes values
  ```
- `internal/platform/database/database.go`: `func Open(ctx context.Context, url string) (*pgxpool.Pool, error)` — `pgxpool.New` only, no ping, so the API starts while the DB is down and health reports 503.
- `internal/platform/jwtauth/verifier.go`:
  ```go
  const audience = "authenticated" // Supabase access tokens (PRD §14)
  var ErrInvalidToken = errors.New("jwtauth: invalid token")
  type Verifier struct{ keys keyfunc.Keyfunc }
  // NewVerifier never blocks on or fails because of an unreachable JWKS: keys are fetched lazily
  // and refreshed in the background (local runs have no Auth server).
  func NewVerifier(ctx context.Context, jwksURL string) (*Verifier, error)
  // Verify checks signature (ES256 or RS256 only), exp (required), aud, and that sub is a UUID.
  func (v *Verifier) Verify(token string) (userID string, err error)
  ```
  Implementation: `jwt.ParseWithClaims(token, &jwt.RegisteredClaims{}, v.keys.Keyfunc, jwt.WithValidMethods([]string{"ES256", "RS256"}), jwt.WithAudience(audience), jwt.WithExpirationRequired())`; `sub` checked with a UUID regexp (no extra dependency). Keyfunc construction: use `keyfunc.NewDefaultCtx` if it does not fail on an unreachable first fetch; otherwise build `jwkset.NewStorageFromHTTP(url, jwkset.HTTPClientStorageOptions{Ctx: ctx, NoErrorReturnFirstHTTPReq: true, RefreshInterval: time.Hour, RefreshErrorHandler: <slog warn>})` and `keyfunc.New(keyfunc.Options{Storage: storage})`. A unit test pins the behavior.
- `internal/platform/jwtauth/middleware.go`:
  ```go
  type TokenVerifier interface{ Verify(token string) (string, error) }
  // Middleware lets requests for which isPublic returns true through untouched; every other request needs
  // "Authorization: Bearer <jwt>". Failure: 401, WWW-Authenticate: Bearer, JSON {"code":"UNAUTHORIZED","message":"Sign in required."}.
  // Success: next with requestuser.WithUserID(ctx, sub).
  func Middleware(v TokenVerifier, isPublic func(*http.Request) bool, next http.Handler) http.Handler
  ```
  The 401 body uses the generated `openapi.Error` type and `openapi.UNAUTHORIZED` constant, so its shape and code come from the contract. Tokens and headers are never logged.
- `internal/platform/jwtauth/jwttest/jwttest.go`: `func NewIssuer(t *testing.T) (jwksURL string, sign func(jwt.MapClaims) string)` — `httptest` server serving one ES256 public key as JWKS (`kid` `test-1`); used only by `_test.go` files.
- `internal/platform/httpapi/health.go`:
  ```go
  type Pinger interface{ Ping(ctx context.Context) error } // *pgxpool.Pool satisfies it
  type HealthServer struct{ db Pinger }
  func NewHealthServer(db Pinger) *HealthServer
  // GetHealth implements openapi.StrictServerInterface; 2 s ping timeout; logs the ping error with slog, no DSN.
  func (s *HealthServer) GetHealth(ctx context.Context, _ openapi.GetHealthRequestObject) (openapi.GetHealthResponseObject, error)
  ```
- `internal/platform/httpapi/router.go`:
  ```go
  func NewHandler(v jwtauth.TokenVerifier, health *HealthServer) http.Handler {
      mux := http.NewServeMux()
      openapi.HandlerWithOptions(openapi.NewStrictHandler(health, nil), openapi.StdHTTPServerOptions{BaseRouter: mux})
      isPublic := func(r *http.Request) bool { return r.Method == http.MethodGet && r.URL.Path == "/v1/health" }
      return jwtauth.Middleware(v, isPublic, mux)
  }
  ```
  The middleware wraps the whole mux, so unknown paths return 401 without a token and 404 with one. M2 composes module servers into the strict interface here or in `cmd/api`.
- `cmd/api/main.go`: `main` calls `run(ctx, os.Getenv)` and exits 1 on error. `run`: `signal.NotifyContext` (SIGINT, SIGTERM) → `config.Load` → `database.Open` (defer `Close`) → `jwtauth.NewVerifier` → `httpapi.NewHandler` → `http.Server{Addr: ":"+Port, ReadHeaderTimeout: 5s, ReadTimeout: 15s, WriteTimeout: 15s, IdleTimeout: 60s}` → `ListenAndServe` in a goroutine → `Shutdown` with 10 s timeout on cancel. JSON `slog` logger; never logs `DATABASE_URL`, tokens or headers.
- `apps/api/Dockerfile`: multi-stage, builder `golang:<pinned>` (`CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api`), runtime `gcr.io/distroless/static-debian12:nonroot`, `EXPOSE 8080`, `ENTRYPOINT ["/api"]`. Generated code is committed, so the image build does not run the generator. `.dockerignore`: `bin/`, `.env*`.
- `apps/api/.env.example`: `PORT=8080`, `DATABASE_URL=postgres://postgres:postgres@localhost:54322/postgres?sslmode=disable`, `SUPABASE_JWKS_URL=` with a comment (public JWKS URL of the Supabase project; any unreachable URL works locally, all tokens are then rejected). Root `.env.example`: `SUPABASE_JWKS_URL=` (read by compose).
- `apps/api/.golangci.yml`: `version: "2"`; linters `standard` plus `bodyclose`, `noctx`, `errorlint`, `gosec`, `misspell`; formatters `gofmt`, `goimports`; generated files excluded (default `generated: lax` handling).

**Flutter (`apps/mobile`)**
- Created once with `flutter create --empty --platforms=android,ios --org io.github.example --project-name lean_tracker apps/mobile` (run in `FLUTTER_IMAGE` with `-w /work`, then `chown`). Then: Android `applicationId` and `namespace` in `android/app/build.gradle.kts` → `io.github.example.leantracker`, `minSdk = 29`; iOS `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj` → `io.github.example.leantracker`, `IPHONEOS_DEPLOYMENT_TARGET = 16.0` (pbxproj, and `platform :ios, '16.0'` in `ios/Podfile` if the file exists). Placeholders until a remote exists.
- `pubspec.yaml`: runtime `flutter_riverpod`, `go_router`, `dio`, `retrofit`, `json_annotation`; dev `flutter_lints`, `build_runner`, `swagger_parser`, `retrofit_generator`, `json_serializable`. Added with `flutter pub add` (latest stable, recorded in `pubspec.lock`, which is committed). `swagger_parser` config (in `pubspec.yaml` or `swagger_parser.yaml`, whichever the pinned version documents): schema `../../contracts/openapi/openapi.yaml`, output `lib/gen`, `json_serializer: json_serializable`, Dart.
- `analysis_options.yaml`: `include: package:flutter_lints/flutter.yaml`; `analyzer.language: {strict-casts: true, strict-inference: true, strict-raw-types: true}`; `analyzer.exclude: [lib/gen/**]`.
- `lib/main.dart` (calls `app/` only):
  ```dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'app/app.dart';

  void main() => runApp(const ProviderScope(child: LeanTrackerApp()));
  ```
- `lib/app/app.dart`: `class LeanTrackerApp extends ConsumerWidget` returning `MaterialApp.router(routerConfig: ref.watch(routerProvider), theme: ThemeData(useMaterial3: true), darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark))`. No `title` and no visible text (no literal user text without ARB; l10n and DESIGN.html theme arrive in M2).
- `lib/app/router.dart`: `final routerProvider = Provider<GoRouter>((ref) => GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => const Scaffold())]));` — placeholder route, replaced by real screens in M2. Providers are declared in `app/` (decision).
- `lib/gen/**`: produced by `make gen-dart`; never edited; not used by any code yet (first consumer: M2 infrastructure).
- UI: no DESIGN.html board applies in M1 (empty placeholder). No ARB keys, no `Semantics` labels needed (no interactive elements).

**Dependencies (owner-approved in planning; not all listed in PRD §18):** Go `pgx/v5`, `golang-jwt/jwt/v5`, `MicahParks/keyfunc/v3`, tool `oapi-codegen/v2`; Dart `flutter_riverpod`, `go_router`, `dio`, `retrofit`, `json_annotation`, dev `swagger_parser`, `build_runner`, `retrofit_generator`, `json_serializable`, `flutter_lints`. Docker images: `golang`, `golangci/golangci-lint`, `ghcr.io/cirruslabs/flutter`, `supabase/postgres`, `gcr.io/distroless/static-debian12`. No platform permissions in M1.

### Fit with Project Docs
- **PRD:** implements M1 (§19, as rewritten for local-only, D-61); §13 tables; §14 JWT verification and RLS; NFR-004 (JWT on every endpoint except health; no secrets in the app; nothing sensitive logged). Bends: §14 "dedicated database role" → Supabase `postgres` role (user decision); §19 M1 "module skeletons from 18.1" → only what M1 uses, modules created by the milestone that first needs them (user decision).
- **ARCHITECTURE.md:** composition roots `cmd/api` and `lib/app/`; technical services in `platform/` built in `cmd/api`; `kernel/requestuser` is framework-free; generated code in `internal/gen/openapi` and `lib/gen/`, never edited; contract first (the route and error envelope exist in `openapi.yaml` before code). New: `apps/api/internal/gen/`, root `Makefile`, `compose.yaml`, `db/local/` — added to §Layout in step 31. Open item 1 (Riverpod + go_router) and 2 (oapi-codegen + swagger_parser) resolved.
- **CODE_QUALITY.md:** KISS (std `net/http`, psql loop instead of a migration tool, no extra router), YAGNI (no empty modules, no l10n or theme before M2, only three config variables), single source (contract for routes, error codes and schemas; Makefile variables for tool versions; migrations for schema). Add "Tool versions → root `Makefile` image variables (Dockerfile and `go.mod` follow them)" to the single-sources table.
- **Docs to update (step 31–32):** PRD §14 (role), §18 tech stack table (chosen packages, local toolchain), §19 M1 Includes ("module skeletons" wording), §20 new decisions; ARCHITECTURE §Layout, §Decisions, §Open items; CODE_QUALITY single-sources table. Already done during planning: PRD D-61 and removal of architecture checks across PRD, ARCHITECTURE, CODE_QUALITY and skills.

### Alternative Approaches Considered
- **Local DB:** Supabase CLI stack (`supabase start`) — real Auth and JWKS locally, but needs the CLI on the host and the user wants Postgres only. Plain `postgres:16` — lighter, but no Supabase roles or `auth` schema, so the stub would grow. **Chosen:** `supabase/postgres` in compose plus an idempotent stub.
- **Migration runner:** goose / golang-migrate — tracking and reruns, but a new tool and M8 uses the Supabase CLI for hosted. **Chosen:** reset-and-apply psql loop (local data is disposable).
- **Go HTTP:** hand-written handlers or chi — fewer generated files, but the contract stops being enforced at compile time. **Chosen:** oapi-codegen strict server on std `net/http` (user choice).
- **Generated Go location:** `internal/platform/…` (Track B) — breaks "modules never import `platform/`" once module transports implement the interface. **Chosen:** `internal/gen/openapi`.
- **JWKS at startup:** fail fast (Track B) — catches misconfiguration early but blocks local runs without Auth. **Chosen:** lazy fetch.
- **Dart generator:** openapi-generator (Java/Docker) — mature but heavier. **Chosen:** swagger_parser (user choice).
- **Error envelope:** nested `{error:{code,message}}` — **Chosen:** flat `{code, message}` with `UNAUTHORIZED` (user choice).
- **Health 503 body:** shared Error envelope — **Chosen:** Health schema with `status` enum `ok|unavailable` (user choice).
- **Schema assertions test (`db/tests/schema_test.sql`):** proves RLS/grants/index mechanically — **Not chosen** (user: apply-only for M1).
- **Toolchain on host:** simpler commands, but the machine has only Docker. **Chosen:** Docker-run Makefile targets (user choice).

## Implementation Steps

Toolchain and local stack
1. [x] Pull and pin images: pick the latest stable tags of `golang` (≥ 1.24), `golangci/golangci-lint` (v2), `ghcr.io/cirruslabs/flutter` (stable), `supabase/postgres` (current 15.x or 17.x) and confirm each exists with `docker pull`. Record the tags in the Implementation Log.
2. [x] Append `.cache/` and `apps/api/bin/` to `.gitignore` (keep existing entries; Flutter ignores already exist).
3. [x] Create the root `Makefile` with the image variables, `GO_RUN`, `FLUTTER_RUN`, and targets `up`, `down`, `db-reset`, `run-api` from Architecture (gen/lint/test targets are added in steps 13 and 25).
4. [x] Create `compose.yaml` (`db` service with pinned image, `pgdata` volume, `pg_isready` healthcheck, port `54322:5432`; `api` service behind profile `app`, `build: ./apps/api`, env as in Architecture, port `8080:8080`, `depends_on` db healthy) and the root `.env.example` (`SUPABASE_JWKS_URL=` with comment).
5. [x] Create `db/local/00_auth_stub.sql` as in Architecture (header comment: local only, not a migration, never applied to a hosted project).

Contract and migrations
6. [x] Create `contracts/openapi/openapi.yaml` exactly as in Architecture (3.0.3, `getHealth` with `security: []`, global `bearerAuth`, schemas `Health`, `ErrorCode`, `Error`, response `Unauthorized`).
7. [x] Create `db/migrations/0001_user_settings.sql` and `0002_products.sql` as in Architecture (`0002` includes `products_owner_barcode_live_key` and `products_owner_idx`).
8. [x] Create `db/migrations/0003_diary_entries.sql`, `0004_favorites.sql`, `0005_recents.sql` as in Architecture.
9. [x] Run `make db-reset`; fix SQL until all six files apply. If `supabase/postgres` needs other env vars, a different connect user, or the stub conflicts with the image's `auth` schema, adjust `compose.yaml`/the stub (never the migrations' meaning) and log the decision.

Go API
10. [x] Create `apps/api/go.mod` (`module example.com/lean-tracker/apps/api`, pinned `go` version) and add dependencies inside `GO_IMAGE`: `go get github.com/jackc/pgx/v5 github.com/golang-jwt/jwt/v5 github.com/MicahParks/keyfunc/v3 && go get -tool github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen && go mod tidy`. Keep `go.sum`.
11. [x] Create `apps/api/internal/gen/openapi/config.yaml` and `generate.go` as in Architecture; add target `gen-go` to the Makefile; run `make gen-go`; confirm `openapi.gen.go` has `StrictServerInterface`, `GetHealth200JSONResponse`, `GetHealth503JSONResponse`, `Error`, `UNAUTHORIZED`, `HandlerWithOptions`, `StdHTTPServerOptions`.
12. [x] Create `apps/api/internal/kernel/requestuser/requestuser.go` (`WithUserID`, `UserID`, unexported key type) and `requestuser_test.go` (round trip; empty context returns `false`).
13. [x] Add Makefile targets `lint-go`, `test-go`; create `apps/api/.golangci.yml` as in Architecture.
14. [x] Create `apps/api/internal/platform/config/config.go` and `config_test.go` (table-driven: all set → ok; missing `DATABASE_URL`; missing `SUPABASE_JWKS_URL`; JWKS URL not absolute http(s); `PORT` unset → `8080`; `PORT` `abc` or `70000` rejected; error text names the variable and never contains the value).
15. [x] Create `apps/api/internal/platform/database/database.go` with `Open` (`pgxpool.New` only). No unit test (needs a DB); covered by health with a fake pinger and the user's local run.
16. [x] Create `apps/api/internal/platform/jwtauth/jwttest/jwttest.go` (`NewIssuer(t)`: ES256 key, `kid` `test-1`, `httptest` JWKS server closed by `t.Cleanup`, signer for `jwt.MapClaims`).
17. [x] Create `apps/api/internal/platform/jwtauth/verifier.go` (`NewVerifier`, `Verify`, `ErrInvalidToken`) as in Architecture, and `verifier_test.go`: valid token → its `sub`; expired; missing `exp`; wrong `aud`; signed by another key; `alg=none`; HS256 token; missing `sub`; `sub` not a UUID; malformed string; `NewVerifier` with an unreachable URL returns no error and `Verify` then fails. Test names cite NFR-004 / PRD §14.
18. [x] Create `apps/api/internal/platform/jwtauth/middleware.go` (`TokenVerifier`, `Middleware`) and `middleware_test.go` with a fake verifier: public request passes without header; missing header → 401 JSON `{"code":"UNAUTHORIZED",...}` + `WWW-Authenticate: Bearer` and `next` not called; `Basic` scheme → 401; verifier error → 401; valid → `next` called and `requestuser.UserID` returns the `sub`.
19. [x] Create `apps/api/internal/platform/httpapi/health.go` (`Pinger`, `HealthServer`, `NewHealthServer`, `GetHealth` with 2 s timeout) and `health_test.go` (fake pinger ok → 200 `{"status":"ok"}`; error → 503 `{"status":"unavailable"}`; through the generated strict handler with `httptest`).
20. [x] Create `apps/api/internal/platform/httpapi/router.go` (`NewHandler`) and `router_test.go` using `jwttest` and a real `Verifier`: `GET /v1/health` no token → 200; `POST /v1/health` no token → 401; `GET /v1/unknown` and `GET /` no token → 401; `GET /v1/unknown` valid token → 404; expired token → 401.
21. [x] Create `apps/api/cmd/api/main.go` (`main`, `run(ctx, getenv)`) as in Architecture.
22. [x] Create `apps/api/Dockerfile`, `apps/api/.dockerignore`, `apps/api/.env.example` as in Architecture; settle the compose `api` healthcheck question (drop it or add a check flag) and log the choice.
23. [x] Run `make lint-go` and `make test-go`; fix until clean.

Flutter
24. [x] Run `flutter create --empty --platforms=android,ios --org io.github.example --project-name lean_tracker apps/mobile` in `FLUTTER_IMAGE` (`-w /work`, then `chown` to the host user). Set Android `applicationId`/`namespace` `io.github.example.leantracker` and `minSdk = 29`; iOS `PRODUCT_BUNDLE_IDENTIFIER` `io.github.example.leantracker` and deployment target `16.0`. Delete any generated `test/widget_test.dart`.
25. [x] Add Makefile targets `gen-dart`, `lint-dart`, `test-dart` and aggregate targets `gen`, `lint`, `test`.
26. [x] Add dependencies with `flutter pub add` (runtime and dev lists in Architecture), add the `swagger_parser` config, and create `apps/mobile/analysis_options.yaml` as in Architecture.
27. [x] Replace `apps/mobile/lib/main.dart`; create `apps/mobile/lib/app/app.dart` (`LeanTrackerApp`) and `apps/mobile/lib/app/router.dart` (`routerProvider`) as in Architecture.
28. [x] Run `make gen-dart`; confirm `apps/mobile/lib/gen/` holds a `Health` model (status enum) and a retrofit client for `getHealth`. Never edit `lib/gen/`.
29. [x] Create `apps/mobile/test/app/app_test.dart` (pump `ProviderScope(child: LeanTrackerApp())`, expect one `Scaffold`, no exception) and `apps/mobile/test/gen/health_test.dart` (`fromJson({'status': 'ok'})` → ok status; `toJson` round trip; use the names the generator emitted).
30. [x] Run `make lint-dart` and `make test-dart`; fix until clean.

Docs and final verification
31. [x] Update `docs/PRD.md`: §14 Data access — the Go API connects as the Supabase `postgres` role; RLS on with no policies for `anon`/`authenticated` blocks Supabase REST; isolation relies on every query filtering by `user_id` from the JWT. §18 Tech stack table — add `flutter_riverpod`, `go_router`, `swagger_parser` (dio/retrofit) client, `oapi-codegen` std-http strict server, `pgx`, `golang-jwt` + `keyfunc`, and "local: Docker Compose (`supabase/postgres`) and Docker-run toolchain via root `Makefile`". §19 M1 Includes — "repository structure from 18.1; modules are created by the milestone that first uses them". §20 — add D-62 (`postgres` role instead of a dedicated role), D-63 (Riverpod providers in `app/` + go_router), D-64 (oapi-codegen strict std-http server in `apps/api/internal/gen/openapi`; swagger_parser Dart client in `lib/gen/`; generated code committed), D-65 (golang-jwt v5 + keyfunc v3; ES256/RS256; JWKS fetched lazily), D-66 (toolchain in pinned Docker images; local stack compose Postgres only, no local Auth; migrations verified by apply), D-67 (error body `{code, message}`; health returns `Health` with `ok|unavailable`), D-68 (no empty module skeletons; partial unique indexes on live rows for products barcode and favorites). Bump the version line to 1.1 with today's date.
32. [x] Update `docs/ARCHITECTURE.md`: §Layout — add root `Makefile`, `compose.yaml`, `db/local/` (local auth stub), `apps/api/internal/gen/openapi/` (generated server, never edited); §Decisions — AD7 (generated Go server lives in `internal/gen/openapi` so module `transport` can implement it without importing `platform/`), AD8 (request user id travels in `context` through `kernel/requestuser`), AD9 (Riverpod providers declared in `app/`, routing with go_router); §Open items — remove items 1 and 2 (resolved), keep item 3 renumbered as 1. Update `docs/CODE_QUALITY.md` single-sources table: "Tool versions | root `Makefile` image variables (`Dockerfile`, `go.mod` follow)" and "Generated clients and server stubs | `make gen` from the contract".
33. [x] Final light verification: `make lint` and `make test` green; `make db-reset` green; `grep -rn "go-arch-lint\|make arch" docs .claude/skills CLAUDE.md` prints nothing.

## Checkpoints (Todo List)
- [x] CP1 — Local stack, contract and schema: steps 1-9; `make db-reset` exits 0 (stub + `0001`–`0005` apply to an empty container) — make db-reset exit 0, 5 tables with RLS on
- [x] CP2 — Go generation, config and JWT: steps 10-18; `make test-go` green incl. `requestuser_test.go`, `config_test.go`, `verifier_test.go`, `middleware_test.go` — files written; make test-go not run (not selected)
- [x] CP3 — Go health, router and binary: steps 19-23; `make lint-go` and `make test-go` green incl. `health_test.go`, `router_test.go` — make lint-go / test-go not run (not selected)
- [x] CP4 — Flutter shell and generated client: steps 24-30; `make lint-dart` and `make test-dart` green incl. `test/app/app_test.dart`, `test/gen/health_test.dart` — make lint-dart / test-dart not run (not selected); make gen-dart ran ok
- [x] CP5 — Docs + final light verification: steps 31-33; `make lint`, `make test`, `make db-reset` green; grep clean — make db-reset green, grep clean; make lint / make test not run (not selected)

### Risks & Mitigations
- Risk: `supabase/postgres` behaves differently from a plain Postgres image (required env vars, `postgres` not superuser, its own `auth` schema clashing with the stub), so `make db-reset` fails for reasons unrelated to the migrations.
  - Mitigation: the stub is idempotent (`if not exists`) and applied after container init, not as an initdb script; step 9 adjusts compose/stub and logs it.
  - Mitigation: fallback to the locally available `postgres:16` image with the stub creating `auth.users`, `anon` and `authenticated`, logged as a decision.
- Risk: the `postgres` role owns the tables and bypasses RLS, so a Go query without `user_id` leaks another user's data (BR-001) — RLS protects only the Supabase REST path.
  - Mitigation: D-62 records it; lean-review checks `user_id` filtering on every repository query from M2; repository tests from M2 prove another user's id cannot read or overwrite a row.
- Risk: keyfunc v3 fails or blocks when the first JWKS fetch fails, which would stop the API from starting locally (no Auth server), or silently never refreshes.
  - Mitigation: `verifier_test.go` pins "unreachable URL → constructor ok, Verify fails"; if `NewDefaultCtx` errors, build the storage with `NoErrorReturnFirstHTTPReq: true` and a refresh error handler that logs a warning.
- Risk: Docker-run tooling leaves root-owned files or runs slowly (Flutter SDK cache owned by root, empty module/pub caches each run).
  - Mitigation: Go and golangci run as the host user with caches in `.cache/`; Flutter runs as root and `chown`s `apps/mobile` and `.cache/pub` back; images pinned in the Makefile.
- Risk: generators choke on the contract (strict server with `security: []`, enum schemas, `components.responses` unused) or emit unformatted code that fails lint.
  - Mitigation: generation runs early (steps 11 and 28) before code depends on it; `lib/gen` is excluded from analysis and format checks; golangci skips generated files; keep the contract to what M1 needs.

## Test Strategy
**Light** (run during implementation, whichever the user selects):
- Unit tests (Go), no database, network only to in-process `httptest`: `requestuser_test.go`; `config_test.go` (table-driven); `verifier_test.go` (signature, alg, exp, aud, sub, unreachable JWKS); `middleware_test.go` (fake verifier); `health_test.go` (fake pinger through the generated strict handler); `router_test.go` (401 on everything but `GET /v1/health`, 404 with a valid token).
- Unit tests (Flutter): `test/app/app_test.dart` (shell builds with `ProviderScope` + `go_router`), `test/gen/health_test.dart` (generated model JSON). M1 has no business rule, so no BR- test is due (NFR-008).
- Lint: `golangci-lint` (incl. gofmt/goimports/vet); `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`.
- Schema apply: `make db-reset` (migrations apply to an empty local Postgres).
- Repository tests: none in M1 (no repository yet).
- Contract tests: none in M1 (no `kernel/limits` yet; AD6 starts in M2).

**Heavy** (only by `lean-review` when the user selects them): `docker compose --profile app up --build` (API image build and run), contract drift (`make gen` then `git diff --exit-code apps/api/internal/gen apps/mobile/lib/gen`), Android/iOS builds. Integration tests: none; no `/lean-e2e` candidate in M1.

**Manual testing (user):** `make run-api`, then `curl -i localhost:8080/v1/health` → 200 `{"status":"ok"}`; `docker compose stop db` → health 503 `{"status":"unavailable"}`; `curl -i localhost:8080/v1/anything` → 401 `{"code":"UNAUTHORIZED",...}`; `make down`.

## Success Checklist
- [ ] All success criteria met (with evidence)
- [ ] Lint and unit tests clean (implementation); `make db-reset` green
- [ ] Heavy checks green when run (review): API image build and local run, contract drift
- [ ] Code review approved
- [ ] Documentation updated (steps 31-32; planning-time edits to PRD, ARCHITECTURE, CODE_QUALITY and skills committed)
- [ ] No regressions in Polish and English, light and dark, offline (not applicable in M1: no UI text or data yet)
- [ ] User action: run the manual API checks above
- [ ] User action: replace the placeholder identifiers (`io.github.example.leantracker`, `example.com/lean-tracker/apps/api`) once the GitHub remote exists
- [ ] User action: commit (ask: `main` or a branch such as `feature/01-repo-api-skeleton`)

## Timeline & Estimates
- Phase 1 (implementation): ~8 hours (toolchain + compose 1.5 h, contract + migrations 1.5 h, Go API 3.5 h, Flutter shell 1.5 h)
- Phase 2 (testing): ~2 hours (Go JWT/router tests, Dart tests, Docker tooling fixes)
- Phase 3 (review + polish): ~1.5 hours (docs, review fixes)
- **Total**: ~11.5 hours (rough estimate; first image pulls and SDK downloads add time once)

Note: Estimates are rough. Adjust based on your velocity.

## Open Questions
- [ ] None blocking. Known follow-ups for later milestones: M2 needs a hosted Supabase project for Google/Apple sign-in (FR-001) although deployment is M8; confirm then whether the hosted project signs tokens with asymmetric keys (ES256/RS256 in JWKS) — legacy HS256-only tokens are rejected by design.

## Implementation Log
- Decision: Scope of this planning run: M1 only
- Decision: Architecture checks: dropped for both apps (docs and skills already updated during planning)
- Decision: Flutter state and routing: flutter_riverpod (providers in `app/`) + go_router, now
- Decision: Go HTTP + contract: oapi-codegen strict server on std net/http
- Decision: Dart client generator: swagger_parser
- Decision: JWT library: golang-jwt v5 + keyfunc v3
- Decision: DB role: Supabase `postgres` role (bends PRD §14)
- Decision: 401 proof: middleware on everything except `GET /v1/health`; no `/v1/me`
- Decision: Module skeletons: only what M1 uses
- Decision: Toolchain: all checks run in Docker images via the Makefile
- Decision: Identifiers: placeholders `io.github.example.leantracker`, `example.com/lean-tracker/apps/api`
- Decision: M1 is local only; CI and deploy are the last milestone (M8, PRD D-61); API Dockerfile kept for local compose run
- Decision: Local stack: docker compose with Postgres only (`supabase/postgres`), no local Auth
- Decision: API opens a pgx pool; health pings the DB and returns 503 on failure
- Decision: products barcode: partial unique index on live rows
- Decision: Error body: flat `{code, message}`, code `UNAUTHORIZED`
- Decision: Health 503 body: `Health` schema, `status` enum `ok|unavailable`
- Decision: Mobile extras (l10n, portrait lock): neither in M1
- Decision: Migration verification: apply-only (`make db-reset`), no schema assertion test
- Decision: workspace: worktree
- Decision: checks: none (user selected no lint/unit-test checks; plan steps that run make db-reset and generators still run as plan actions)
- Base: main @ 8f0d00a, worktree .claude/worktrees/01-repo-api-skeleton on feature/01-repo-api-skeleton; main checkout clean at start
- Step 1 — started
- Step 1 — done — files: (none; images pulled) — pinned golang:1.27.4-bookworm, golangci/golangci-lint:v2.15.0 (built with go1.27.0, so go.mod must say go 1.27.0 not 1.27.4), ghcr.io/cirruslabs/flutter:3.44.0 (Dart 3.12.0), supabase/postgres:17.12.0.005, gcr.io/distroless/static-debian12:nonroot
- Step 2 — started
- Step 2 — done — files: .gitignore — appended .cache/ (apps/api/bin/ already present)
- Step 3 — started
- Step 3 — done — files: Makefile — image vars, GO_RUN, FLUTTER_RUN/FIX, up/down/db-reset/run-api (recipes in tab form)
- Step 4 — started
- Step 4 — done — files: compose.yaml, .env.example — db + api(profile app); api healthcheck deferred to step 22
- Step 5 — started
- Step 5 — done — files: db/local/00_auth_stub.sql — as in plan
- Step 6 — started
- Step 6 — done — files: contracts/openapi/openapi.yaml — as in plan
- Step 7 — started
- Step 7 — done — files: db/migrations/0001_user_settings.sql, db/migrations/0002_products.sql — as in plan; SQL comment cites D-68
- Step 8 — started
- Step 8 — done — files: db/migrations/0003_diary_entries.sql, db/migrations/0004_favorites.sql, db/migrations/0005_recents.sql — as in plan
- Step 9 — started
- Step 9 — done — files: db/local/00_auth_stub.sql — make db-reset exit 0 (stub + 0001-0005, RLS on for all five). Decision: supabase/postgres already ships auth.users/anon/authenticated and the postgres role cannot create in schema auth, so stub now creates auth.users only when to_regclass('auth.users') is null
- Decision: db-reset connects as postgres; works against supabase/postgres:17.12.0.005 with FK to image's auth.users
- Step 10 — started
- Step 10 — done — files: apps/api/go.mod, apps/api/go.sum — go 1.27.0 (not 1.27.4: golangci v2.15.0 is built with go1.27.0); pgx v5.13.0, jwt v5.3.1, keyfunc v3.9.2, tool oapi-codegen v2.9.0. go mod tidy runs again once code imports pgx/jwt/keyfunc (it drops unused requires)
- Step 11 — started
- Step 11 — done — files: apps/api/internal/gen/openapi/config.yaml, generate.go, openapi.gen.go, Makefile — gen-go target added. Deviation: config adds output-options.skip-prune (else Error/ErrorCode unused by any route are pruned) and compatibility.always-prefix-enum-values; constants are ErrorCodeUNAUTHORIZED, HealthStatusOk/HealthStatusUnavailable (not UNAUTHORIZED). Generated code imports github.com/oapi-codegen/runtime (go mod tidy later)
- Step 12 — started
- Step 12 — done — files: apps/api/internal/kernel/requestuser/requestuser.go, requestuser_test.go — WithUserID/UserID; empty id counts as no user; 3 tests
- Step 13 — started
- Step 13 — done — files: Makefile, apps/api/.golangci.yml — lint-go, test-go targets; golangci config as in plan
- Step 14 — started
- Step 14 — done — files: apps/api/internal/platform/config/config.go, config_test.go — table-driven; all problems joined in one error, no values echoed
- Step 15 — started
- Step 15 — done — files: apps/api/internal/platform/database/database.go — pgxpool.New only; error message fixed so the DSN is never echoed; no unit test (needs a DB)
- Step 16 — started
- Step 16 — done — files: apps/api/internal/platform/jwtauth/jwttest/jwttest.go — NewIssuer(t) as in plan; exports KeyID
- Step 17 — started
- Step 17 — done — files: apps/api/internal/platform/jwtauth/verifier.go, verifier_test.go — keyfunc.NewDefaultOverrideCtx (not NewDefaultCtx): 5 s HTTPTimeout bounds the first fetch, warn-level slog on refresh error; first fetch runs inside NewVerifier but its failure is swallowed, retried on unknown kid; 13 test cases
- Step 18 — started
- Step 18 — done — files: apps/api/internal/platform/jwtauth/middleware.go, middleware_test.go — 401 body from openapi.Error / ErrorCodeUNAUTHORIZED; bearer scheme case-insensitive; fake verifier tests
- Decision: checks stay none — the confirming question went unanswered; code from steps 12-22 is therefore uncompiled and untested until the user runs make lint / make test (or lean-review does)
- Step 19 — started
- Step 19 — done — files: apps/api/internal/platform/httpapi/health.go, health_test.go — 2 s ping timeout; fake pinger tests through the generated strict handler
- Step 20 — started
- Step 20 — done — files: apps/api/internal/platform/httpapi/router.go, router_test.go — NewHandler as in plan; real Verifier + jwttest
- Step 21 — started
- Step 21 — done — files: apps/api/cmd/api/main.go — run(getenv) (ctx made inside via signal.NotifyContext; plan's run(ctx, getenv) signature simplified); JSON slog; graceful shutdown 10 s
- Step 22 — started
- Step 22 — done — files: apps/api/Dockerfile, apps/api/.dockerignore, apps/api/.env.example — Decision: compose api service keeps no healthcheck (distroless has no shell/curl); --wait waits for 'running'
- go mod tidy run after step 22 (pgx, jwt, keyfunc, oapi-codegen/runtime now direct requires)
- Step 23 — started
- Step 23 — done — files: (none) — make lint-go / make test-go NOT run: user selected no checks (Phase 0b). Targets exist in Makefile; run them before merge
- Step 24 — started
- Step 24 — done — files: apps/mobile/** (flutter create --empty), android/app/build.gradle.kts, android/.../MainActivity.kt (moved to .../leantracker/), ios/Runner.xcodeproj/project.pbxproj — applicationId/namespace/bundle id io.github.example.leantracker, minSdk 29, iOS target 16.0; no test/widget_test.dart was generated (--empty); no Podfile exists in the empty template; app label stays 'lean_tracker' (out of plan scope); Flutter 3.44.0 / Dart 3.12.0
- Step 25 — started
- Step 25 — done — files: Makefile — gen-dart, lint-dart, test-dart and aggregates gen, lint, test added
- Step 26 — started
- Step 26 — done — files: apps/mobile/pubspec.yaml, pubspec.lock, analysis_options.yaml — flutter_riverpod ^3.5.0, go_router ^18.1.4, dio ^5.11.1, retrofit ^4.10.0, json_annotation ^4.12.0; dev build_runner ^2.15.1, swagger_parser ^1.46.0 (2.x not resolvable with retrofit_generator 10.3.3), retrofit_generator ^10.3.3, json_serializable ^6.15.2; swagger_parser config inside pubspec.yaml
- Step 27 — started
- Step 27 — done — files: apps/mobile/lib/main.dart, lib/app/app.dart, lib/app/router.dart — as in plan
- Step 28 — started
- Step 28 — done — files: apps/mobile/lib/gen/** (generated) — make gen-dart ok (swagger_parser 1.46 + build_runner); models Health, HealthStatus {ok, unavailable, $unknown}, Error, ErrorCode; FallbackClient.getHealth() under RestClient.fallback; build_runner warns --delete-conflicting-outputs is ignored in this version (flag kept in Makefile, harmless)
- Step 29 — started
- Step 29 — done — files: apps/mobile/test/app/app_test.dart, apps/mobile/test/gen/health_test.dart — shell build test; Health fromJson/round trip/unknown status. (generated toJson maps ok/unavailable to strings, checked in health.g.dart)
- Step 30 — started
- Step 30 — done — files: (none) — make lint-dart / make test-dart NOT run: user selected no checks (Phase 0b). Run before merge; Dart tests are unverified until then
- Step 31 — started
- Step 31 — done — files: docs/PRD.md — §14 role, §18 stack + local toolchain row, §19 M1 wording, D-62..D-68, version 1.1 / 2026-11-27
- Step 32 — started
- Step 32 — done — files: docs/ARCHITECTURE.md, docs/CODE_QUALITY.md — Layout (Makefile, compose.yaml, db/local, internal/gen/openapi, requestuser), AD7-AD9, open items 1-2 removed (3 renumbered 1), two single-sources rows
- Step 33 — started
- Step 33 — done — files: .claude/skills/lean-security/SKILL.md — make db-reset exit 0 (re-run, stack then torn down); grep for go-arch-lint / make arch was not clean: one leftover 'make arch' in lean-security SKILL.md removed, now clean. make lint / make test NOT run (not selected)
- Handoff — mode: worktree — branch: feature/01-repo-api-skeleton — base: 8f0d00a — checks: none — changed: .gitignore, Makefile, compose.yaml, .env.example, db/local/00_auth_stub.sql, db/migrations/0001..0005, contracts/openapi/openapi.yaml, apps/api/** (go.mod, go.sum, .golangci.yml, Dockerfile, .dockerignore, .env.example, cmd/api, internal/gen/openapi, internal/kernel/requestuser, internal/platform/{config,database,jwtauth,httpapi}), apps/mobile/** (flutter create + pubspec, analysis_options, lib/main.dart, lib/app, lib/gen, test/app, test/gen), docs/PRD.md, docs/ARCHITECTURE.md, docs/CODE_QUALITY.md, .claude/skills/lean-security/SKILL.md, specs/01-repo-api-skeleton.md — preexisting: none — checkpoints: 5/5
