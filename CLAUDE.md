# Claude Code Guidelines for Lean Tracker

Mobile calorie and macro diary (Android and iOS, Flutter) with barcode scan, favorites, recents and offline sync, backed by a Go REST API on Supabase (solo project, internal testing only, about 50 users, no revenue). Source of truth: `docs/PRD.md` (rules and scope, BR-, FR-, NFR-, UF-, BP- ids), `docs/ARCHITECTURE.md` (structure, dependency rules, invariants) and `docs/CODE_QUALITY.md` (code rules). Skills read all three. The PRD has no design file: UI follows Material 3 with the exact strings of PRD §11.

## Stack

A monorepo with strictly separated applications (PRD §18, 18.1; ARCHITECTURE AD1):
- `apps/mobile/` — Flutter (Dart), Material 3, Drift (SQLite), `supabase_flutter`, a barcode scanner plugin, a local notifications plugin. Modules by capability in `lib/<module>/` with the layers `domain`, `application`, `infrastructure`, `presentation`; `lib/app/` composition root; `lib/kernel/` framework-free primitives; `lib/ui/` theme, l10n and shared widgets; `lib/gen/` the generated API client
- `apps/api/` — Go REST API on Cloud Run. Modules by capability in `internal/<module>/` with the layers `domain`, `application`, `infrastructure`, `transport` under the module's own `internal/`; `internal/platform/` config, database, JWT verification and HTTP server; `internal/kernel/` primitives; `cmd/api/` the composition root
- `apps/web/` — reserved for the post-MVP web application. **Do not create it in the MVP** (PRD §18)
- `contracts/openapi/` — the OpenAPI 3 file: the only contract between applications; the Dart client is generated from it
- `db/migrations/` — forward-only SQL for Supabase Postgres, numbered, applied by the pipeline with the Supabase CLI
- `docs/` PRD, ARCHITECTURE, CODE_QUALITY; `specs/` plans; `.github/workflows/` CI and manual deploy workflows
- Supabase Postgres + Auth (the Go API reads Postgres directly through its own database role; Row Level Security on, no policies for `anon` and `authenticated`)

Allowed imports: `domain` imports nothing outside its own module's `domain` (plus `kernel`); `application` → `domain`; `infrastructure` and `presentation`/`transport` → inward only; a module reaches another module only through its public file (`lib/<module>/<module>.dart`, the Go package `internal/<module>`); `apps/mobile`, `apps/api` and the future `apps/web` never import each other and share nothing but `contracts/openapi`. Checked in CI (NFR-008): `go-arch-lint` for Go, an import-restriction check for Dart. A violation fails the build.

Tests: `go test ./...` in `apps/api`, `flutter test` in `apps/mobile` (unit tests of business rules run with no network, no database, no widgets); Flutter `integration_test/` in `apps/mobile/` on a device or emulator (local only, not in CI). Local env: `apps/api/.env` and `apps/mobile/env/local.json` (both git-ignored; only the `*.example` files are tracked).

Commands (a root `Makefile`, created in M1; if a target is missing, say so, do not invent one): `make lint` (dart format check, `flutter analyze`, `go vet`, `golangci-lint`), `make arch` (both architecture checks), `make test` (Go and Flutter unit tests), `make gen` (regenerate the Dart client and any Go contract code from `contracts/openapi`).

The repo may have little or no code yet. Check what exists; do not invent structure beyond ARCHITECTURE.md's layout (which follows PRD §18). Nothing from PRD §23 (future scope: AI recognition, Firebase Analytics) or §10.3 (out of scope) is built in the MVP.

## Commits

- **Follow Conventional Commits**
- **One line only:** subject line, short (≤50 chars), imperative mood, no body
- **No co-author line** — skip `Co-Authored-By: ...`
- **Ask where to commit, every time**: before any commit ask whether to commit on `main` or on a dedicated branch (suggest a name such as `fix/<task>`). Never pick a branch or `main` on your own

Examples:
- `feat: add diary entry snapshot`
- `fix: clamp recents to 20 items`

## Pull requests

- **No Claude attribution in PR descriptions.** Never add the "🤖 Generated with [Claude Code]" footer or any other Claude Code credit line when opening a PR with `gh pr create`. Body is the content only
- **Connect the GitHub issue.** Every PR links its issue in the body with a closing keyword on its own line (`Closes #<n>`). If the work has no issue or the right one is unclear, ask the user; never guess the number

## Skills

Use the lean-* skills:
- `lean-planning` — spec before coding
- `lean-implement` — turn plan into Dart and Go code
- `lean-review` — check code against the three docs and patterns
- `lean-e2e` — add one Flutter integration test from a confirmed test contract (the only skill that writes or runs integration tests)
- `lean-security` — read-only security audit

Skills output changes only; user decides when to commit and merge the worktree branch.

## Workflow rules

- **Ask where to work, every run**: implementation and flow ask whether to use their own git worktree (`.claude/worktrees/<task-name>` on branch `feature/<task-name>`, `<task-name>` = spec file name without `.md`, created from the current `HEAD`; main checkout untouched, implementation ticks the spec copy there) or the current branch. Review asks which one to review. Never assume. If the directory is not a git repository yet, skills work in place and say so (the owner runs `git init`)
- **Skills live in the main checkout**: read the five `lean-*` skills by absolute path from the main checkout, also from inside a linked worktree
- **Ask which checks to run, every run**: lint, architecture, unit tests (implementation); the same plus build and contract drift where relevant (review). Run only what the user selects
- **Deploy is the user's**: API deploys and mobile builds come from the manual GitHub Actions workflows (`workflow_dispatch` on `main`). Claude never runs those workflows, never runs `gcloud run deploy`, never applies migrations to the hosted Supabase project (`supabase db push`, `--linked`, `--db-url` of a remote), never sets GitHub, Cloud Run or Supabase secrets, never uploads builds to TestFlight or Google Play, never pushes to `main`. Local Postgres or `supabase start` and local emulators only
- **Secrets**: never read aloud, print or commit `.env`, `env/*.json` with real values, service account JSON, keystores or `SUPABASE_SERVICE_ROLE_KEY`; only `*.example` files are tracked. The app contains only the Supabase anon key and URL (NFR-004)
- **Migrations are forward-only**: a migration that may already be applied is never edited; a change is a new numbered file in `db/migrations/`
- **No integration tests** in any skill except `lean-e2e`: planning, implementation, review and security neither run nor write `integration_test/` files. Planning never runs tests
- **CI runs the checks**: GitHub Actions run Go tests, Flutter tests, architecture checks and the secret scan on every push and pull request; a failure blocks merging into `main`. They never deploy. Claude never changes repository settings, branch protection or workflow permissions without being asked
