---
name: lean-implement
description: Execute implementation plans for Lean Tracker by writing Dart/Flutter code (modules with domain, application, infrastructure, presentation layers, Drift), Go API code (modules with domain, application, infrastructure, transport), the OpenAPI contract, SQL migrations and unit tests. Always asks the user first where to work (own git worktree on a `feature/<task-name>` branch, or the current branch) and which checks to run (lint, architecture, unit tests); never runs or writes Flutter integration tests (that is the `lean-e2e` skill). Builds and contract-drift checks are left to lean-review. Triggers on "implement", "code this up", "build this", "start coding" — whenever user wants to turn a plan into working code. Consumes plans from specs/ directory or inline. Reads docs/PRD.md, docs/ARCHITECTURE.md and docs/CODE_QUALITY.md first and follows them. Works one step at a time and updates the spec (step checkbox, implementation log) after every step, so work can be stopped and resumed in another session from the spec alone. Does not commit, deploy or touch the hosted Supabase project.
compatibility: Reads from specs/ directory, edits project files (apps/mobile/, apps/api/, contracts/openapi/, db/migrations/, .github/workflows/ when the plan says so) either inside a git worktree under .claude/worktrees/ or on the current branch of the main checkout (user's choice, asked every run), matches existing code style
---

## When to Use This Skill

Use when user explicitly says: "implement X", "code this up", "build X", "start coding X", or "let's build X". After a plan is ready (from lean-planning skill or external plan), use this skill to execute it.

This skill is NOT for code review, testing strategy, or planning—it's for turning plans into working code.

## Workflow

### Phase 0: Locate & Parse Plan

Find the plan to implement. `<task-name>` is the spec file name without `.md`. `<work>` is the directory code is written in, chosen in Phase 0b: the worktree `<repo>/.claude/worktrees/<task-name>` (worktree mode) or `<repo>` itself (current-branch mode). If `<repo>/.claude/worktrees/<task-name>/specs/<task-name>.md` exists, that copy is the live one (it holds the ticks) and every spec read or edit below goes to it; otherwise read the main checkout's spec. Run Phase 0b before editing anything.
0. If invoked with a spec path argument (first run, manual resume line or fix round: `/lean-implement specs/<task-name>.md [from CP<n> | fix]`; `fix` is described below), use exactly that file. Read it fully, do not search for another. `from CP<n>` means skip checkpoints before `CP<n>`; with no `from`, start at the first unticked checkpoint (all unticked = start at CP1). If the path does not exist, say so and stop — do not fall back to a guess
1. Otherwise check `specs/` directory for markdown file matching task name
2. If no file found, ask user to provide plan (inline or file path)
3. Parse plan structure: extract implementation steps, **checkpoints (todo list)**, file changes, code examples, architecture
4. If the plan has no `## Checkpoints (Todo List)` section (older plan or inline plan from a file), add one to the spec file before coding: 3-7 `- [ ]` checkpoints grouping the steps, each with its closing evidence. For an inline plan with no file, track checkpoints in the summary only
5. **Make steps trackable.** Every item under `## Implementation Steps` must be a checkbox line: `1. [ ] Add ...`. If the spec has plain numbered steps, convert them in place (add `[ ] `, change nothing else). If the spec has no `## Implementation Log` section, append an empty one at the end (format under Phase 3). For an inline plan with no file, offer to save it to `specs/<task-name>.md` first, since resuming needs the file
6. **Resume check.** The spec is the only memory between sessions. Work out where the last session stopped:
   - First unticked step `[ ]` = where to continue. Steps already `[x]` are done: do not redo them
   - A log line `Step N — started` with no `Step N — done` means that session stopped mid-step. Look at the files the log names (`git -C <work> diff` / `git -C <work> status`, or just read them) and finish the step from what is already there. Never rewrite it from scratch
   - Trust but verify: for the last 1-2 `[x]` steps, confirm the named files exist and contain the change. If a ticked step is not actually in the tree, say so, untick it, and redo it
   - Read the `Implementation Log` for notes from earlier sessions
   - Tell the user in 2-3 lines: "Resuming `specs/<task>.md`: steps 1-4 done, continuing at step 5 (CP2)"

**Fix mode** (`/lean-implement specs/<task-name>.md fix`, run by the user after a review): the spec has a `## Review` section appended by the reviewer, with lines `R1. [ ] [CRITICAL] <title> — <file:line> — <suggested fix>`. Do not re-implement the plan. Which findings to fix: if the prompt already names them (for example `fix R1 R3`), use exactly those; otherwise ask the user (one `AskUserQuestion`, multi select, Critical and Warning preselected as recommended). Copy each chosen one into `## Implementation Steps` as the next numbered step (`N. [ ] Fix R<k>: ...`) plus one closing checkpoint `- [ ] CP<m> — Review fixes: steps N-M; selected checks green`, then run the normal loop on those steps only. When a fix is done, tick both the step and its `R<k>` line, and log it. Phase 0b (workspace, checks) still applies; reuse the `Handoff` line's mode as the recommended default.

If plan is ambiguous or incomplete, ask user to clarify BEFORE starting coding.

### Phase 0b: Ask Where to Work and Which Checks to Run

Do this before the first edit (and before Phase 1). Never assume either answer.

Names: `<repo>` = main checkout root (`git rev-parse --show-toplevel`; from inside a linked worktree, the parent of `git rev-parse --path-format=absolute --git-common-dir`). Worktree `<wt>` = `<repo>/.claude/worktrees/<task-name>`, branch `feature/<task-name>`. `<work>` = `<wt>` (worktree mode) or `<repo>` (current-branch mode).

**Not a git repository yet** (`git rev-parse` fails): skip the workspace question, work in place in the project directory (`<work>` = `<repo>` = the project root), say so in one line, and suggest the owner runs `git init` before the first commit. Every `git -C` step below is skipped; the "pre-existing work" note is replaced by listing the files you created and changed.

**0. Ask the user** with ONE `AskUserQuestion` call holding two questions:

1. **Workspace** (single select): "Own git worktree `feature/<task-name>` (isolated, main checkout untouched)" or "Current branch `<branch>` (edit the main checkout directly)". Name the real current branch in the label. Skip this question only when the prompt that invoked you already carries the answer, when resuming and `<wt>` exists or the log has a `Decision: workspace` line (then state the mode you are continuing in), or when the directory is not a git repository
2. **Checks** (multi select, none required): Lint (`make lint`), Architecture (`make arch`), Unit tests (`make test`: Go and Flutter). Offer exactly these; do NOT offer integration tests, builds or contract drift (see "Automated checks"). If the user types an Other answer naming integration tests, do not run them: point to `/lean-e2e`. Skip only when the invoking prompt already carries the answer. Ask again every run, even on resume (earlier choice may be the recommended default)

Record both answers in the spec's `## Implementation Log` (in `<work>`'s spec copy) as `- Decision: workspace: worktree|current-branch|in-place` and `- Decision: checks: <list or none>`. "None" is valid: then run no automated checks and say so in the final summary.

**Worktree mode**

1. **Reuse or create**: `git -C <repo> worktree list`.
   - `<wt>` listed (resume): reuse it. Its branch (`git -C <wt> branch --show-current`) must be `feature/<task-name>`; if not, stop and ask
   - Not listed, branch `feature/<task-name>` exists: `git -C <repo> worktree add <wt> feature/<task-name>`
   - Neither exists: `git -C <repo> worktree add -b feature/<task-name> <wt> HEAD`. Base is the main checkout's `HEAD`, not `origin`. Do not use `EnterWorktree` (it branches from `origin` by default)
2. **Note the base**: current branch and short SHA of `<repo>` (`git -C <repo> branch --show-current`, `git -C <repo> rev-parse --short HEAD`); report them. Check `git -C <repo> status --short`: uncommitted work in the main checkout is invisible in the worktree. If the plan touches or relies on it (or on a dependency branch not merged yet), ask the user how to proceed before coding (commit or merge it first, or go on without)
3. **Copy the spec**: for a new worktree, copy `<repo>/specs/<task-name>.md` to `<wt>/specs/<task-name>.md` (overwrite: it may be untracked or newer than `HEAD`). For a reused worktree keep its copy, since it holds the ticks; if the main copy was revised after the worktree was created, tell the user and ask which to keep
4. **Local env**: if `<repo>/apps/api/.env` or `<repo>/apps/mobile/env/local.json` exists and the worktree lacks it, copy it with `cp` (git-ignored). Never print, read aloud or commit its contents. Do not start Supabase or a database unless a selected check needs one, and then only a local one: never connect to the hosted project
5. **Install dependencies**: `flutter pub get` in `<wt>/apps/mobile` and `go mod download` in `<wt>/apps/api` (only for the apps the plan touches, and only if their manifest exists). This is the only setup command to run besides step 4; do not build
6. **Work only in `<wt>`**: every Read/Edit/Write path is under `<wt>`; every Bash command starts with `cd <wt> &&` or uses `git -C <wt>`. Never edit the main checkout, its spec copy included (it stays stale until the branch is merged). Read the `lean-*` skills by absolute path from `<repo>`. Read `docs/` from `<wt>`

**Current-branch mode**

1. **Note the branch**: `git -C <repo> branch --show-current` and short SHA; report them. Do not create, switch or reset branches. If the branch is `main` (or the default branch), say so in one line before coding
2. **Note pre-existing work**: `git -C <repo> status --short` before the first edit and keep that list. Those files are not yours: leave them alone, and exclude them from the `CHANGED:` list unless the plan edits them (then say so)
3. **Spec**: edit `<repo>/specs/<task-name>.md` directly (no copy)
4. **Install dependencies**: `flutter pub get` / `go mod download` only if the dependency directory is missing or the plan adds a dependency
5. **Work only in `<repo>`**: every Bash command starts with `cd <repo> &&` or uses `git -C <repo>`

Never commit, merge, push, switch branches or remove a worktree, in either mode. Never run `gcloud`, `supabase db push`, `supabase link`, any command with a hosted `--db-url`, or anything that deploys or uploads a build. The user commits (in the worktree, or on the current branch), merges and releases.

### Phase 1: Light Questions (Critical Unknowns Only)

**The plan is the source of truth.** Implement what it says; don't second-guess it, don't fill its gaps with your own ideas. If something is unclear or the plan doesn't cover it, ask the user with the `AskUserQuestion` tool (concrete options, one question per decision) instead of guessing.

Ask ONLY if the plan leaves critical gaps:

- **File location**: "Plan says 'add recents trimming' but not where. Assume `apps/mobile/lib/favorites_recents/domain/` for the rule and the Drift DAO in `infrastructure/`?"
- **Dependencies**: "Plan needs a date picker but `pubspec.yaml` has none. Use the Flutter SDK's `showDatePicker`, or add a package?"
- **Naming conflicts**: "`entries_repo.go` already exports `ListByDate`. Extend it or add a new function?"
- **API shape**: "Plan adds `PUT /v1/settings` but not its body. The four goals as integers?"

Do NOT ask for things the plan already specifies. Do NOT ask for subjective preferences (naming, formatting). Those are covered by existing code and the lint config.

### Phase 2: Prepare Environment

Before coding:
0. **Read the docs first**, all three, as binding constraints:
   - `docs/PRD.md`: business rules (§5), processes (§6), user flows and exact UI strings (§11), functional requirements and acceptance criteria (§12), data model (§13), auth (§14), integrations (§15), platforms and UI (§16), NFRs (§17), stack and architecture (§18), decisions log (§20), future scope (§23, not built)
   - `docs/ARCHITECTURE.md`: layout, dependency rules, invariants, errors, testing, deployment, decisions AD1+, open items
   - `docs/CODE_QUALITY.md`: principles, single sources of truth, working agreements, review checklist

   Which app, module and layer each change belongs in, the rules the code must satisfy. If the plan conflicts with any of them, stop and ask (Phase 4) instead of silently picking a side.
1. **Explore existing code**: Read relevant folders to understand current structure, patterns, imports. If the area has no code yet, follow ARCHITECTURE.md §Layout (and PRD §18).
2. **Match style**: Examine existing code for:
   - Naming and exported API (few exports, typed; the module's public file exports only what others need)
   - Error handling (closed error codes from ARCHITECTURE §Errors, typed domain errors, not message strings)
   - Test structure (names state the rule and cite BR-/FR-; table-driven in Go)
   - Flutter conventions (view models hold state, widgets send intents, ARB keys instead of literals, `Semantics` on interactive elements)
3. **List dependencies**: Note new packages the plan requires; add them to `pubspec.yaml` / `go.mod`. Mind CODE_QUALITY's KISS rule and the owner-approval rule for anything outside PRD §18
4. **File map**: Create mental map of files to create vs modify, per app and module (`apps/mobile/lib/<module>/...`, `apps/api/internal/<module>/...`, `contracts/openapi/`, `db/migrations/`, tests) plus config

### Phase 3: Execute Implementation Steps

Follow the plan's numbered steps exactly, one at a time, starting at the first unticked step (Phase 0 resume check). The user may stop at any point and continue in another session, so the spec must be true after every step: never batch several steps into one spec update, never tick ahead, never leave a finished step unticked.

**The loop, for each step N:**

1. **Read the step** — understand what code/resource to create
2. **Mark started** — append to the `## Implementation Log` in the spec: `- Step N — started`. Do this before touching code, so a stopped session leaves a trace
3. **Implement** — write code, create files, modify existing files
4. **Match style** — follow project conventions (use existing code as template)
5. **Use plan examples** — if plan provides code examples, adapt them; don't rewrite from scratch
6. **Quick check** — in `<work>`, run only the checks the user selected in Phase 0b, scoped to what the step touched (`flutter test test/<path>`, `go test ./internal/<module>/...`, `make lint`, `make arch`, or the equivalent targets). Fast, in the foreground. Failing in code this step just wrote → fix it. Do not tick a step whose selected checks fail. If the user selected none, skip this. **Never run integration tests or other heavy checks here** (see "Automated checks" below)
7. **Update the spec now**, before starting step N+1:
   - tick the step: `N. [ ]` → `N. [x]`
   - append to the log: `- Step N — done — files: <paths created/modified> — <one-line note: what was done, any deviation, any follow-up>`
   - if the step closed its checkpoint, do the checkpoint update below
8. **Next step.** No pause between steps unless a question is open or the user stopped you. If the user stops you mid-step, make the spec true first: leave the step unticked, log what is done and what remains (`- Step N — stopped — done: ..., left: ...`)

**Implementation Log format** (appended at the end of the spec, one line per event, newest last):

```
## Implementation Log
- Step 1 — started
- Step 1 — done — files: apps/mobile/lib/diary/domain/nutrition.dart, apps/mobile/test/diary/domain/nutrition_test.dart — BR-006 formula, 9 cases
- Step 2 — started
```

**Checkpoint progress (update the spec after every checkpoint):**

When the last step of a checkpoint is done, update the plan's todo list in `specs/<task-name>.md` before starting the next checkpoint:

1. Launch the checkpoint's closing checks as background subagents (see "Automated checks"; only checks the user selected in Phase 0b and its evidence names, e.g. the test files of the touched module). If a checkpoint's evidence names a check the user did not select, or a heavy check (integration tests, build, contract drift), do not run it: tick the checkpoint on the evidence actually obtained, note `— <check> not run (not selected|deferred to review)`, and keep going. Keep implementing the next checkpoint; do not wait or poll
2. When a check reports PASS and the checkpoint's evidence is met, tick it: `- [ ]` → `- [x]`, and append a short note if useful (e.g. `— 12 tests green`)
3. On FAIL, leave the box unchecked and add `— FAIL: <file:line, one line>`. Fix it if the failure is in code this skill just wrote, then re-run and tick; otherwise report it plainly
4. If steps change mid-way (a step is split, skipped with user approval, or reordered), edit the checkpoint text to match. Never tick a box whose evidence was not actually obtained
5. The spec edits you may make: step and checkpoint checkboxes (plus their short notes), the `## Implementation Log`, and the one-time conversions in Phase 0. Leave the rest of the spec untouched

**Key principles:**
- **Follow the docs**: put each change in the app, module and layer ARCHITECTURE.md §Layout says it belongs in, and respect its dependency rules. `domain` and `application` import no framework, SQL, plugin, `ui/` or other module internals; a module reaches another only through its public file; `apps/mobile` and `apps/api` import nothing from each other and meet only in `contracts/openapi`. SQL only in the API's `infrastructure/`; Drift, `supabase_flutter` and plugins only in the app's `infrastructure/`. Apply CODE_QUALITY.md while writing: single source of truth, small units, no speculative code
- **Contract first**: a new or changed route starts in `contracts/openapi/openapi.yaml` (schemas with limits, status codes, `ErrorCode`), then `make gen`, then the code. Never edit `lib/gen/` by hand
- **Isolation (BR-001, §14)**: every repository method on a user table takes the user id and filters by it; an upsert of a client-supplied `id` cannot overwrite another user's row; shared products are read only through the `is_shared` methods; no `SELECT *`
- **Auth and input (FR-001, NFR-004)**: every endpoint except health sits behind the JWT middleware; every body, path and query value is validated against the contract at `transport`; every SQL statement uses bound parameters
- **Snapshots and units (BR-006, BR-007)**: an entry copies name, base unit, per-100 values and serving size; the formula lives only in `diary/domain`; `serving` only with `serving_size`; no g↔ml conversion
- **Offline and sync (BR-014, FR-013)**: write to Drift first; every syncable row has `id` (client UUID v4), `updated_at`, `deleted_at`; deletes are soft; last `updated_at` wins; the server bounds a future `updated_at`
- **Constants**: rule values live in `kernel/limits` (mirrored in both apps and held equal to the OpenAPI file by a test), not inline
- **Migrations**: a new schema change is a new numbered file in `db/migrations/` (RLS on, no policies for `anon`/`authenticated`, grants for the API role); never edit a migration that may already be applied. Drift schema changes bump the Drift schema version and add a migration step
- **Secrets**: only via env or `--dart-define-from-file`; never hardcoded, logged or written to tracked files; only `*.example` files (no real values) are tracked; the app holds only the Supabase anon key and URL
- **i18n and a11y**: every user-facing string is an ARB key (EN + PL) with the exact text of PRD §11; `Semantics` on interactive elements; 360 dp minimum width, font scale up to 200%, light and dark from the system theme
- **Be literal**: If plan says "add field `is_shared` to products", add exactly that column, schema field and type, not a second name for it
- **Complete steps**: Each step should be independently functional if possible; don't create stubs
- **Preserve existing**: Don't refactor unrelated code; only change what the plan asks for
- **New files**: Create them with full content, not skeleton. Add tests with the code (unit tests, fake `Clock` and `Uuid`, no network, no sleeps). Write no Flutter integration tests, even if the plan lists some: skip them, log `integration test skipped (lean-e2e)` and name them in the summary for `/lean-e2e`
- **Stay in scope**: edit only files the plan names, plus the spec (checkboxes and log) and docs the change makes stale. Leave pre-existing uncommitted work alone. Nothing from PRD §10.3 or §23
- **Dependencies**: Add to `pubspec.yaml` / `go.mod`; run `flutter pub get` / `go mod tidy` only if the plan adds a dependency

### Phase 4: Handle Unknowns

If you encounter something the plan doesn't specify clearly:

1. **Check the plan first**: it is the source of truth. Then the PRD, then ARCHITECTURE.md and CODE_QUALITY.md, then existing code: Does the codebase have a similar pattern? Use it
2. **Make assumptions explicit**: Add a short comment pointing to the plan section or rule id: `// Recents keep the 20 newest unique products (BR-010)`
3. **If still unclear**: STOP and ask the user with the `AskUserQuestion` tool. Do NOT guess on critical decisions.

**Don't guess on:**
- API routes, request/response shapes, status and error codes, sync protocol
- Exact numbers and rules the PRD specifies (goal 500–10000 and 0–1000, quantity 0.1–10000 with one decimal, per-100 ranges, 20 recents, 30 search results, 3 reminders, 7 summary days, 5 s OFF timeout, barcode 8–13 digits, password ≥ 8, field lengths); reproduce them exactly
- Exact Polish and English texts of PRD §11 and the reminder text
- State transitions (product private ⇄ shared, soft delete, session)
- Anything that changes who can see or do what (another user's data, shared products)
- Anything that adds cost, tracking, a permission, an SDK or a new external service
- Schema changes to tables already in a migration

**OK to assume:**
- File location if ARCHITECTURE §Layout is clear
- Naming conventions (match existing code)
- Error handling pattern (match existing code)
- Test layout (match existing tests)

### Phase 5: Output & Summary

After all steps complete, launch the checks the user selected in Phase 0b (see "Automated checks" below) in the background first, then:

0. **Progress**: show `N/M steps done, K/L checkpoints ticked` and the checkpoint todo list as it stands in the spec (ticked / pending / failed). Tick the final checkpoint when its checks pass, including docs updates from step 2 below. If not everything is done (user stopped, blocked, failure), say where it stopped and print the manual resume line (see Advance below). The spec already holds all state, so nothing else needs saving
1. **List changes**: Show the mode (`MODE: worktree|current-branch|in-place`), the work directory (`WORKTREE:` = `<work>`) and its branch (`BRANCH:`), then files created / modified by this task under `CHANGED:`, paths relative to `<work>` (`git -C <work> status --short`; the spec's checkbox edits included; in current-branch mode leave out the pre-existing files noted in Phase 0b)
2. **Keep docs true**: if the implementation changed something a doc describes, update that section in the same change: PRD (rules, FRs, data model, stack; new decisions go in §20), ARCHITECTURE.md (layout, invariants, errors, decisions table, open items), CODE_QUALITY.md (known debt, single-sources table). List doc edits separately in the summary
3. **Brief summary**: 2-3 sentences on what was implemented
4. **Next steps**: Say which background checks are still running or their results; list which checks the user selected and which were not run; note that no integration test was run or written (`/lean-e2e` writes them) and that builds and contract drift are for `lean-review`; note any user action needed (new GitHub secret, hosted migration, store permission, workflow change) — never do it yourself. Worktree mode: the ticked spec is the worktree copy (the main copy is stale), and committing and merging `feature/<task-name>` is the user's. Current-branch and in-place modes: the spec in `<repo>` is current, and committing is the user's. Do not commit, merge or remove a worktree
5. **Write the handoff, then print the next command.** The next stage runs in a fresh session, so everything it needs must be in the spec. Once the background checks have reported (or after the last step if none were selected), append ONE line to the live spec's `## Implementation Log`, replacing any earlier `Handoff` line:
   `- Handoff — mode: <worktree|current-branch|in-place> — branch: <branch or none> — base: <short sha or none> — checks: <list or none> — changed: <comma-separated paths relative to <work>> — preexisting: <paths to ignore, or none> — checkpoints: K/L`
   Then do the **Next command** step (below)
6. **Do NOT commit**: Skill outputs code changes only; user decides when/how to commit and merge. When committing: Conventional Commits, short subject (≤50 chars, imperative), no body, no co-author line

#### Next command (manual handoff to review)

A skill cannot clear this conversation and does not start the next stage. The user runs it in a fresh session that sees only the spec. Do this last, after the summary:

- **All checkpoints ticked**: print the review command: `/lean-review specs/<task-name>.md` (run it after `/clear` or in a new session; it asks which review checks to run). Do not invoke `lean-review` yourself
- **Checkpoints left unticked** (stopped, blocked, failed): do not print the review command. Print the manual resume line: `/lean-implement specs/<task-name>.md from CP<n>` (lowest unticked `CP<n>`)

### Automated checks (background subagents, never in the main thread)

**Only what the user selected, light checks only.** Phase 0b asks which of lint, architecture and unit tests to run; run exactly those, nothing more. Implementation never runs or writes Flutter integration tests (that is the `lean-e2e` skill), and never runs builds, contract-drift checks, emulators, a hosted database or anything else that is slow or needs a device or the network (those belong to `lean-review`).

Run every checker in its own background subagent (Agent tool, `subagent_type: "general-purpose"`; subagents run in the background and notify on completion) so the main thread keeps working and the user is never blocked. Launch all in ONE message so they run in parallel. Targets come from the root `Makefile`; if a target does not exist yet, the subagent reports that instead of inventing one. Every command runs in `<work>`: give the subagent its absolute path (in worktree mode, not the main checkout's).

| Checker | Command | Run when |
|---|---|---|
| Lint | `make lint` (dart format check, `flutter analyze`, `go vet`, `golangci-lint`) | user selected it |
| Architecture | `make arch` (`go-arch-lint` and the Dart import check) | user selected it |
| Unit tests | `make test` (`go test ./...`, `flutter test`) | user selected it |

Subagent prompt rules:
- Run the one command only, from `<work>`'s root. Do NOT edit files, fix errors, or commit.
- If a tool or target is missing (`flutter`, `go`, `golangci-lint`, `go-arch-lint`, a Makefile target), report that instead of installing or creating it.
- Report back in <=10 lines: PASS/FAIL, and for FAIL the exact error lines with `file:line`. No full logs.

Main thread: keep going (summary, docs, next step) and do not poll or sleep. Results arrive as notifications; fold them into the final message. On FAIL, report it plainly with the errors; fix only if the failure is in code this skill just wrote.

## Example: What Good Looks Like

**Good implementation:**
- Follows every step in the plan
- Spec updated after every single step (step ticked, log line written) and every checkpoint (ticked only with evidence, never ahead of it), so a stop at any moment can be resumed in a new session from the file alone
- Code matches existing project style
- New files created with full, working content, with tests
- Only files specified in plan are touched
- Comments explain why for non-obvious choices, citing the BR-/FR- id
- Consistent with `docs/PRD.md`, `docs/ARCHITECTURE.md` and `docs/CODE_QUALITY.md`; they stay accurate afterwards
- If plan has code examples, they're adapted to the codebase

**Weak implementation:**
- Skips steps or changes plan without asking
- Does several steps and updates the spec once at the end (a stop loses the progress)
- Code style inconsistent with project
- Creates stub files that aren't functional
- Modifies unrelated files
- Does not ask where to work or which checks to run, or assumes the answer
- In worktree mode: edits the main checkout instead of the worktree, bases the worktree on `origin` instead of the local `HEAD`, forgets to fetch dependencies in the worktree. In current-branch mode: switches branches, or touches pre-existing uncommitted files. In either: commits / merges / removes the worktree
- Runs or writes integration tests, a build or an emulator during implementation, or runs a check the user did not select
- Deploys, applies a migration to the hosted project, sets a secret, or prints `.env`
- Breaks a boundary (`domain` imports a framework, a module imports another's internals, an app imports the other app, SQL outside the API's `infrastructure/`), returns another user's row, skips the JWT middleware, builds SQL from strings, hand-edits generated code
- Hardcodes strings instead of ARB keys, or magic numbers instead of `kernel/limits`
- Ignores `docs/PRD.md`, `docs/ARCHITECTURE.md` or `docs/CODE_QUALITY.md`, or leaves them stale after changing what they describe
- Builds anything from PRD §10.3 or §23
- Doesn't ask for clarification when needed

## Integration with lean-planning Skill

This skill works standalone—it doesn't require the planning skill to have run first. However:

- If a plan was generated by lean-planning, it will be in `specs/<task-name>.md`
- This skill will find and consume it automatically
- If no plan exists, user provides one (inline or path)

The skills are independent; either can be used separately or together.
