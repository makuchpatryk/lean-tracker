# Code quality

Rules the code is written and reviewed against. Product: [PRD](PRD.md). Structure: [ARCHITECTURE.md](ARCHITECTURE.md).

## Principles

### KISS — Keep It Simple

- Choose the simplest solution that meets the requirement.
- Standard library and platform first; a new dependency needs a reason a few lines of code cannot meet.
- Readable beats clever. Code is read far more often than it is written.

### YAGNI — You Aren't Gonna Need It

- Build only what the PRD asks for now. Nothing from PRD §10.3 (out of scope) or §23 (future scope).
- No speculative parameters, flags, abstractions or "for later" hooks.
- Delete code with no caller.

### DRY — Don't Repeat Yourself

- Every piece of knowledge (a rule, a limit, a text, a type) has one source of truth.
- Duplication of *knowledge* is the problem, not similar-looking code. Extract on the third copy, not the second.

### SOLID

- **S — Single Responsibility:** a class, function or module has one reason to change.
- **O — Open/Closed:** extend behavior by adding code (a new adapter, a new use case), not by editing working code everywhere.
- **L — Liskov Substitution:** every implementation of a port can replace another without the caller noticing (a fake repository behaves like the real one).
- **I — Interface Segregation:** small, focused ports declared by the consumer; no "god" interfaces.
- **D — Dependency Inversion:** depend on abstractions (ports), not on concrete classes; inner layers never know which adapter runs.

### Other rules

- **Separation of concerns:** rules in `domain`/`application`; UI, HTTP, SQL and plugins at the edge (ARCHITECTURE.md).
- **Composition over inheritance:** build behavior from small objects and functions; no deep class hierarchies.
- **Law of Demeter:** talk only to direct collaborators; no `a.b.c.d` chains.
- **Fail fast:** validate input at the boundary; reject invalid state immediately with a clear error.
- **Explicit over implicit:** no hidden globals, no magic; dependencies come through constructors.
- **Principle of least surprise:** names and behavior do what a reader expects.
- **Boy scout rule:** leave touched code a little cleaner, but stay inside the task.

## Single sources of truth

| Knowledge | Lives in |
| --- | --- |
| Wire contract: routes, schemas, error codes, field limits | `apps/api/openapi.yaml` (mobile copy `apps/mobile/openapi.yaml`, kept identical by `make check-contract`) |
| Rule values (ranges, caps, timeouts) | the contract; mirrored in each app's `kernel/limits`, checked by a test |
| Business rules | the owning module's `domain` (or `application`) |
| UI text (PL, EN) | `apps/mobile/lib/l10n/*.arb` |
| Theme and design tokens | `apps/mobile/lib/ui/` |
| Database schema | `apps/api/db/migrations/` (server), Drift tables in each module's `infrastructure/`, composed in `app/database.dart` (device) |
| Configuration names | the API config validation and `*.example` env files |
| Tool versions | root `Makefile` image variables (`apps/api/Dockerfile` and `go.mod` follow them) |
| Generated clients and server stubs | `make gen` from the contract |

## Working agreements

- **Naming:** intention-revealing names; domain words from the PRD glossary; no abbreviations except standard ones (`id`, `kcal`).
- **Functions:** small, one job, few parameters, no boolean-flag parameters; pass what is used.
- **Types:** Dart — sound null safety, no `dynamic`, no `!` without a reason, exhaustive `switch` on sealed types. Go — `gofmt`, `go vet`, `golangci-lint` clean, `context.Context` first on I/O, no `panic` outside `main`.
- **Errors:** errors are values; typed domain errors inside, mapped once at the edge; never show stack traces or match on message text.
- **Boundaries:** everything from outside (request bodies, API responses, JSON columns, platform values) is untrusted until validated.
- **SQL:** bound parameters only; explicit columns, no `SELECT *`; migrations are forward-only.
- **State and side effects:** no global mutable state; inject `Clock` and `Uuid`; side effects stay in adapters.
- **Cleanup:** dispose controllers, streams and subscriptions; stop goroutines with their context; close HTTP bodies.
- **Security and privacy:** never log passwords, tokens, emails, diary contents or secrets; secrets only from the environment.
- **UI:** no literal user text in widgets (ARB keys); `Semantics` on interactive elements; works from 360 dp and with large fonts; light and dark.
- **Comments:** explain *why*, not *what*; cite the BR-/FR-/NFR- id for non-obvious rules.
- **Tests:** one behavior per test, the name states the rule; business rules tested without network, database or widgets; fakes over mocks; no sleeps.

## Review checklist

1. Is there a simpler way (KISS)? Does the platform already do it?
2. Does every line serve a requirement (YAGNI)?
3. Is any knowledge duplicated (DRY)? Literal that belongs in the contract, `kernel/limits`, ARB or theme?
4. Does each unit have one responsibility, and does it depend on abstractions (SOLID)?
5. Right module and layer? Dependency rule and module boundaries respected (ARCHITECTURE.md)?
6. Input validated at the boundary, errors mapped at the edge, nothing sensitive logged?
7. Tests for the logic; lint and unit tests clean?

## Known debt

- Dev seed products in `apps/mobile/lib/diary/infrastructure/dev_seed_products.dart` (code that ships, behind `kDebugMode`). Removed in M4, when the products module replaces the `ProductSource` override.
