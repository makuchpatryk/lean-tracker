# Lean Tracker — Architecture

**Based on:** [PRD](PRD.md) §18.1 | **Code rules:** [CODE_QUALITY.md](CODE_QUALITY.md)

This document says how the code is structured and which way dependencies point. Product rules (BR-, FR-, NFR-) live in the PRD, code rules in CODE_QUALITY.md.

## Principles

### Clean Architecture

The code is organised in rings. The inner rings hold what the app *is* (business rules); the outer rings hold *how* it talks to the world (UI, database, network, frameworks).

```
        ┌──────────────────────────────────────────────┐
        │  presentation / transport   infrastructure   │  frameworks, UI, HTTP, DB, plugins
        │     ┌────────────────────────────────────┐   │
        │     │            application             │   │  use cases
        │     │     ┌──────────────────────┐       │   │
        │     │     │        domain        │       │   │  entities, rules, ports
        │     │     └──────────────────────┘       │   │
        │     └────────────────────────────────────┘   │
        └──────────────────────────────────────────────┘
                 dependencies point inward only
```

- **Dependency rule.** Source code depends only inward. `domain` knows nothing about `application`; neither knows about Flutter, Drift, Postgres, HTTP or plugins.
- **Business rules are independent** of the UI, the database, frameworks and external services. They can be tested alone.
- **Frameworks are details.** Flutter, Drift, `net/http`, pgx and Supabase are plugged in at the edge and can be replaced without touching a rule.
- **Screaming architecture.** Folder names say what the app does (`diary`, `products`), not which framework it uses.

### Ports and adapters (hexagonal)

- A **port** is an interface the inner layers declare for what they need (`EntryRepository`, `ProductLookup`, `Clock`).
- An **adapter** in `infrastructure` implements a port with real technology (Drift DAO, SQL repository, HTTP client).
- Inner code calls the port; the adapter is chosen in the composition root. This is the **Dependency Inversion Principle** applied to the whole app.

### Modular monolith per application

- Code is grouped first by **business capability** (module), then by layer. A module is a vertical slice with its own `domain`, `application`, `infrastructure` and `presentation`/`transport`.
- A module exposes **one public entry point**; everything else is private to it.
- **High cohesion, low coupling:** what changes together lives together; modules know as little about each other as possible.

### Composition root

- Each application has one place that creates concrete classes and wires them (`lib/app/`, `cmd/api/`).
- Modules receive dependencies through constructors. No service locator, no global singletons inside modules.

### Independent applications, shared contract

- `apps/mobile`, `apps/api` and the future `apps/web` share no code.
- The contract is owned by the API (`apps/api/openapi.yaml`); the mobile app keeps a committed copy (`apps/mobile/openapi.yaml`) that `make check-contract` keeps byte-identical. Clients are generated from it and never edited by hand.
- **Contract first:** a change that crosses applications starts in the contract.

### Tested

- Every business rule is unit-tested without network, database or UI framework.

## Layers

| Layer | Holds | May depend on | Must not depend on |
| --- | --- | --- | --- |
| `domain` | Entities, value objects, business rules, ports | standard library, `kernel` | any other layer, any framework, any other module |
| `application` | Use cases: one user intent each, orchestrating domain objects through ports | own `domain`, `kernel` | `infrastructure`, `presentation`/`transport`, frameworks |
| `infrastructure` | Adapters implementing ports: database, HTTP clients, plugins, generated API client | own `application` and `domain`, `kernel`, the framework it adapts | `presentation`/`transport`, other modules' internals |
| `presentation` (mobile) | Screens, widgets, view models; renders state, sends intents to use cases | own `application` and `domain`, `kernel`, `ui/`, Flutter | `infrastructure`, database, API client, plugins |
| `transport` (API) | HTTP handlers: validate input, call one use case, map result and errors | own `application` and `domain`, `kernel`, `net/http` | `infrastructure`, SQL |

Shared building blocks outside modules:

- `kernel` — small framework-free primitives (`Result`, `Clock`, `Uuid`, `LocalDate`, rule values). No business rule of any module.
- `ui/` (mobile) — theme, shared widgets, localization. Used by `presentation` and `app/` only.
- `platform/` (API) — technical services (config, database pool, JWT verifier, HTTP server). Built in `cmd/api` and passed into modules; modules never import it.

## Layout

```
apps/mobile/                      Flutter application
  openapi.yaml                    committed copy of the API contract (make sync-contract; checked by make check-contract)
  env/example.json                build-time config template (`--dart-define-from-file=env/local.json`, git-ignored)
  assets/fonts/                   Nunito variable font and its OFL license
  lib/main.dart                   entry point; calls app/ only
  lib/app/                        composition root (wiring, router, database, sync registration)
  lib/kernel/                     framework-free primitives
  lib/ui/                         theme, design tokens, shared widgets (fields, buttons, mascot)
  lib/l10n/                       ARB files (EN, PL) and the generated localizations (committed)
  lib/kernel/limits/              rule values mirrored from the contract
  lib/gen/                        generated API client (never edited; `make gen-dart`)
  lib/<module>/<module>.dart      the module's only public file
  lib/<module>/domain/
  lib/<module>/application/
  lib/<module>/infrastructure/
  lib/<module>/presentation/
  test/<module>/                  mirrors lib/<module>/
apps/api/                         Go application
  openapi.yaml                    the contract between applications (owned here; contract first)
  db/migrations/                  SQL migrations (forward-only)
  db/local/                       local-only auth stand-in, not a migration, never applied to a hosted project
  cmd/api/main.go                 composition root
  cmd/devjwk/                     dev tool: writes the local Auth signing key (`make auth-keys`)
  internal/<module>/<module>.go   the module's only public package (facade)
  internal/<module>/internal/domain/
  internal/<module>/internal/application/
  internal/<module>/internal/infrastructure/
  internal/<module>/internal/transport/
  internal/platform/              technical services
  internal/kernel/                framework-free primitives (`requestuser`: user id in `context`; `clock`; `limits`)
  internal/gen/openapi/           generated server interface and models (never edited; `make gen-go`)
Makefile                          Docker-run toolchain: gen, lint, test, local database
compose.yaml                      local Postgres (`supabase/postgres`), local Supabase Auth (profile `auth`) and the API image (profile `app`)
local/auth-gateway.conf           nginx config that serves GoTrue under `/auth/v1`, like a hosted project
apps/web/                         reserved for post-MVP; not created now
```

## Modules

PRD 18.1 names nine capabilities. A module exists in an application only where that application has behavior for it (AD2):

| Module | Mobile | API |
| --- | --- | --- |
| `auth` | yes | yes |
| `settings` | yes | yes |
| `products` | yes | yes |
| `diary` | yes | yes |
| `favorites_recents` | yes | yes |
| `summary` | yes | no |
| `reminders` | yes | no |
| `sync` | yes | yes |
| `account` | yes | yes |

## Dependency rules

- `domain` imports only its own `domain`, the standard library and `kernel`.
- `application` imports only its own `domain` and `kernel`; it reaches the outside through ports.
- `infrastructure` and `presentation`/`transport` import inward only and never each other.
- A module reaches another module only through its public file (`lib/<module>/<module>.dart`, Go package `internal/<module>`).
- A module that needs another module's data declares its own small type instead of importing the other's entity (AD3).
- Business rules live in `domain` or `application`, never in widgets, handlers, adapters or SQL.
- Only the composition root creates adapters. Nothing imports the composition root.
- Applications never import each other; they meet only in the contract (the API's `openapi.yaml` and each client's checked copy).
- Mobile: Flutter, Drift, `supabase_flutter`, plugins and `lib/gen/` appear only in `infrastructure` (Flutter also in `presentation`, `ui/`, `app/`).
- API: SQL only in `infrastructure` repositories; Go `internal/` keeps a module's layers private to it.

## Cross-layer flow

- **Device:** widget → view model → use case → port → adapter (Drift or API client). Results and errors come back the same way.
- **API:** router → handler (validate) → use case → port → repository.
- **Errors:** inner layers return typed domain errors; only `transport` maps them to HTTP status and contract error codes; only the app maps codes to user text. No framework error crosses a layer outward (AD5).
- **Local first:** the device writes through its own adapters first; `sync` moves changes later. Feature modules do not know if they are online (AD4).

## Decisions

| # | Decision |
| --- | --- |
| AD1 | Monorepo, applications separated by directory, no shared code, one OpenAPI contract |
| AD2 | A module exists in an application only where it has behavior there (`summary` and `reminders` are mobile-only) |
| AD3 | Cross-module data shapes are declared by the consumer, not imported from the producer |
| AD4 | `sync` is generic: modules expose syncable data through a `SyncSource` port registered in `app/`; `sync` imports no feature module |
| AD5 | Errors cross layers as typed domain errors, mapped only at the edge |
| AD6 | Rule values both applications need are mirrored in each `kernel/limits` and compared with the contract by a test |
| AD7 | The generated Go server lives in `internal/gen/openapi`, not in `platform/`, so a module's `transport` can implement it without importing `platform/` |
| AD8 | The authenticated user id travels in the request `context` through `kernel/requestuser`; `platform/jwtauth` sets it, `transport` reads it |
| AD9 | Riverpod providers are declared in `app/`; routing uses `go_router`. A module's screens need use cases without importing `app/`, so the module declares the providers they read, with its port provider (`authGatewayProvider`, `goalsRepositoryProvider`) as an override point; `app/` plugs in the real adapter (`appOverrides()`) and derives what the router watches |
| AD10 | The API owns the contract (`apps/api/openapi.yaml`) and the schema (`apps/api/db/`); each client keeps a committed copy of the contract checked by `make check-contract` (PRD D-70) |
| AD11 | A Go module's public package builds its own adapters from a database handle and a clock that `cmd/api` passes in, because Go's `internal/` rule hides `settings/internal/infrastructure` from `cmd/api`. `cmd/api` stays the composition root: it creates the pool and the clock and embeds each module's handler in one server struct |

## Open items

1. **M6** — shape of the `SyncSource` port and the sync contract.
