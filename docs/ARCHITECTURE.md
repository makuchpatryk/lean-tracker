# Lean Tracker — Architecture

**Based on:** [PRD v1.0](PRD.md) | **Code rules:** [CODE_QUALITY.md](CODE_QUALITY.md) | **Design:** [DESIGN.html](DESIGN.html) (bundled canvas; open it in a browser) | **Status:** no code yet; M1 (repo, database and API skeleton) is next. Items marked _proposed_ are derived from the PRD, not stated in it, and are confirmed when their milestone is planned (see Open items).

## Drivers

| Driver | Source | Consequence |
| --- | --- | --- |
| Works offline, syncs later | BR-014, FR-013 | Drift (SQLite) is the source of truth on the device; every syncable record carries `id` (client UUID v4), `updated_at`, `deleted_at`; last `updated_at` wins |
| One user never sees another's data | BR-001, NFR-004 | Every query on a user table filters by `user_id` from the verified JWT; RLS on with no policies, so Supabase REST is closed |
| Old entries never change | BR-007 | An entry stores a snapshot of name, base unit and values per 100; no foreign key to a product |
| Fast logging | A-2, NFR-001, NFR-002 | Local save ≤ 300 ms p95; barcode lookup order local → own → shared → OFF; p95 ≤ 4 s online |
| Only an AI agent writes the code | PRD §9 | Rules are checked by tools, not by habit: architecture checks in CI, business rules unit-tested without I/O (NFR-008) |
| Free tiers, about 50 users | PRD §4, NFR-007 | One Cloud Run service, Supabase Free, one environment (`test`); no cache, queue or second datastore |
| Post-MVP web app | PRD §10.2 | `apps/mobile` and `apps/api` share nothing but the OpenAPI contract, so a third app can join |

## Layout

One repository, applications separated by directory (PRD §18, 18.1, AD1):

```
apps/mobile/            Flutter app
  lib/main.dart         entry; calls app/ only
  lib/app/              composition root: wires modules (DI), router, AppDatabase (Drift, AD5), sync registration, error mapping. Imports every module's public file; nothing imports app/
  lib/kernel/           framework-free primitives used by every layer: Result, Clock port, Uuid port, LocalDate, limits.dart (rule values). No Flutter, no Drift, no http
  lib/ui/               Material 3 theme built from the DESIGN.html tokens (light/dark by system, Nunito bundled as a font asset, AD12), shared widgets, l10n (app_en.arb, app_pl.arb, generated AppLocalizations), error code → message mapping. Imported by presentation layers and app/ only
  lib/gen/              generated Dart client of contracts/openapi (never edited by hand)
  lib/<module>/<module>.dart   the module's one public file (exports only what other modules or app/ need)
  lib/<module>/domain/         entities, value objects, rules (BR-xxx), ports (abstract repositories/services)
  lib/<module>/application/    use cases over the ports
  lib/<module>/infrastructure/ Drift tables and DAOs, API client adapters, platform plugins (scanner, notifications, secure storage)
  lib/<module>/presentation/   screens, widgets, view models (state holders)
  test/<module>/...            mirrors lib/; business rules tested here without Flutter widgets
  integration_test/            lean-e2e only; device or emulator, local
  drift_schemas/               Drift schema versions for local migrations
apps/api/               Go API
  cmd/api/main.go       composition root: config → deps → router
  internal/<module>/<module>.go   the module's public package (facade: constructors and the types others need)
  internal/<module>/internal/domain/       entities, rules (BR-xxx), ports (interfaces)
  internal/<module>/internal/application/  use cases over the ports
  internal/<module>/internal/infrastructure/  SQL repositories (the only SQL), OFF client, Supabase Admin client
  internal/<module>/internal/transport/    HTTP handlers: parse, call one use case, map the result
  internal/platform/    config (env validation), pgx pool, JWKS/JWT verifier, HTTP server and middleware, error mapping
  internal/kernel/      framework-free primitives: Clock, limits.go (rule values), id helpers
  .go-arch-lint.yml     architecture rules (CI)
contracts/openapi/      openapi.yaml: routes, schemas, error codes, field limits. Single contract
db/migrations/          0001_*.sql ... forward-only, applied with the Supabase CLI
docs/  specs/           PRD, ARCHITECTURE, CODE_QUALITY; plans
.github/workflows/      ci.yml (tests, architecture, secret scan), deploy-api.yml (manual), build-mobile.yml (manual)
apps/web/               reserved, not created in the MVP
```

### Modules

PRD 18.1 names nine capabilities: `auth`, `settings`, `products`, `diary`, `favorites_recents`, `summary`, `reminders`, `sync`, `account`. A module exists in an application only where that application has behavior for it (_proposed_, AD2):

| Module | Mobile | API | Owns |
| --- | --- | --- | --- |
| `auth` | yes | yes | Mobile: sign-up/in (email, Google, Apple), session, password reset (FR-001). API: JWT verification middleware, `user_id` in the request context |
| `settings` | yes | yes | Daily goals (FR-002, BR-002, BR-003); `user_settings` |
| `products` | yes | yes | Own products, private/shared (BR-009, FR-008), barcode scan and name search (FR-005, FR-006), OFF mapping (FR-007, API) |
| `diary` | yes | yes | Entries, meal categories, units, nutrition formula, snapshot, copy meal, day totals (BR-004 to BR-007, FR-003, FR-004, FR-010) |
| `favorites_recents` | yes | yes | BR-010, FR-009 |
| `summary` | yes | no | 7-day chart and average from local entries (BR-015, FR-011); computed on the device, works offline |
| `reminders` | yes | no | Up to 3 local notifications (BR-016, FR-012); no server push |
| `sync` | yes | yes | Push/pull, `updated_at` conflict rule, `deleted_at` propagation (FR-013) |
| `account` | yes | yes | Account deletion with re-authentication (BP-007, FR-016); `DELETE /v1/account` |

## Dependency rules

Both applications (PRD 18.1):

- `domain` imports no other layer, no framework package and no other module's internals. Allowed: its own module's `domain`, the language standard library and `kernel`.
- `application` imports its own `domain` and `kernel` only; it talks to the outside world through ports declared in `domain` or `application`.
- `infrastructure` and `presentation` (mobile) / `transport` (API) import inward (their own `application` and `domain`, `kernel`) and the framework they adapt. They never import each other.
- A module reaches another module only through that module's public file: `lib/<module>/<module>.dart` (Dart) or the package `internal/<module>` (Go). No import of another module's `domain`, `application`, `infrastructure`, `presentation` or `transport`. Types are declared by the consumer when a small copy is enough (`diary` owns its `ProductSnapshot`, it does not import `products`' entity, AD3).
- Business rules BR-xxx live in `domain` or `application`; handlers, widgets, DAOs and SQL do not decide rules.
- `apps/mobile`, `apps/api` and `apps/web` never import each other's code and share no code. Their only common input is `contracts/openapi/openapi.yaml`. Generated clients are the only shared-by-generation code.

Mobile only:

- `presentation` may import `ui/` and the generated `AppLocalizations`; `domain` and `application` never import `ui/`, `gen/`, `flutter`, `drift` or any plugin.
- `infrastructure` is the only place that imports `drift`, `supabase_flutter`, the scanner and notifications plugins, `flutter_secure_storage` and `lib/gen/`.
- `app/` is the only place that creates implementations and passes them to use cases. Modules never import `app/`; they receive dependencies through constructors or providers declared in `app/`.
- `sync` knows no module. Each module's `infrastructure` exposes its syncable tables as an implementation of a `SyncSource` port declared in `sync/domain`; `app/` registers them (AD4).
- Tables are declared per module in `infrastructure/`; the single `AppDatabase` that lists them lives in `app/` (AD5).

API only:

- Go enforces module walls with `internal/<module>/internal/...`: the layers of a module are importable only inside that module. The facade `internal/<module>/<module>.go` is the public file.
- `transport` imports `application` and the module's own request/response mapping, never `infrastructure`; only `cmd/api` (and the facade constructors it calls) connects them.
- SQL only in `infrastructure/` repositories, with bound parameters. The Supabase service role key and Admin API client exist only in `account/infrastructure`. The database pool is created in `platform/` and passed down as a dependency, never read from the environment inside a module.
- `platform/` imports no module, and modules do not import `platform`: `cmd/api` builds the pool, verifier and config in `platform/` and hands them to module constructors. The only package every module may import is `kernel` (AD6).

Enforcement (PRD 18.1, NFR-008): Go with `go-arch-lint` (`apps/api/.go-arch-lint.yml`); Dart with an import-restriction check (_proposed_: the `import_lint` package or an equivalent script, decided in M1, AD7). M1 ships a probe test that introduces a violation and confirms the check fails, and passes on the clean skeleton.

## Invariants

- **Data isolation (BR-001)**: the API reads `user_id` from the JWT `sub` and puts it in the request context; every repository method on a user table takes `userID` and filters by it. An upsert of a client-supplied `id` is `INSERT ... ON CONFLICT (id) DO UPDATE ... WHERE table.user_id = $user` so a client cannot overwrite another user's row. No endpoint returns a row of another user, except shared products.
- **Shared products (BR-009)**: a product is visible to others only while `is_shared = true` and `deleted_at IS NULL`; the author alone edits or deletes it. Search and barcode lookup read other users' products only through a repository method that filters `is_shared`. Setting it false removes the product from other users' results; entries already saved keep their snapshot.
- **Snapshot (BR-007)**: saving an entry copies `product_name`, `base_unit`, the four per-100 values and `serving_size` into it. Editing an entry changes only quantity, unit, meal and date (FR-004). A product edit or delete never touches entries, favorites' or recents' saved snapshots.
- **Nutrition (BR-006)**: `value_per_100 * quantity_in_base_unit / 100`, with `quantity_in_base_unit = quantity * serving_size` for `serving`. `serving` is allowed only when `serving_size` is set; g and ml are never converted. The formula lives only in `apps/mobile/lib/diary/domain/`. The API stores and validates entries, it does not recompute them.
- **Validation (BR-003)**: ranges are in the OpenAPI schemas (`minimum`, `maximum`, `maxLength`, `pattern`) and mirrored by `kernel/limits` in each application; a contract test per application reads the OpenAPI file and fails when a mirrored value differs (AD8). The API rejects out-of-range input with `validation`; the app validates before saving.
- **Day boundary (BR-004)**: `entry_date` is a local calendar date chosen on the device (`kernel/LocalDate`, `YYYY-MM-DD`), stored and sent as a date, never converted through UTC. Timestamps (`updated_at`, `deleted_at`, `last_used_at`) are UTC `timestamptz`.
- **Recents (BR-010)**: unique by `product_key`, 20 newest by `last_used_at`; the 21st removes the oldest, in the domain rule on the device and again on the server after each sync. Favorites are unique by `product_key` per user.
- **Sync (BR-014, FR-013)**: the device writes locally first, then pushes changes with `updated_at`; a delete sets `deleted_at` (soft delete, rows are not removed by sync). Conflict: the later `updated_at` wins, on the device and on the server. The server never trusts a client `updated_at` beyond a small clock skew into the future (_proposed_: reject or clamp above now + 5 minutes, AD9), otherwise one device could win every conflict forever. Sync payload size and item count are bounded.
- **Offline matrix (BR-014)**: works without network: entry CRUD, diary, weekly summary, favorites, recents, own-product create/edit, locally stored products. Needs network: login, barcode lookup of a product not stored locally (`OFFLINE_LOOKUP_UNAVAILABLE`), name search in OFF and shared products, account deletion.
- **Barcode lookup (FR-005)**: order local storage → own products → shared products → Open Food Facts; the first source that has it wins. EAN-13, EAN-8, UPC-A, UPC-E; the barcode is digits only, 8–13, validated before it is placed in a URL or SQL.
- **Open Food Facts (FR-007, §15)**: not stored server-side; the API maps `product_name`, `brands`, `energy-kcal_100g`, `proteins_100g`, `fat_100g`, `carbohydrates_100g`, `serving_quantity`; base unit `ml` when `product_quantity_unit` is `ml` or `l`, else `g`; products without a name or kcal are dropped; missing macros map to 0. Timeout 5 s, then `OFF_UNAVAILABLE`. The product is copied into the entry snapshot when the user saves.
- **Search (FR-006)**: query ≥ 2 characters, at most 30 results, order favorites, recents, own, shared, OFF. Offline: local only.
- **Auth (§14, FR-001)**: Supabase Auth issues the JWT; the API verifies signature through the project JWKS, `exp` and `aud` on every request except `GET /health`; the algorithm is pinned to what the JWKS declares (never `none`). The app keeps the refresh token in secure storage. Apple sign-in is offered on iOS and Android.
- **Database access (§14)**: the API uses a dedicated Postgres role (not the service role) with only the grants it needs; RLS enabled on every table with no policies for `anon` and `authenticated`. The service role key is used only for the Supabase Admin delete of `DELETE /v1/account`.
- **Account deletion (BR-017, FR-016)**: `DELETE /v1/account` deletes all rows of the user (own products, shared ones included) in one transaction, then the Supabase Auth user through the Admin API; the app first asks for re-authentication (password, or provider login) and clears the local database afterwards. Offline: not available.
- **Reminders (BR-016)**: 0–3 local daily notifications with fixed text (PL/EN); no server push, no token registration.
- **Secrets (NFR-004)**: `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_URL`, `DATABASE_URL`, `SUPABASE_JWKS_URL` only as GitHub Secrets injected into Cloud Run at deploy, and the local `apps/api/.env`; their names are the lines of `apps/api/.env.example` and the keys validated by `platform/config` (a test keeps both equal). The app holds only the Supabase anon key and URL and the API base URL. Never logged: passwords, JWTs, refresh tokens, email addresses, diary contents, secrets.
- **No tracking (MVP)**: no analytics SDK, no ads, no third-party SDK beyond PRD §18. Firebase Analytics and AI recognition are future scope (PRD §23) and are not built.
- **Localization (FR-017)**: PL and EN strings from ARB files by system locale (EN otherwise); no literal user-facing text in widgets; theme follows the system.

States: product `private ⇄ shared`; entry/product/favorite `active → deleted_at set` (soft); reminder list 0–3; session `signed out → signed in → signed out`; sync record `local-only → synced`.

## Errors

The API answers `{ "error": "<CODE>", "fields"?: { "<field>": "<code>" } }` with an HTTP status, never a stack trace. The closed list lives in `contracts/openapi` (`ErrorCode` enum); a use case returns a typed domain error and `transport` maps it. Codes (_proposed_ names for the statuses the PRD implies, AD10): `UNAUTHORIZED` (401), `FORBIDDEN` (403), `NOT_FOUND` (404), `VALIDATION` (400, with `fields`), `CONFLICT` (409), `PAYLOAD_TOO_LARGE` (413), `RATE_LIMITED` (429), `OFF_UNAVAILABLE` (502, PRD §15), `INTERNAL` (500). `OFFLINE_LOOKUP_UNAVAILABLE` is an app-side state (no network, product not stored locally), not an API response. The app maps codes to the exact texts of PRD §11 in `lib/ui/` (ARB keys); no API message text is shown to the user. Future codes (`AI_*`) are not added in the MVP.

## Testing

| Weight | Checks | Where |
| --- | --- | --- |
| Light | `make lint` (dart format, `flutter analyze`, `go vet`, `golangci-lint`), `make arch`, `make test`: Go table tests of domain and application on in-memory fakes; Flutter unit tests of domain and application (BR-003, BR-006, BR-007, BR-010, BR-015, sync conflict, copy meal) with no network, database or widgets; JWT middleware tests (NFR-004); repository tests against a local Postgres for the SQL that enforces isolation and the conditional upserts; limits mirror contract tests; widget tests for presentation where a screen has logic | implementation |
| Heavy | Flutter `integration_test/` on a device or emulator (NFR-002 timing, scan-to-save flow, offline add then sync); `flutter build apk --debug`, `go build ./...`, `make gen` with no diff (contract drift); manual NFR checks (NFR-001 timing on a physical device, NFR-003 cold start) | review; `lean-e2e` for integration tests; M4, M8 |

Unit tests run in CI on every push (D-30). Integration tests are not part of CI. Determinism: inject `Clock` and `Uuid`; no sleeps, no real network (fake OFF client, fake API client).

## Deployment

Exactly one environment, `test`: one Supabase project and one Cloud Run service (D-52). API deploy is the manual workflow `deploy-api.yml` (`workflow_dispatch` on `main`): tests → apply SQL migrations with the Supabase CLI → build the container → push to the registry → deploy to Cloud Run; each step stops the run if it fails (PRD 18.2). Rollback redeploys a previous image tag through the same workflow. Mobile builds come from the manual `build-mobile.yml` (Android app bundle to Google Play internal testing, iOS archive to TestFlight). Secrets live in GitHub Secrets and reach Cloud Run as environment variables. Claude never runs these workflows, never applies migrations to the hosted project, never sets secrets and never pushes to `main`: releases and remote data are the owner's call. Local work uses a local Postgres (or `supabase start`) and local emulators.

## Decisions (AD1–; separate from the PRD §20 log)

| # | Decision |
| --- | --- |
| AD1 | Monorepo layout of PRD §18; applications import nothing from each other; generated code lives only in `lib/gen/` (Dart) and a generated package of the API if a generator is used (decided in M1) |
| AD2 | A module exists in an application only where that application has behavior for it: `summary` and `reminders` have no API module (offline, device-only), the other seven exist in both |
| AD3 | Types needed across modules are declared by the consumer (a small copy), not imported from the producer's domain; the public file exports use cases, ports the consumer implements, and presentation entry points |
| AD4 | `sync` is generic: modules expose syncable stores through a `SyncSource` port; `app/` registers them; `sync` imports no module |
| AD5 | Drift tables per module in `infrastructure/`; one `AppDatabase` in `app/` |
| AD6 | `kernel` (both apps) holds only framework-free primitives and rule values; no business rule of a module belongs there |
| AD7 | Architecture checks: `go-arch-lint` for Go, an import-restriction check for Dart (tool chosen in M1), both probed by a test and required in CI |
| AD8 | Rule values are mirrored in each application's `kernel/limits` because code is not shared; the OpenAPI schema is the reference and a contract test per application compares them |
| AD9 | The server bounds client `updated_at` into the future so last-write-wins cannot be won forever by a bad clock |
| AD10 | The API error body is a closed `ErrorCode` enum in the OpenAPI file; texts belong to the app |
| AD11 | Local-only checks run through a root `Makefile`; skills report a missing target instead of inventing one |
| AD12 | Design tokens are copied once from `docs/DESIGN.html` into `lib/ui/` (palettes, meal colors) and the Nunito font is bundled as an asset, so the app makes no font request at runtime |

## Open items (decide when the milestone is planned)

1. **M1** — state management, DI and routing for Flutter (the PRD fixes none). Proposal: `flutter_riverpod` and `go_router`, no other code generation than Drift, l10n and the OpenAPI client. Any package beyond PRD §18 needs the owner's approval.
2. **M1** — Dart import-restriction tool (AD7) and the OpenAPI generators (Dart client; whether Go handlers or only types are generated, for example `oapi-codegen`).
3. **M1** — Go HTTP router and Postgres driver (proposal: the standard library `net/http` with Go 1.22 patterns, `pgx`); migrations are plain SQL run by the Supabase CLI.
4. **M4** — barcode scanner and notifications plugins, secure storage plugin (PRD §18 names the kinds, not the packages).
5. **M6** — sync wire protocol (endpoints, batch size, cursor), to be written into the OpenAPI file before the code.
6. **PRD cleanup** — FR-001's first acceptance criterion mentions a "consent screen" left from the deferred analytics (D-59); BP-006 and UF-001 go to the goals screen instead. Fix the PRD when convenient.
