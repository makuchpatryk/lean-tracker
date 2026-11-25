# Code quality

Rules Lean Tracker is written and reviewed against. **KISS and YAGNI first** (one author, about 50 friends, 0 revenue, free tiers). Product: [PRD](./PRD.md). Structure: [ARCHITECTURE.md](./ARCHITECTURE.md).

## Principles

- **KISS**: platform and standard library first. Go: `net/http`, `database/sql` or `pgx`, `encoding/json`, `log/slog`, `context`; no web framework, no ORM, no DI container. Dart: the Flutter SDK, Drift, `supabase_flutter`, one scanner plugin, one notifications plugin, `intl`/gen_l10n; plus whatever M1 confirms for state, routing and the generated client (ARCHITECTURE Open items). A new dependency needs a reason a few lines of code cannot meet, and the owner's approval when it is not in PRD §18. Dev-only tooling: `flutter analyze`, `dart format`, `go vet`, `golangci-lint`, `go-arch-lint`, the Dart import check, the OpenAPI generators, GitHub Actions.
- **YAGNI**: only PRD scope. Nothing from §10.3 (premium, payments, goal calculator, water/weight/exercise, custom meal categories, theme switch, server push, admin, data export, tablet or web layouts) and nothing from §23 (AI recognition, Firebase Analytics, `ai_usage`) is built. No retries, caches or background jobs beyond the PRD. Interfaces (ports) only where a second implementation is real: the device/API/OFF/clock boundary, the repositories of a module, the sync source. Delete code with no caller.
- **DRY**: one source of truth per fact (table below). Because applications share no code, a rule value that both need is mirrored once per application in `kernel/limits` and held equal to the OpenAPI file by a test. Extract on the third copy, not the second.
- **Separation**: rules live in `domain` and `application`, never in widgets, handlers, DAOs or SQL. `presentation` renders state and sends intents; `transport` parses, calls one use case and maps the result; `infrastructure` adapts one outside thing. SQL only in `apps/api/internal/<module>/internal/infrastructure/`; Drift, `supabase_flutter` and plugins only in `lib/<module>/infrastructure/`. Enforcement is `make arch` (ARCHITECTURE §Dependency rules).
- **Small units**: one job per function, consumer-declared types, pass what is used, no reaching through objects (`a.b.c.d`).
- **Composition**: functions, small structs/classes and constructor injection; no inheritance hierarchies for behavior, no global state, no service locator inside modules (only `app/` and `cmd/api` wire things), no boolean-flag functions. Errors are values: Go `error` with typed domain errors, Dart sealed result/exception types in `kernel`.

## Single sources of truth

| Knowledge | Lives in |
| --- | --- |
| Wire contract: routes, request/response shapes, error codes, field ranges and lengths | `contracts/openapi/openapi.yaml` |
| Rule values (goal ranges 500–10000 and 0–1000, quantity 0.1–10000 with one decimal, per-100 ranges, 20 recents, 30 search results, 3 reminders, 7 summary days, 5 s OFF timeout, barcode length 8–13, name 1–120, brand ≤ 80, password ≥ 8) | the OpenAPI schemas are the reference; mirrored in `apps/mobile/lib/kernel/limits.dart` and `apps/api/internal/kernel/limits.go`; each has a test that parses the OpenAPI file and compares |
| Nutrition per entry (BR-006), serving conversion | `apps/mobile/lib/diary/domain/` only |
| Entry snapshot fields (BR-007) | `diary/domain` on the device; the `diary_entries` table and the OpenAPI entry schema on the server |
| Day boundary and local date (BR-004) | `apps/mobile/lib/kernel/local_date.dart`; the API treats `entry_date` as an opaque date |
| Weekly summary and average (BR-015) | `apps/mobile/lib/summary/domain/` |
| Recents ordering and the 20 cap (BR-010) | `favorites_recents/domain` on each side (device and server), one function per side, each unit-tested |
| Last-write-wins and soft delete (FR-013) | `sync/domain` on each side (device and server), each unit-tested; the rule is also written in the OpenAPI description |
| Open Food Facts mapping (FR-007) | `apps/api/internal/products/internal/domain/` (pure function over a domain-declared OFF struct); the JSON decoding is in `infrastructure/` |
| Product visibility (BR-009) | the shared-products repository methods in `products/internal/infrastructure/` (filter `is_shared` and `deleted_at`) and the `products` domain rule that only the author edits or deletes |
| JWT verification and `user_id` extraction | `apps/api/internal/platform/` (verifier) and `auth` module middleware; modules read `userID` from the request context only through `auth`'s public package |
| Error codes and their texts | codes: `contracts/openapi` (`ErrorCode`); texts: `apps/mobile/lib/ui/` mapping to ARB keys |
| UI text (PL and EN) | `apps/mobile/lib/l10n/app_en.arb`, `app_pl.arb` (exact strings of PRD §11) |
| Theme, spacing and shared widgets | `apps/mobile/lib/ui/` (Material 3 color scheme from a seed, light and dark by system) |
| Schema and indexes | `db/migrations/` (server), `apps/mobile/lib/<module>/infrastructure/` Drift tables and `apps/mobile/drift_schemas/` (device) |
| Configuration names and secrets | API: `apps/api/internal/platform/config` (validation), `apps/api/.env.example`, the deploy workflow's secret names, kept equal by a test; app: `apps/mobile/env/example.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`) |
| Commit message rule | CLAUDE.md "Commits" |

## Working agreements

- **Dart**: sound null safety; `flutter analyze` with the project's `analysis_options.yaml` clean (strict casts, strict inference, strict raw types); no `dynamic`, no `!` without a comment saying why it cannot be null; `const` where possible; exhaustive `switch` on sealed types; `dart format` clean.
- **Go**: `gofmt`/`go vet`/`golangci-lint` clean; `context.Context` first parameter of anything that does I/O; no `panic` outside `main`; wrap errors with `%w` and map them once, in `transport`; no package-level mutable state; exported API of a module is only its facade.
- **Boundaries**: request bodies, query and path params, OFF responses, JWT claims, Drift JSON columns (`product_snapshot`) and anything from the platform are untrusted until validated against the contract. Validate at the edge (`transport`, DAO mapping), then pass typed values inward.
- **SQL**: bound parameters only, never string-built queries; every statement on a user table has `user_id = $n`; one statement per repository function where possible; no N+1 in sync pulls; no `SELECT *` in repositories (explicit columns, so no internal column leaks); migrations forward-only and never edited after they are applied.
- **Errors**: the API replies with a code from the closed list, never a stack trace or a driver error; the app maps codes to ARB texts and never matches message strings.
- **Determinism**: inject `Clock` and `Uuid`; tests need no sleeps and no network; time zones are explicit (the device local date for `entry_date`, UTC for timestamps).
- **Persistence**: only the tables of PRD §13 on the server and their Drift mirror on the device; the app stores the session in secure storage and nothing else outside Drift. No analytics identifiers, no extra files with personal data.
- **Cleanup**: streams, subscriptions, controllers, camera and timers disposed with the widget or scope; Go goroutines stop with their context; HTTP bodies closed.
- **Privacy and safety**: never log passwords, JWTs, refresh tokens, email addresses, diary contents or secrets; log a request id and a status, not payloads. The device local database holds personal diary data: it is cleared on sign-out and on account deletion.
- **UI**: no literal user-facing text in widgets (ARB keys, PL and EN); every interactive element has a `Semantics` label; layouts work from 360 dp wide, in portrait, with system font scaling up to 200%; text contrast at least 4.5:1; light and dark theme from the system; Material 3 components, no custom design system.
- **Flutter**: logic in `domain`/`application`, state in view models; widgets build from state and send intents, they never call the API client, Drift or a plugin directly; no `BuildContext` across async gaps without a mounted check; keep `build` free of side effects.
- **Comments**: why, not what; cite the BR/FR/NFR id or decision number for a non-obvious rule.
- **Tests**: one behavior per case, the name states the rule and cites the id (`BR-006: serving uses serving_size`); table-driven in Go, `group`/`test` in Dart; business-rule tests need no network, database or widget (NFR-008).

## Review checklist

1. Simpler way? Does the platform or a package already in use do it?
2. Does every line serve a PRD requirement, and nothing from §10.3 or §23?
3. Knowledge in two places? A literal that belongs in `kernel/limits`, the OpenAPI file, an ARB file or the theme?
4. Right folder and layer? `domain` and `application` free of framework, SQL, plugin and `ui` imports; module reached only through its public file; `apps/*` untouched by each other; `make arch` green?
5. Data isolation: every query on a user table filters by the JWT user; upserts cannot overwrite another user's row; shared products filtered by `is_shared`; `updated_at` bounded; input validated against the contract?
6. Offline: does the feature work (or fail with the documented message) per the BR-014 matrix? Local write first, sync later, soft delete?
7. Snapshots: entries independent of later product changes; units and nutrition per BR-006?
8. PL + EN strings, `Semantics`, 360 dp, font scale, light and dark?
9. Tests for the logic; `make lint`, `make arch` and `make test` clean; `make gen` produces no diff; integration tests only through `lean-e2e`?

## Known debt

None.
