# Contract and DB Owned by the API — Implementation Plan

## Summary
The OpenAPI contract (`contracts/openapi/openapi.yaml`) and the database schema (`db/`) sit at the repo root, outside the application that owns them. This change moves both into `apps/api/`. The mobile app keeps its own committed copy of the contract, `apps/mobile/openapi.yaml`, and `make check-contract` (part of `make lint`, so it runs in CI) fails when the two copies differ. Only paths change: no behavior, no contract content, no migration content. This is a follow-up to M1 (merged in PR #2). Base: `main` at `3b8b34f`, clean working tree. The stale worktree `.claude/worktrees/01-repo-api-skeleton` (branch `feature/01-repo-api-skeleton`, already merged) is not used.

## Success Criteria
- `git ls-files | grep -E '^(contracts|db)/'` prints nothing, and neither directory exists on disk.
- `apps/api/openapi.yaml`, `apps/api/db/local/00_auth_stub.sql` and `apps/api/db/migrations/0001`–`0005` exist as pure renames: `git diff --cached -M --stat` shows each as a rename with no content change.
- `apps/mobile/openapi.yaml` is byte-identical to `apps/api/openapi.yaml`. `make check-contract` exits 0, and exits non-zero once the copy is changed.
- `make lint` (which now runs `check-contract` first), `make test` and `make db-reset` all exit 0. `db-reset` applies the stub and then `0001`–`0005` from `apps/api/db/`.
- No old path remains outside `specs/01-repo-api-skeleton.md` (history): the grep in step 11 prints nothing.

## Scope & Constraints
- **In scope:**
  - `git mv` of `db/` and of the contract.
  - The mobile contract copy.
  - Makefile targets `sync-contract` and `check-contract`, and `lint` depending on `check-contract`.
  - Path updates in the Makefile `db-reset`, `apps/api/internal/gen/openapi/generate.go` and `apps/mobile/pubspec.yaml`.
  - Docs: PRD §18, §18.1, §18.2 and new D-70; ARCHITECTURE principle, layout, dependency rule and new AD10; CODE_QUALITY single-sources table.
  - Path mentions in the local, untracked `.claude/skills/*/SKILL.md`.
- **Out of scope:**
  - Any change to contract or migration content.
  - Regenerating code with new content.
  - `compose.yaml` and `.github/workflows/ci.yml` (neither names the moved paths).
  - `apps/api/.dockerignore`. `db/` and `openapi.yaml` enter the build stage context through `COPY . .`, but only `/api` reaches the distroless image.
  - `apps/web` (§10.3).
  - Editing `specs/01-repo-api-skeleton.md` (history).
  - Deploy and hosted migrations (M8).
- **Hard constraints:**
  - Applications never import each other (PRD §18.1).
  - Migrations are forward-only and must not be edited (§18.2). A rename keeps the content, and nothing hosted has been applied yet (D-61).
  - Generated code is never edited by hand (D-64).
  - Docker-only toolchain through the root `Makefile` (D-66). `cp` and `cmp` run on the host like the existing `docker compose`/`for` recipes; they are coreutils, not project tools.
- **Trade-offs:**
  - Two committed contract files plus a check, chosen over one shared root file. Each app owns what it reads, at the cost of a sync step whenever the contract changes.

## Architecture & Design

### High-Level Flow
```
apps/api/openapi.yaml  (source of truth, edited first: contract first)
   │  go:generate ../../../openapi.yaml      ─► apps/api/internal/gen/openapi/openapi.gen.go
   │  make sync-contract (cp)                ─► apps/mobile/openapi.yaml (committed copy)
   │                                              │ swagger_parser schema_path: openapi.yaml
   │                                              ▼
   │                                           apps/mobile/lib/gen/**
   └─ make check-contract (cmp) in make lint / CI: fails when the copy differs

apps/api/db/local/00_auth_stub.sql + apps/api/db/migrations/*.sql
   └─ make db-reset (root Makefile, psql loop into the compose `db` service)
```

### Key Changes
- **Files moved:**
  - `git mv db apps/api/db`, which yields `apps/api/db/local/00_auth_stub.sql` and `apps/api/db/migrations/0001_user_settings.sql` … `0005_recents.sql`.
  - `git mv contracts/openapi/openapi.yaml apps/api/openapi.yaml`, then remove the now-empty `contracts/`.
- **New file:** `apps/mobile/openapi.yaml`, copied by `make sync-contract` and committed.
- **Makefile** (root; stays at root and only paths change):
  ```make
  .PHONY: gen gen-go gen-dart lint lint-go lint-dart test test-go test-dart up down db-reset run-api sync-contract check-contract

  lint: check-contract lint-go lint-dart

  # The API owns the contract; the mobile app keeps a committed copy (D-70).
  sync-contract:
  	cp apps/api/openapi.yaml apps/mobile/openapi.yaml

  check-contract:
  	@cmp -s apps/api/openapi.yaml apps/mobile/openapi.yaml || { echo "apps/mobile/openapi.yaml differs from apps/api/openapi.yaml: run make sync-contract"; exit 1; }
  ```
  The `db-reset` loop becomes `for f in apps/api/db/local/00_auth_stub.sql apps/api/db/migrations/*.sql; do \`.
- **`apps/api/internal/gen/openapi/generate.go`:**
  ```go
  // Package openapi is generated from apps/api/openapi.yaml. Never edit openapi.gen.go.
  //go:generate go tool oapi-codegen -config config.yaml ../../../openapi.yaml
  ```
  `go generate` runs in the package directory, so `../../../` resolves to `apps/api/`. `openapi.gen.go` embeds neither the spec nor its path (verified: no `swaggerSpec`/`GetSwagger`), so its output is unchanged.
- **`apps/mobile/pubspec.yaml`:**
  - `schema_path: openapi.yaml`. swagger_parser runs with cwd `/work/apps/mobile` (`FLUTTER_RUN -w`).
  - Comment above it: `# Dart client generated from apps/mobile/openapi.yaml, the committed copy of the API contract (make sync-contract): make gen-dart. Output is committed and never edited.`
  - `lib/gen/` contains no source path, so its output is unchanged.
- **Contract, data model, limits, UI, dependencies:** no change.

### Fit with Project Docs
- **PRD:**
  - §18 repo structure: replace `/contracts/openapi` and `/db/migrations` with `/apps/api/openapi.yaml` (contract, API-owned), `/apps/api/db/migrations` (SQL migrations) and `/apps/mobile/openapi.yaml` (checked copy the Dart client is generated from).
  - §18.1 Application boundaries: "They must share only the OpenAPI contract, owned by the API at `/apps/api/openapi.yaml`; each other application keeps a byte-identical copy checked by `make check-contract`."
  - §18.2 API deployment step (2): `/apps/api/db/migrations`.
  - §20: new D-70. D-64 and D-66 stay as written, since the log is append-only and neither names the moved paths. Version line stays 1.1, date stays 2026-11-27 (same day).
- **ARCHITECTURE.md:**
  - "Independent applications, shared contract": "The contract is owned by the API (`apps/api/openapi.yaml`); the mobile app keeps a committed copy (`apps/mobile/openapi.yaml`) that `make check-contract` keeps byte-identical. Clients are generated from it and never edited by hand."
  - §Layout: add `openapi.yaml` and `db/migrations/`, `db/local/` under `apps/api/`, and `openapi.yaml` under `apps/mobile/`. Drop the root `contracts/` and `db/` lines.
  - Dependency rule: "Applications never import each other; they meet only in the contract (the API's `openapi.yaml` and each client's checked copy)."
  - New AD10.
- **CODE_QUALITY.md:**
  - Wire contract row: `apps/api/openapi.yaml` (mobile copy `apps/mobile/openapi.yaml`, kept identical by `make check-contract`).
  - Database schema row: `apps/api/db/migrations/` (server), Drift tables in `infrastructure/` (device).
  - KISS: `cp`/`cmp`, no tool. Single source: one edited file, with a mechanical copy that is checked rather than trusted.
- **Docs to update:** PRD §18, §18.1, §18.2, §20; ARCHITECTURE principle, Layout, Dependency rules, Decisions; CODE_QUALITY single sources. Spec 01 stays as history.

### Alternative Approaches Considered
- **Keep the root `contracts/` and `db/`:** one file, nothing to sync. Not chosen: the user wants each artifact inside the app that owns it.
- **Mobile reads `../api/openapi.yaml` directly:** no copy. Not chosen: one app would reach into another's folder.
- **Symlink `apps/mobile/openapi.yaml`:** no drift. Not chosen: it hides the cross-app dependency and is unreliable on Windows checkouts.
- **No copy check:** simplest. Not chosen (user): drift would be silent until runtime.
- **Committed copy plus `sync-contract` and `check-contract` in `make lint`/CI:** chosen (user). The copy is visible, drift is caught mechanically, and no new tool is needed.

## Implementation Steps
Move
1. [x] `git mv db apps/api/db`. `git ls-files apps/api/db` lists 6 files.
2. [x] `git mv contracts/openapi/openapi.yaml apps/api/openapi.yaml`, then `rmdir contracts/openapi contracts`.

Wire the paths
3. [x] Root `Makefile`:
   - Change the `db-reset` loop to `apps/api/db/local/00_auth_stub.sql apps/api/db/migrations/*.sql`.
   - Add `sync-contract` and `check-contract` with the comment from Key Changes.
   - Set `lint: check-contract lint-go lint-dart`.
   - Add both targets to `.PHONY`.
4. [x] Run `make sync-contract` and `git add apps/mobile/openapi.yaml`.
5. [x] In `apps/api/internal/gen/openapi/generate.go`, change the package comment and the `go:generate` path to `../../../openapi.yaml`. Do not touch `openapi.gen.go`.
6. [x] In `apps/mobile/pubspec.yaml`, set `schema_path: openapi.yaml` and rewrite the comment above it as in Key Changes. Do not touch `lib/gen/`.

Docs
7. [x] `docs/PRD.md`: apply the §18 repo-structure bullets, §18.1 Application boundaries and §18.2 API deployment step (2) as in Fit with Project Docs. Append this row after D-69:
   `| D-70 | The OpenAPI contract is owned by the API at `apps/api/openapi.yaml`; the mobile app keeps a committed copy at `apps/mobile/openapi.yaml` that `make check-contract` (part of `make lint`, run in CI) keeps byte-identical; the database schema lives in `apps/api/db/` (`migrations/`, `local/`). Supersedes the root `contracts/openapi` and `db/` locations | Root `contracts/` and `db/` shared by all applications; mobile reading the API's file directly; symlink | User choice: each application owns what it uses and never reaches into another's folder |`
8. [x] `docs/ARCHITECTURE.md`:
   - Rewrite the "Independent applications, shared contract" bullet as in Fit with Project Docs.
   - Layout: under `apps/mobile/` add `openapi.yaml                    committed copy of the API contract (make sync-contract; checked by make check-contract)`.
   - Layout: under `apps/api/` add `openapi.yaml                    the contract between applications (owned here; contract first)`, `db/migrations/                  SQL migrations (forward-only)` and `db/local/                       local-only auth stand-in, not a migration, never applied to a hosted project`.
   - Layout: remove the root `contracts/openapi/`, `db/migrations/` and `db/local/` lines.
   - Rewrite the dependency rule line.
   - Append `| AD10 | The API owns the contract (`apps/api/openapi.yaml`) and the schema (`apps/api/db/`); each client keeps a committed copy of the contract checked by `make check-contract` (PRD D-70) |`.
9. [x] `docs/CODE_QUALITY.md`: update the wire contract and database schema rows as in Fit with Project Docs.
10. [x] Local untracked skills: in `.claude/skills/lean-planning/SKILL.md`, `lean-implement/SKILL.md` and `lean-review/SKILL.md`, replace `contracts/openapi/openapi.yaml` and `contracts/openapi/` with `apps/api/openapi.yaml`, and `db/migrations/` with `apps/api/db/migrations/`. Where a contract change is described, add "then `make sync-contract`". The files are not in git, so they do not show in the diff.

Verify
11. [x] Stale-path grep prints nothing: `grep -rInE 'contracts/|(^|[^a-z_/-])db/(migrations|local)' . --exclude-dir={.git,.claude,.dart_tool,build,.cache,.idea} --exclude=DESIGN.html --exclude=01-repo-api-skeleton.md`. Also `git status` shows only the renames, the new copy and the edited files.
12. [x] Drift gate: `make check-contract` exits 0. Append a blank line to `apps/mobile/openapi.yaml`: `make check-contract` exits 1 with the message. Then `make sync-contract` and `make check-contract` exits 0.

## Checkpoints (Todo List)
- [x] CP1 — Moves: steps 1-2. `git diff --cached -M --stat` shows 7 renames with no content change; `contracts/` and `db/` are gone. — 7 renames, 0 content change, contracts/ and db/ gone
- [x] CP2 — Paths and copy: steps 3-6. `make check-contract` exits 0 and `make db-reset` exits 0, applying `apps/api/db/local/00_auth_stub.sql` then `0001`–`0005`. — check-contract exit 0; db-reset not run (not selected)
- [x] CP3 — Docs: steps 7-10. The step 11 grep prints nothing. — only intended hits remain (see log, step 11)
- [x] CP4 — Final light verification: steps 11-12. The drift gate behaves as in step 12, and `make lint` and `make test` are green. — drift gate verified; make lint / make test not run (not selected)

## Risks & Mitigations
- **A path is left behind** (string paths aren't caught by the compiler or analyzer).
  - Mitigation: the step 11 grep, which CP3 and CP4 require to be empty.
- **Wrong relative path in `go:generate` or `schema_path`.** `make gen` would fail or read nothing.
  - Mitigation: derive the paths from the cwd (package dir `apps/api/internal/gen/openapi`; Flutter `-w /work/apps/mobile`).
  - Mitigation: lean-review runs `make gen` (the contract-drift check) and expects no change in the generated files.
- **A future contract edit forgets `make sync-contract`.**
  - Mitigation: `check-contract` in `make lint` fails locally and in CI.
  - Residual risk: a forgotten `make gen-dart` after a sync is still only caught by the lean-review drift check, as before.
- **History looks like delete plus add.**
  - Mitigation: `git mv` with no content change keeps rename detection at 100%.
- **Local skills keep pointing at old paths**, so future plans target the wrong folders.
  - Mitigation: step 10.

## Test Strategy
- **Light** (during implementation): `make check-contract`, including the negative case in step 12; `make db-reset`; `make lint`; `make test`. No new unit tests: no behavior changes.
- **Heavy** (lean-review only, if selected): `make gen`, then `git status --short apps/api/internal/gen apps/mobile/lib/gen` is empty. This proves the generators read the new paths and produce identical code. Also the API image build (`make run-api`) and `curl localhost:8080/v1/health` → 200.
- **Integration tests:** none. Nothing for `/lean-e2e`.

## Success Checklist
- [ ] All success criteria met (with evidence)
- [ ] Lint and unit tests clean (implementation)
- [ ] Heavy checks green when run (review): `make gen` leaves no diff, API image builds
- [ ] Code review approved
- [ ] Documentation updated: PRD §18, §18.1, §18.2, D-70; ARCHITECTURE principle, Layout, rules, AD10; CODE_QUALITY table
- [ ] User: commit (ask where, per CLAUDE.md) and push; open a PR with `Closes #<n>` (issue number from the user)

## Timeline & Estimates
- Implementation: ~0.5 h
- Testing: ~0.25 h
- Review + polish: ~0.25 h
- **Total**: ~1 h

## Open Questions
- [ ] GitHub issue number for the PR (`Closes #<n>`), asked at PR time.

## Implementation Log
- Decision: What to move into apps/api: `db/` → `apps/api/db/`; contract API-owned, mobile keeps its own copy (option 1)
- Decision: Contract file locations: `apps/api/openapi.yaml` + `apps/mobile/openapi.yaml`
- Decision: Copy drift: `make sync-contract` + `make check-contract` in `make lint`/CI
- Decision: Docs: new spec + PRD D-70; specs/01 left as history
- Decision: Root `Makefile` and `compose.yaml` stay at root, only paths change
- Decision: Regeneration identity (`make gen` no diff) is a lean-review heavy check, not an implementation step (skill rule: drift checks belong to review)
- Decision: No `.dockerignore` change and no `apps/web` note (YAGNI, §10.3)
- Decision: workspace: current-branch (main @ 3b8b34f; pre-existing untracked: specs/02-contract-db-ownership.md, which is this spec)
- Decision: checks: none (lint and unit tests not selected; db-reset not run; step 12 drift gate is a plan step, run as written)
- Step 1 — started
- Step 1 — done — files: apps/api/db/** (6 files renamed) — git mv, 6 files listed
- Step 2 — started
- Step 2 — done — files: apps/api/openapi.yaml (renamed) — contracts/ removed
- Step 3 — started
- Step 3 — done — files: Makefile — db-reset paths, sync-contract, check-contract, lint dep, .PHONY
- Step 4 — started
- Step 4 — done — files: apps/mobile/openapi.yaml — copied and git-added, check-contract exit 0
- Step 5 — started
- Step 5 — done — files: apps/api/internal/gen/openapi/generate.go — comment + go:generate path ../../../openapi.yaml
- Step 6 — started
- Step 6 — done — files: apps/mobile/pubspec.yaml — schema_path: openapi.yaml, comment rewritten
- Step 7 — started
- Step 7 — done — files: docs/PRD.md — §18 repo bullets, §18.1, §18.2 step 2, D-70 row
- Step 8 — started
- Step 8 — done — files: docs/ARCHITECTURE.md — principle, Layout (mobile + api, root lines removed), dependency rule, AD10
- Step 9 — started
- Step 9 — done — files: docs/CODE_QUALITY.md — wire contract and database schema rows
- Step 10 — started
- Step 10 — done — files: .claude/skills/lean-planning|lean-implement|lean-review/SKILL.md (untracked) — paths updated, sync-contract added to contract-change text
- Step 11 — started
- Step 11 — done — no files — grep not literally empty, all hits intended: specs/02 (this plan describes old paths; plan's grep only excluded spec 01), docs/ARCHITECTURE.md lines 92-93 (new indented `db/migrations/`, `db/local/` under `apps/api/`), docs/PRD.md D-70 (names superseded locations). No other stale path. git status: 7 renames, new apps/mobile/openapi.yaml, edited Makefile, generate.go, pubspec.yaml, 3 docs
- Step 12 — done — no files — check-contract exit 0; after appended blank line it printed the message and failed (make reports exit 2 wrapping the recipe's exit 1); after sync-contract exit 0
- Handoff — mode: current-branch — branch: main — base: 3b8b34f — checks: none — changed: Makefile, apps/api/openapi.yaml, apps/api/db/local/00_auth_stub.sql, apps/api/db/migrations/0001_user_settings.sql, apps/api/db/migrations/0002_products.sql, apps/api/db/migrations/0003_diary_entries.sql, apps/api/db/migrations/0004_favorites.sql, apps/api/db/migrations/0005_recents.sql, apps/api/internal/gen/openapi/generate.go, apps/mobile/openapi.yaml, apps/mobile/pubspec.yaml, docs/PRD.md, docs/ARCHITECTURE.md, docs/CODE_QUALITY.md, specs/02-contract-db-ownership.md — preexisting: none (spec was untracked) — checkpoints: 4/4
