---
name: lean-planning
description: Create detailed implementation plans for Lean Tracker (Flutter mobile app, Go API, Supabase Postgres, OpenAPI contract) when user explicitly requests. Triggers on "plan", "design", "spec out", "let's design", "create a plan" — whenever user wants structured guidance before starting work. Produces a markdown spec covering steps, checkpoint todo list, architecture, risks, trade-offs, file changes, OpenAPI changes, SQL migrations, Drift schema changes, dependencies, tests, success criteria. Reads docs/PRD.md, docs/ARCHITECTURE.md and docs/CODE_QUALITY.md and explores the codebase first to validate assumptions. Grills user relentlessly to zero uncertainty before planning.
compatibility: Requires Explore agent for codebase search and Agent tool access to spawn an independent Haiku-model agent
---

## When to Use This Skill

Use when user explicitly says: "plan X", "design X", "spec out X", "create a plan for X", "how should we implement X", "let's design X". This skill is NOT for quick answers—it's for substantial features, refactors, or architectural changes where thorough upfront planning saves dev time.

## Workflow

### Phase 1: Grill User to Zero Uncertainty

Before exploring code or writing any plan, interview user relentlessly until you have clear answers to:

- **Problem scope**: What problem does this solve? Who benefits (the single role "User", PRD §3)? What's the current state?
- **Success criteria**: How do we measure if this worked? What must be true at the end? Which FR-/BR-/NFR-/UF-/BP- ids and acceptance criteria does it satisfy?
- **Constraints**: data isolation (BR-001), offline matrix (BR-014), snapshot rule (BR-007), validation ranges (BR-003), local save ≤ 300 ms (NFR-002), barcode lookup p95 ≤ 4 s (NFR-001), security (NFR-004: HTTPS, JWT on every endpoint but health, secrets only where allowed), free tiers (Supabase Free, Cloud Run, NFR-007), a11y and 360 dp (§16), PL + EN strings (FR-017), scope limits (§10.3) and future scope (§23: not built in the MVP)?
- **Unknowns**: Tricky parts (the sync protocol and conflict rule; client `updated_at` trust; idempotent upserts of client UUIDs; Drift migrations; scanner and notification permissions on Android 10+/iOS 16+; Apple sign-in on Android; OFF mapping and timeouts; day boundary in the device time zone; deleting the Supabase Auth user)? Where is the user uncertain?
- **Priority**: What's most important? Any hard constraints vs nice-to-haves?
- **Context**: Which milestone (M1–M8 in PRD §19)? Which user flow (UF-001–UF-006), which DESIGN.html board (Logowanie, Cele, Dziennik, Dodaj wpis, Skaner, Ilość, Własny produkt, Szczegóły posiłku, Kopiuj posiłek, Tydzień, Ustawienia, Usuwanie konta) and exact strings from PRD §11? Open items in ARCHITECTURE.md, known debt in CODE_QUALITY.md, prior attempts?
- **Technical constraints**: Which app and module (`apps/mobile/lib/<module>/<layer>`, `apps/api/internal/<module>/internal/<layer>`)? New or changed route in `contracts/openapi` and a new error code? New SQL migration in `db/migrations/` and a matching Drift table or schema version? New rule value for `kernel/limits` (both apps) and the OpenAPI schema? New ARB keys (EN + PL)? New dependency (needs the owner's approval when not in PRD §18)? Existing patterns to follow?

Don't assume—**ask until you're certain**. If user gives vague answers, drill deeper. Ask follow-ups, propose scenarios, stress-test assumptions. This usually takes 5-10 questions. Stop only when you understand the problem deeply enough to spot risks and trade-offs.

### Phase 2: Parallel Dual-Track Draft (Explore + Plan)

Run two full, independent tracks in parallel — same message, single response block:

**Track A (you, main agent):**
0. Read before exploring: `docs/PRD.md` (business rules §5, processes §6, scope §10, user flows §11, functional requirements §12, data model §13, auth §14, integrations §15, platforms and UI §16, NFRs §17, stack, architecture and DevOps §18, milestones §19, decisions log §20, future scope §23), `docs/ARCHITECTURE.md` (principles, layers, layout, modules, dependency rules, cross-layer flow, enforcement, decisions AD1+, open items) and `docs/CODE_QUALITY.md` (principles, single sources of truth, working agreements, review checklist). The plan must fit all three; where it can't, the deviation is stated explicitly in the plan.
   For UI work, name the DESIGN.html board the plan follows. `docs/DESIGN.html` is a 4 MB bundle: never Read it whole; search it with a small script or ask the user for values.
1. Use Explore agent (medium breadth) to understand:
   - What exists today in `apps/mobile/`, `apps/api/`, `contracts/openapi/`, `db/migrations/`, `.github/workflows/`
   - Relevant existing code patterns (a similar use case, repository, handler, screen, view model, Drift table, migration, test)
   - `pubspec.yaml`, `analysis_options.yaml`, `go.mod`, `.go-arch-lint.yml`, the Makefile
   - Existing similar implementations (to avoid reinventing)
   Focus on: "What exists today that's related to this task?" (The repo may have little or no code yet; say so rather than inventing structure.)
2. Write your own draft plan (see Phase 3 template) from these findings.

**Track B (independent Haiku agent):** Spawn via Agent tool with `model: "haiku"`, `subagent_type: "general-purpose"` (fresh agent, not a fork — it must not see your exploration or draft plan, or its "independent opinion" is worthless). In the prompt, give it verbatim the grilled requirements from Phase 1 and instruct it to, on its own: read `docs/PRD.md`, `docs/ARCHITECTURE.md` and `docs/CODE_QUALITY.md`, explore the codebase itself, then write a complete draft plan using the Phase 3 template. It must not talk to the user — it works from the requirements you hand it only. It must not open `docs/DESIGN.html` with Read (4 MB bundle); it uses the PRD's description of the design instead.

Do not let either track see the other's output while in progress. Wait for both to finish before Phase 4.

### Phase 3: Write Comprehensive Plan

Structure the plan markdown as follows. This is the template both Track A and Track B use for their draft. Only the final, reconciled plan (Phase 4) gets saved to `specs/<task-name>.md`.

#### Template Structure

```markdown
# [Feature/Refactor Name] — Implementation Plan

## Summary
2-3 sentences: What problem does this solve? Why now? Milestone (M1–M8). Base: current branch and short SHA (or "not a git repository yet"); any uncommitted work or unmerged branch the plan relies on.

## Success Criteria
Bulleted list of measurable outcomes. Must verify at the end:
- Metric 1 (specific target, e.g. an FR acceptance criterion)
- Metric 2 (specific target)
- ... (3-5 criteria)

## Scope & Constraints
- In scope: [what this covers, with FR-/BR-/UF-/BP- ids]
- Out of scope: [explicitly what it doesn't; check PRD §10.3 and §23]
- Hard constraints: [BR-/NFR- rules: isolation, offline, snapshot, validation, performance, security, a11y, free tier]
- Trade-offs: [what we're prioritizing over what, and why]

## Architecture & Design

### High-Level Flow
Describe how the solution works end-to-end (screen → view model → use case → Drift / API client → OpenAPI route → transport → use case → repository → Postgres). Use ASCII or mermaid diagram if helpful.

### Key Changes
- **App / module / layer**: What changes in `apps/mobile/lib/<module>/...` and `apps/api/internal/<module>/internal/...`. Why this choice over alternatives.
- **Contract**: New or changed routes in `contracts/openapi/openapi.yaml` (method, path, schemas, status codes, error codes), and the regenerated Dart client (`make gen`).
- **Data model**: SQL migration file (next number in `db/migrations/`, forward-only), RLS and grants for a new table, the Drift table and schema version, the sync fields (`id`, `updated_at`, `deleted_at`).
- **Limits**: new values in `kernel/limits` of both apps and the OpenAPI schema, with the contract test.
- **UI**: screens and the DESIGN.html board each follows, states (loading, empty, error, offline), exact PRD §11 texts as ARB keys (EN + PL), `Semantics` labels, 360 dp, font scale, light and dark.
- **Dependencies**: New packages (justify against CODE_QUALITY; owner approval if not in PRD §18; platform permissions in `AndroidManifest.xml` / `Info.plist`), config or workflow changes.

### Fit with Project Docs
- **PRD**: which BR-/FR-/NFR-/UF-/BP- ids the change implements or touches; any rule bent, with the reason.
- **ARCHITECTURE.md**: which app, module and layer each change lives in; which principles and dependency rules apply (layers, module boundaries, ports, composition root, contract first); the product rules that apply come from the PRD (isolation, snapshot, sync, offline matrix, auth, secrets). Any deviation, with the reason.
- **CODE_QUALITY.md**: how the design stays KISS and YAGNI, keeps one source of truth per the single-sources table, and keeps concerns separated. Name any rule being bent and why.
- **Docs to update**: PRD sections (decisions log §20, open questions §21, milestones §19) and ARCHITECTURE.md / CODE_QUALITY.md sections (decisions, open items, known debt) the change makes stale.

### Alternative Approaches Considered
For each major decision (tool choice, architecture pattern):
- Option A: pros/cons, why not chosen
- Option B: pros/cons, why chosen
- Option C: pros/cons, why not chosen

## Implementation Steps
Numbered sequence of steps from start to finish, written as checkbox lines (`N. [ ] ...`) so lean-implement can tick each one as it goes and a stopped session can resume. Each step should be:
- Atomic (can be reviewed/tested independently if possible, and small enough to finish and tick in one go)
- Clear (specific folders, files, functions, or behaviors; nothing left for the implementer to guess)
- Ordered (later steps depend on earlier ones where relevant; contract and migration before the code that uses them)

Example:
```
1. [ ] Add `Quantity` value object and `entryNutrition(snapshot, quantity, unit)` to `apps/mobile/lib/diary/domain/nutrition.dart` (BR-006)
2. [ ] Unit tests in `apps/mobile/test/diary/domain/nutrition_test.dart`: g, ml, serving, serving without `serving_size` rejected, rounding (FR-004 criteria)
3. [ ] Add the `DiaryEntry` schema to `contracts/openapi/openapi.yaml` and run `make gen`
4. [ ] Add migration `db/migrations/0003_diary_entries.sql` (RLS on, no policies, grants for the API role)
5. [ ] `SaveEntry` use case in `apps/mobile/lib/diary/application/` writing to the `EntryRepository` port; Drift implementation in `infrastructure/`
6. [ ] Mark FR-004 acceptance criteria covered in the spec
```

## Checkpoints (Todo List)
Checkbox list of milestones, so progress is trackable and the plan can be resumed mid-way. Each checkpoint is a verifiable gate, not a restated step:
- Group related Implementation Steps (reference them by number)
- State the evidence that closes it, using only light checks: `make lint` clean, `make arch` clean, `make test` (or the named test files) green. Never name integration tests, builds on a device or manual timing as checkpoint evidence: integration tests are `lean-e2e` only, builds and drift checks belong to `lean-review`
- Order so each checkpoint leaves the workspace analyzing and light tests passing
- 3-7 checkpoints; the last one covers docs + final verification

Example:
```
- [ ] CP1 — Domain: steps 1-2; `flutter test test/diary/domain` green
- [ ] CP2 — Contract and schema: steps 3-4; `make gen` runs, migration applies to a local Postgres
- [ ] CP3 — Use case and storage: step 5; `make lint` and `make arch` clean, unit tests green
- [ ] CP4 — Docs + final light verification: step 6; lint, arch and all unit tests green
```

### Risks & Mitigations
- Risk: [What could go wrong?]
  - Mitigation: [How do we prevent or recover from it?]
  - Mitigation: [Alternative approach if first fails]
- ... (3-5 major risks; consider another user's data reachable through a query without `user_id`, an upsert overwriting someone else's row, a shared product leaking after `is_shared = false`, an entry changing when its product changes, LWW won forever by a future `updated_at`, offline edits lost on conflict, wrong day near midnight or across time zones, a migration that cannot be rolled back, a dependency or permission the stores reject, a layer rule broken and caught late)

## Test Strategy
How do we verify this works?
- Unit tests (Go): [table-driven tests of domain and application on in-memory fakes; JWT middleware; OFF mapping; handler tests with `httptest`]
- Unit tests (Flutter): [domain and application with no network, database or widgets: BR-003, BR-006, BR-007, BR-010, BR-015, sync conflict; fake `Clock` and `Uuid`]
- Repository tests: [SQL that enforces isolation and conditional upserts, against a local Postgres]
- Contract tests: [mirrored limits equal the OpenAPI values; generated client in sync]
- Integration tests (Flutter `integration_test/`), heavy: [flows of §11, NFR-002 timing]. Do not plan integration test steps: implementation neither writes nor runs them. If a flow deserves one, list it under a "For `/lean-e2e`" note (the behavior in one sentence)
- Manual testing: [scenarios, e.g. airplane mode add and sync, two devices editing one entry, Polish locale, dark theme, 200% font, camera permission denied]

Split the strategy in two groups: **light** (`make lint`, `make arch`, `make test`: run during implementation, whichever the user selects) and **heavy** (builds, contract drift, manual timing: only by `lean-review` when the user selects them; integration tests: the `lean-e2e` skill only).

## Success Checklist
At launch, verify:
- [ ] All success criteria met (with evidence)
- [ ] Lint, architecture check and unit tests clean (implementation)
- [ ] Heavy checks green when run (review): build, contract drift
- [ ] Code review approved
- [ ] Documentation updated (sections listed in "Fit with Project Docs")
- [ ] No regressions in Polish and English, light and dark, offline

## Timeline & Estimates
- Phase 1 (implementation): ~X hours
- Phase 2 (testing): ~Y hours
- Phase 3 (review + polish): ~Z hours
- **Total**: ~X+Y+Z hours (rough estimate, plus buffer)

Note: Estimates are rough. Adjust based on your velocity.

## Open Questions
Any assumptions still uncertain? List them:
- [ ] Question 1?
- [ ] Question 2?

(These should be empty or near-empty after grilling—but if something remains genuinely unclear, call it out explicitly.)

## Implementation Log
(Empty. lean-implement appends one line per step event here, so work can resume in a new session. Decisions from `AskUserQuestion` answers are also recorded here as `- Decision: <question>: <answer>`)
```

### Phase 4: Reconcile Track A and Track B, Confirm with User

Once both drafts are done:

1. Diff the two plans section by section (scope, architecture/design decisions, implementation steps, risks, alternatives considered). Ignore wording differences — only substantive disagreements matter.
2. For any difference that is a verifiable fact about the codebase or the PRD, verify it yourself directly — grep/read the actual file — before doing anything else. Never guess, never pick a side because it "sounds more likely." If verification resolves the difference, silently take the correct side and don't bother the user with it.
3. For every remaining real disagreement that is a judgment call, ask the user **one separate `AskUserQuestion` per disagreement**. Present both options neutrally — what Track A proposed and what Track B proposed — with the actual trade-off, and no recommendation unless you've verified one side is factually wrong.
4. Build the final plan using the user's choices (plus your own verified corrections from step 2). Save only this final, reconciled plan to `specs/<task-name>.md` — never save the two intermediate drafts. Name files with a two-digit milestone-ordered prefix (`01-repo-api-skeleton.md`, `02-auth-settings.md`, ...) matching existing files in `specs/`.

## Key Principles

1. **Be specific**: Not "update the diary", but "add `copyMeal(source, target)` to `apps/mobile/lib/diary/application/copy_meal.dart` creating new ids and `updated_at = clock.now()`".
2. **Show trade-offs**: Explain why you chose this path over alternatives. The user should understand the reasoning, not just the decision.
3. **Flag risks early**: Better to spot problems in the plan than mid-implementation.
4. **Validate against code and docs**: Use exploration phase to check that proposed changes align with existing patterns, `docs/PRD.md`, `docs/ARCHITECTURE.md` and `docs/CODE_QUALITY.md`, and won't break isolation, the dependency rule, module boundaries or the free-tier budget.
5. **Make it actionable**: Devs should be able to take the plan to implementation without major re-thinking.
6. **Checkpoint it**: Every plan carries a Checkpoints todo list with a verifiable closing condition per checkpoint. Final plan saved to `specs/` must keep all step and checkpoint boxes unchecked (`[ ]`) so implementation can tick them off.
7. **Keep heavy tests out of the loop**: planning never runs tests, and the plan never makes integration tests, builds or manual timing a step's or checkpoint's closing evidence.
8. **Never plan production actions for Claude**: API deploys, mobile builds and uploads, migrations on the hosted Supabase project, secrets and pushes to `main` are user steps. If the task needs one, list it under "Success Checklist" as a user action, not as an implementation step.
9. **Where implementation runs is the user's choice, made at implement time**: `lean-implement` asks whether to use its own git worktree (`.claude/worktrees/<task-name>` on branch `feature/<task-name>` from the current `HEAD`, `<task-name>` = spec file name without `.md`) or the current branch, and which checks to run. Planning decides neither and does not create a worktree. Note the current branch and short SHA in the plan's Summary, and flag any local uncommitted work, or any unmerged dependency branch, that the plan touches or relies on, because a worktree cannot see it. The spec stays in the main checkout's `specs/`; in worktree mode implementation copies it into the worktree.

## After the Plan

1. Present plan to user
2. End the message with the **Next move snippet** (below), filled with the real spec path
3. Wait for approval, feedback, or changes
4. Revise if needed (path stays the same; reprint the snippet only if the file name changed)
5. Once approved: print the manual implement command (see Next move snippet), or the user codes directly

Do NOT start implementing until user explicitly approves the plan.

### Next move snippet

Always the last thing in the message that presents the saved plan, with the exact path of the spec just written to `specs/` (never a placeholder).

**The next stage is started by the user, in a fresh session.** The spec holds everything implementation needs (grilled answers, decisions, steps), so this conversation's history is dead weight. A skill cannot clear the conversation and nothing here starts the next stage, so print the command and let the user run it after `/clear` or in a new session:

````markdown
**Next move** — approve the plan (or ask for changes). Then, in a fresh session (`/clear`), run `/lean-implement specs/<task-name>.md`. It carries only the spec and first asks where to work and which checks to run.
````

On explicit approval: apply any requested plan changes to the spec first (whatever is not in the file is lost), then repeat the one-line command `/lean-implement specs/<task-name>.md`. Do not invoke `lean-implement` yourself and do not start implementing, on approval or on silence.

Manual resume later, in any new session (continues at the first unticked checkpoint): `/lean-implement specs/<task-name>.md [from CP<n>]`. `<n>` is the lowest unticked checkpoint.

**Commit guidance (if user later commits):** Conventional Commits, short subject (≤50 chars, imperative), no body, no co-author line

## Example: What Good Looks Like

**Good plan** shows:
- Concrete file paths (not "update the API", but "modify `apps/api/internal/diary/internal/infrastructure/entries_repo.go`")
- Specific interface changes (function signatures, OpenAPI schemas, status and error codes, migration SQL, Drift table)
- Dart and Go type sketches where relevant
- Risks that are relevant (not generic)
- Test cases tied to implementation steps and to FR- acceptance criteria
- Trade-off reasoning ("We chose approach X because Y, not approach Z because...")

**Weak plan** is vague:
- "Improve performance" without metrics
- "Refactor sync" without specifying what changes
- "Add tests" without saying which tests or why
- Risks that are too generic ("bugs might happen")
- No rationale for decisions
- Steps that deploy, migrate the hosted database or set secrets
