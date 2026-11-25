---
name: lean-review
description: Review Lean Tracker code (also `/lean-review specs/<task-name>.md` in a fresh session: scope, mode and branch come from the spec's Handoff line; findings are saved to the spec's `## Review` section and a fix round can start in a fresh context) for correctness, quality, performance, security, accessibility and test coverage across the Flutter app, the Go API, the OpenAPI contract and SQL migrations. Triggers on "review", "check this code", "code review", "/review" — whenever user wants feedback on uncommitted changes. Reviews staged files, modified files, or user-specified files. Reports all findings ranked by severity (critical first) with suggested fixes. Checks changes against docs/PRD.md, docs/ARCHITECTURE.md and docs/CODE_QUALITY.md. Does NOT auto-fix; user decides whether to apply suggestions.
compatibility: Reads git status (or user-named files when not a git repo), reviews uncommitted changes (apps/mobile/, apps/api/, contracts/openapi/, db/migrations/, .github/workflows/) either in the task's git worktree (`.claude/worktrees/<task-name>`, branch `feature/<task-name>`) or on the current branch (asked, never assumed), explores project codebase. Always asks which checks to run; never runs or writes Flutter integration tests (that is `lean-e2e`)
---

## When to Use This Skill

Use when user explicitly says: "review this", "code review", "check my code", "find issues", "review changes", or "/review".

This skill reviews uncommitted code changes and provides feedback on:
- **Bugs & Correctness**: Logic errors, crashes, edge cases, wrong nutrition math (BR-006), wrong day or time zone handling (BR-004), recents not capped at 20 or not unique (BR-010), the weekly average counting empty days (BR-015), snapshot not copied or entries changing with their product (BR-007), soft delete not propagated, last-write-wins resolved the wrong way, unit `serving` without `serving_size`, `async` gaps with a disposed `BuildContext`, undisposed controllers, streams or the camera, Go goroutine leaks and unclosed bodies
- **Code Quality**: DRY violations, simplification opportunities, readability, types (`dynamic`, `!` without reason, unchecked casts, `panic`)
- **Performance**: local save ≤ 300 ms (NFR-002), barcode lookup p95 ≤ 4 s (NFR-001), N+1 queries in sync pulls or search, unbounded lists, heavy work in `build`, cold start ≤ 3 s (NFR-003), unneeded rebuilds, large Drift reads on the UI isolate
- **Security**: missing JWT check, query without `user_id`, upsert that can overwrite another user's row, trusted client `updated_at`, `SELECT *` leaking columns, unbound SQL, unvalidated input or barcode in a URL (SSRF/path), shared-product visibility leaks, service role key outside `account/infrastructure`, secrets or `.env` in the repo, passwords/JWTs/emails/diary data logged, secrets in the app bundle, tokens outside secure storage
- **Tests**: Missing test coverage, untested branches, test gaps for new functionality, acceptance criteria from the PRD with no test, business-rule tests that need network, database or widgets (NFR-008)
- **Docs conformance**: Violations of `docs/PRD.md` (business rules, FRs, NFRs, UI strings, data model, stack, decisions), `docs/ARCHITECTURE.md` (principles, layers, layout, dependency rules, cross-layer flow, decisions) and `docs/CODE_QUALITY.md` (principles, single sources of truth, working agreements, checklist), and any of them left stale by the change

## Workflow

### Phase 0: Scope & Discover

Determine what to review:

0. **Ask where to review, and which checks**: never assume. `<repo>` is the main checkout; read this skill and any other skill by absolute path from `<repo>`. `<work>` is the directory under review:
   - **Spec argument** (`/lean-review specs/<task-name>.md`, usually in a fresh session after `lean-implement`): there is no conversation history, so the spec is the only input. Read the live spec (`<repo>/.claude/worktrees/<task-name>/specs/<task-name>.md` if it exists, else `<repo>/specs/<task-name>.md`) and take the LAST `Handoff` line of its `## Implementation Log`: `mode`, `branch`, `changed` (the review scope), `preexisting` (ignore), `checks`. Do not make the user retype any of it. Still ask, in ONE `AskUserQuestion`, where to review and which checks, with the Handoff's mode as the first option marked "(Recommended)" and its `checks` preselected as recommended (the user decides every run). Verify `git -C <work> branch --show-current` equals the Handoff `branch`; on mismatch, or if a `changed` file is unchanged on disk, say so before reviewing. No `Handoff` line (implementation unfinished, older spec): say so and fall back to the questions below. Mode `in-place` or a directory that is not a git repository: review the files in `changed` (or the ones the user names) in the project root, skip the workspace question
   - If the prompt passes a path (a worktree or file list) or the user named one, use it and say so
   - Otherwise run `git worktree list` and ask with `AskUserQuestion`: each `feature/*` worktree as an option (`<repo>/.claude/worktrees/<task-name>`, branch `feature/<task-name>`) plus "Current branch `<branch>` (main checkout)". With no `feature/*` worktree, still ask whether to review the current branch's uncommitted changes or a PR/branch the user names
   - The checks question comes from "Automated checks" below (ask it in the same `AskUserQuestion` call; skip only when the prompt already carries the answer)

   Never create, switch or remove branches or worktrees, and never edit code or docs (the one allowed write is the `## Review` section of the spec, Phase 5). Run every git command as `git -C <work>` and read files under `<work>`, including `docs/` and the spec copy `<work>/specs/<task-name>.md` (in worktree mode the main checkout's spec copy is not ticked). Scope is `<work>`'s uncommitted changes (in current-branch mode ignore files that were already modified before the task if the prompt lists them), the PR diff when the user names a PR, or the files the prompt names
1. **Check git status**: In the worktree, are there staged files? Modified files? Untracked files? If the directory is not a git repo, ask which files to review
2. **Ask if needed**: "Should I review staged changes, all modified files, or specific files you mention?"
3. **Read the docs**: `docs/PRD.md` (business rules §5, processes §6, user flows and UI strings §11, FRs and acceptance criteria §12, data model §13, auth §14, integrations §15, platforms and UI §16, NFRs §17, stack and architecture §18, decisions §20, future scope §23), `docs/ARCHITECTURE.md` (layout, dependency rules, invariants, errors, testing weights, deployment, decisions, open items) and `docs/CODE_QUALITY.md` (principles, single sources of truth, working agreements, review checklist, known debt). This defines what "correct" means for this project; the review is measured against them. For UI changes, compare against the DESIGN.html board the spec names (4 MB bundle: search it, do not Read it whole)
4. **Explore project**: Read existing code to understand patterns, conventions, neighbouring files
5. **Set context**: Note which area(s) the change touches (`apps/mobile/lib/<module>/<layer>`, `apps/api/internal/<module>/internal/<layer>`, `contracts/openapi`, `db/migrations`, workflows, config)

### Phase 1: Review Uncommitted Changes

Before reading files, start the automated checks in the background (see "Automated checks" below) and review while they run.

For each file in scope:

1. **Read the file**: Understand what changed and why
2. **Check against patterns**: Compare against existing project patterns
3. **Analyze for issues**: Look for bugs, quality problems, perf issues, security flaws, test gaps
4. **Check against the docs**, rule by rule (each is a documented, non-subjective standard). Cite PRD ids for product rules, and ARCHITECTURE.md / CODE_QUALITY.md section names for structure and quality rules:
   - **ARCHITECTURE.md**: layout matches §Layout; dependency rules hold (`domain` and `application` free of framework, SQL, plugins and `ui/`; a module reached only through its public file; `presentation` never touches Drift, the API client or a plugin; `app/` and `cmd/api` are the only places that wire implementations; `apps/mobile` and `apps/api` import nothing from each other; nothing created under `apps/web`); errors cross layers as typed domain errors and are mapped only in `transport`; decisions AD1+ not contradicted
   - **PRD product rules**: isolation, shared products, snapshot, nutrition, validation, day boundary, recents, sync, offline matrix, barcode order, OFF mapping, auth, database access, account deletion, reminders, secrets, no tracking, localization (PRD §5, §12–§15, §17, §18.2); error codes from the closed `ErrorCode` list in `contracts/openapi`
   - **CODE_QUALITY.md**: KISS and YAGNI (no dependency or abstraction the platform already covers, nothing from PRD §10.3 or §23); DRY against the single-sources table (no duplicate rule values, field limits, texts or types; mirrored limits equal the OpenAPI file); separation (rules not in widgets, handlers or SQL); no `dynamic`, unchecked casts or unexplained `!`; cleanup; nothing sensitive logged; ARB keys instead of literals
   - **Isolation and sharing (BR-001, BR-009)**: every query on a user table filters by the JWT user; upserts of a client `id` constrained by owner; shared products only through `is_shared` methods; `is_shared = false` hides the product from others; deleting a product leaves entries
   - **Entries (BR-003 to BR-007, FR-003, FR-004, FR-010)**: ranges, one decimal, meal set fixed, units, formula, snapshot, editing only quantity, unit, meal, date; copy meal creates new ids and `updated_at = now`; totals and remaining kcal with a minus sign
   - **Products and lookup (BR-008, BR-009, FR-005 to FR-008)**: lookup order, barcode 8–13 digits validated, `OFFLINE_LOOKUP_UNAVAILABLE`, OFF mapping and 5 s timeout, ≤ 30 results in the right order, own-product form pre-filled on not found, form errors with the exact texts
   - **Favorites, recents, summary (BR-010, BR-015, FR-009, FR-011)**: 20 unique recents by last use, last quantity and unit, 7-day window, empty days 0 in the chart and excluded from the average, `—` when all empty
   - **Sync and offline (BR-014, FR-013)**: local write first, `id` UUID v4, `updated_at`, `deleted_at`, last-write-wins, future `updated_at` bounded, deletion propagated, matrix of what works offline, sync within 30 s of network return
   - **Auth and account (§14, FR-001, FR-016, BR-017)**: JWKS signature, `exp`, `aud` on every endpoint but health; `sub` as user id; refresh token in secure storage; deletion removes rows and the Auth user, re-auth first, local database cleared; service role key only in `account/infrastructure`
   - **Reminders (BR-016, FR-012)**: 0–3, local only, fixed text in PL/EN, permission-denied message with settings link
   - **Limits**: rule values in `kernel/limits` and the OpenAPI schemas, not inline magic numbers
   - **UI (§16, FR-017, UF-001–UF-006)**: layout and tokens match the DESIGN.html board, no color or font literal outside `lib/ui/`, strings via ARB with the exact PRD texts (EN + PL), `Semantics` on interactive elements, 360 dp, font scale 200%, contrast, light and dark from the system, empty, error and offline states
   - Does the change touch anything the docs describe (PRD rules, FRs, data model, stack; ARCHITECTURE layout, modules, dependency rules, decisions, open items; CODE_QUALITY single sources, known debt) without updating them? Does it contradict a row of the PRD decisions log (§20) or ARCHITECTURE decisions?
5. **Categorize findings**: Critical, Warning, Suggestion, Nitpick

### Phase 2: Evaluate Findings

For each finding:

1. **Assess severity**:
   - **Critical**: Crashes, auth bypass (missing JWT check), another user's data readable or writable, SQL injection, shared-product leak after `is_shared = false`, service role key or other secret leaked or logged, data loss beyond the documented deletion, last-write-wins that lets a future `updated_at` win forever, account deletion that leaves rows
   - **Warning**: Code smell, performance problem, missing test, rule violation affecting readability, boundaries, a11y, localization or exact texts
   - **Suggestion**: Simplification opportunity, edge case, minor optimization
   - **Nitpick**: Style preference, comment clarity (low priority)

2. **Provide evidence**: Show exact line/code causing the issue
3. **Suggest fix**: Offer code snippet or refactoring approach
4. **Explain why**: Why this matters and what happens if ignored

### Phase 3: Report Findings

Collect the background check results first; a failing check is a finding (Critical if it breaks the build, Warning otherwise), cited with the tool's exact error. Don't wait idle: if a check is still running when the review is done, report the review and say which checks are pending.

Report ONLY findings that are either:
- **Objectively wrong** (logic error, crashes, security flaw)
- **High-impact** (perf problem, missing critical test, architectural inconsistency)
- **A clear violation of a rule written in a project doc** (cite the id or section, e.g. `BR-001`, `FR-013`, `NFR-008`, `ARCHITECTURE.md §Dependency rules`, `CODE_QUALITY.md › DRY`), or a doc section left stale by the change. A documented rule is not a style preference. Default severity: Warning; Critical only if it also breaks behavior

Do NOT report:
- Subjective style preferences (unless the lint config enforces them)
- Single-line cleanups that don't affect readability
- Theoretical edge cases unlikely to occur in practice

**Format findings as:**
````
## [CRITICAL] Issue Name

**File**: apps/api/internal/diary/internal/infrastructure/entries_repo.go:45
**Rule**: (only for PRD violations) BR-001
**Issue**: Entry upsert does not constrain the owner
**Evidence**: `INSERT ... ON CONFLICT (id) DO UPDATE SET ...` without `WHERE diary_entries.user_id = $1`
**Suggested Fix**:
```sql
INSERT INTO diary_entries (...) VALUES (...)
ON CONFLICT (id) DO UPDATE SET ... WHERE diary_entries.user_id = $1
```
**Why**: BR-001: a user must be able to write only their own data.
**Risk if ignored**: a client that sends another user's entry id overwrites that user's entry.
````

### Phase 4: Suggest Fixes (Don't Apply)

For each finding:
1. Show the problematic code
2. Show what it should be
3. Explain the fix (1-2 sentences)
4. Do NOT modify the actual file (user decides if they want to apply it)

### Phase 5: Save Findings to the Spec, Then Advance

The fix stage runs in a fresh context, so findings must live in the spec. This is the only edit the skill makes, and only to the live spec (`<work>`'s copy), never to code:

1. Replace any earlier `## Review` section (or append one at the end) with a header line `Reviewed <date> — checks run: <list or none>` and one line per finding, ranked Critical first: `R1. [ ] [CRITICAL] <title> — <file:line> — <one-line suggested fix>`. The full write-up (evidence, why, risk) stays in the chat report; the spec line must be enough to act on. No findings: write `No findings.` and no `R` lines
2. Skip the write when the spec file cannot be found (no spec argument, inline review); say so
3. **Next command.** A skill cannot clear this conversation and does not start the fix stage. The user runs it in a fresh session that sees only the spec:
   - **Findings exist**: print `/lean-implement specs/<task-name>.md fix` (run it after `/clear` or in a new session; it asks which findings to fix, where to work and which checks to run; `fix R1 R3` names findings up front). Then `/lean-review specs/<task-name>.md` again re-checks. Do not invoke `lean-implement` yourself. Nitpick/Suggestion only: say fixing is optional
   - **No findings**: no question. Say "Nothing to fix. Commit is yours (worktree mode: in the worktree, then merge `feature/<task-name>`)"

**Commit guidance (if user later commits):** Conventional Commits, short subject (≤50 chars, imperative), no body, no co-author line

### Automated checks (background subagents, never in the main thread)

**Ask which checks to run, every review.** Use `AskUserQuestion` (multi select) with the rows below that apply to what changed; mark the cheap ones (lint, architecture, unit tests) as recommended. Run exactly what the user selects, nothing more. "None" is valid: then say in the report that no checks ran.

**Integration tests are never offered, run or written here.** Flutter `integration_test/` belongs to the `lean-e2e` skill. If the user asks for them in a review, point to `/lean-e2e` and do not run them. Missing integration coverage for a changed flow may be a finding (suggest `/lean-e2e`), but this skill writes no test.

Run every selected checker in its own background subagent (Agent tool, `subagent_type: "general-purpose"`; subagents run in the background and notify on completion) so the main thread keeps working and the user is never blocked. Launch all in ONE message so they run in parallel. Targets come from the root `Makefile` and the app manifests; if one does not exist yet, the subagent reports that instead of inventing one. Every command runs in `<work>`: give the subagent its absolute path, and have it run `flutter pub get` / `go mod download` there first if dependencies are missing.

| Checker | Command | Offer when |
|---|---|---|
| Lint | `make lint` | always |
| Architecture | `make arch` | always |
| Unit tests | `make test` (Go and Flutter) | always |
| Contract drift | `make gen`, then `git -C <work> status --short` shows no change in generated files | `contracts/openapi`, `lib/gen/` or generated Go code changed |
| Go build | `go build ./...` in `apps/api` (and `docker build` is not run) | `apps/api` changed |
| Flutter build | `flutter build apk --debug` in `apps/mobile` (slow) | `apps/mobile`, `pubspec.yaml` or native config changed |
| Migrations | apply `db/migrations/*.sql` in order to a throwaway local Postgres (docker or `supabase start`), never the hosted project | `db/migrations/` changed |

The Migrations subagent may start a local database container and must stop and remove it before reporting. No subagent deploys, runs `supabase db push`, uses a hosted `--db-url`, uploads a build or reads `.env` aloud.

Subagent prompt rules:
- Run the one command only, from `<work>`'s root. Do NOT edit files, fix errors, or commit.
- If a tool or target is missing (`flutter`, `go`, `docker`, `golangci-lint`, `go-arch-lint`, a Makefile target), report that instead of installing or creating it.
- Report back in <=10 lines: PASS/FAIL, and for FAIL the exact error lines with `file:line`. No full logs.

Main thread: keep going and do not poll or sleep. Results arrive as notifications; fold them into the final report. On FAIL, report it plainly with the errors. This skill never fixes.

## Scoping Rules

**Review these files:**
- Staged files (git add)
- Modified files since last commit (git status)
- Files user explicitly names ("review apps/api/internal/products/internal/domain/off_mapping.go")

**Don't review:**
- Unchanged files
- Deleted files (unless they broke something)
- Lockfiles (`pubspec.lock`, `go.sum`), `build/`, `.dart_tool/`, `.gradle/`, `Pods/`, `*.g.dart`, `*.freezed.dart`, `lib/gen/`, generated Go code (review the OpenAPI file that produces them instead)
- Generated l10n output (review the ARB files)
- Anything outside the repo
- `docs/DESIGN.html` (reference material), unless the user asks

## What Good Looks Like

**Good code review:**
- Finds real bugs (not hypothetical)
- Explains why it matters
- Suggests actionable fixes
- Ranked by severity (critical first)
- Aware of project patterns and holds the change to the written rules in the three docs (cites the id or section)
- Doesn't nitpick trivial things

**Weak code review:**
- Complains about style without context
- Finds issues but no fixes suggested
- All findings treated equally (not ranked)
- Doesn't know the layer and module rules, the isolation rule or the offline and sync model
- Too many low-value findings (drowns out real issues)

## Integration with lean-implement

This skill works standalone. However:
- If code came from lean-implement skill, review will focus on implementation quality and plan fidelity
- If code came from user edits, review will check correctness and patterns
- Can review partial implementations or work-in-progress code

The skill doesn't require lean-implement to have run first—any uncommitted code can be reviewed.
