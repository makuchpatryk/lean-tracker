---
name: lean-e2e
description: Add a Flutter integration test (`apps/mobile/integration_test/*_test.dart`) to Lean Tracker for one exactly specified behavior. The user says what must be checked; the skill runs a short grill to pin down the actor, setup, steps and exact expected results, writes a confirmed test contract, then writes the test in the existing integration-test style. Never guesses a label, text, key or number: it finds it in the source or asks. Always asks where to work (own git worktree or current branch) and which checks to run. Triggers on "add e2e test", "write e2e", "new integration test", "integration_test for X", "e2e for X", "/lean-e2e". Does not commit, and does not change product code without asking.
compatibility: Edits `apps/mobile/integration_test/` (and docs the change makes stale), either in a per-task git worktree (`.claude/worktrees/<task-name>`, branch `feature/<task-name>`) or on the current branch (asked every run). Uses AskUserQuestion. Runs only the checks the user selects, and when it runs a test it runs only the new file on one chosen device or emulator, never the whole folder. No hosted services: the API and Open Food Facts are faked. Never commits, merges or removes a worktree.
---

## When to Use This Skill

Use when the user wants a new integration test, or a new case in an existing one: "add an e2e test for X", "write an integration test for the quick add flow", "/lean-e2e X".

This skill is NOT for unit tests (those go with the code, `lean-implement`), for planning a feature, or for reviewing code. It writes Flutter integration tests only. Asking for this skill is the explicit request that lifts the "no integration tests" default of `CLAUDE.md`; running the test still needs the user's selection in Phase 3.

Integration tests run on a device or emulator, locally. They are not part of CI (PRD D-30, ARCHITECTURE §Testing).

**The user decides what is checked.** The skill's job is to make that decision exact, then encode it. It never invents expected behavior from reading the code: the code says what the app does, the user says what it should do. If they differ, that is a question for the user.

## Workflow

### Phase 0: Read the integration-test setup (before asking anything)

Names: `<repo>` = main checkout root (`git rev-parse --show-toplevel`, or the project root when it is not a git repository yet). Read skills by absolute path from `<repo>`.

Read, from `<repo>`:

1. `apps/mobile/pubspec.yaml` (`integration_test` and `flutter_test` dev dependencies), `apps/mobile/analysis_options.yaml`, the root `Makefile`
2. `apps/mobile/integration_test/`: the existing tests and any `support/` helpers (app launcher with test overrides, fake API client, fake OFF/barcode source, fake clock, in-memory or temporary Drift database, sign-in bypass, pump helpers). Know what exists before proposing anything new. Find the closest test and use it as the style template
3. `apps/mobile/lib/app/`: where dependencies are wired, so the test replaces the network, the clock, the scanner and the notifications with fakes through the composition root, never by editing product code
4. `docs/ARCHITECTURE.md` §Testing and decisions, and `docs/CODE_QUALITY.md`. `docs/PRD.md` only for the requirement ids the user names, and PRD §11 for exact UI strings

### Phase 1: Take the request, then grill

Start from what the user wrote. Extract what is already exact; ask only about what is missing or vague. This is a **small** grill: usually 3 to 8 questions, no padding, never a question the user already answered or the code can answer for certain.

**Ask with `AskUserQuestion`**: concrete options when the choices are known (2-4 options, the recommended one first), one question per decision, up to 4 questions per call. Free text only when options cannot be listed.

What must be pinned down (skip an item only when it is already unambiguous):

1. **The claim.** One sentence: "when the user does <action> in <situation>, <observable result>". Which FR-, BR-, NFR-, UF-, BP- id does it prove? If the user gives only a topic ("test the diary"), ask for the exact behavior
2. **Why integration.** Compare with the existing tests and `ARCHITECTURE.md` §Testing. If the behavior is already covered, say so and ask whether to extend that test, add a case anyway, or stop. If it needs no real app, navigation, Drift database or platform channel, ask whether a unit or widget test (`apps/mobile/test/`) is the better place
3. **Surface and state.** Signed in with which fake user, locale (EN or PL, set explicitly), theme, device orientation (portrait only, PRD §16), network (online, offline, flaky), permissions (camera, notifications) granted or denied. Which platform: Android emulator, iOS simulator, or a physical device
4. **Setup.** Data that must exist (goals, products, entries, favorites, recents, reminders), created through the app's own repositories or a test seed into a fresh temporary Drift database, and what the fake API and fake OFF return. Defaults come from the helpers; confirm only what the claim depends on
5. **Steps.** The user-visible actions in order: taps, text entry, scan result delivered by the fake scanner, navigation, a date change, going offline and back. Name the control as the user sees it
6. **Expected results, exact.** For each: what is observed, where, and the exact value. A UI text (in the test's locale), a `Semantics` label, a `Key`, a number, a stored row. "Works", "looks right", "no errors" are not results: ask what exactly appears or does not appear
7. **Must NOT happen.** The negative checks that matter for the claim (an entry unchanged after the product changed, no fourth reminder, no call to the API while offline), each as exact as the positive ones
8. **Isolation and cleanup.** The test starts from a fresh temporary database and fakes, owns its data and leaves nothing on the device (database file deleted in `tearDown`). Does it touch device state outside the app (permissions, notification schedule)? If so, say how it restores it
9. **Time.** Inject a fake `Clock`; prefer `pumpAndSettle` and finders over fixed delays. If the claim needs a measured time (NFR-002: local save ≤ 300 ms p95), state the number, the number of repetitions and the rule it comes from, and ask before raising a timeout

**Never assume, never fill gaps.** If you are not sure about any of these, STOP and ask, with concrete options:

- a UI text, label, key or route: find it in the source first (`apps/mobile/lib/l10n/*.arb`, `apps/mobile/lib/<module>/presentation/`, `apps/mobile/lib/ui/`; limits in `apps/mobile/lib/kernel/limits.dart`; API behavior in `contracts/openapi`). Found and unambiguous: use it. Not found, found twice, or different from what the user said: ask
- whether a product behavior is a bug or intended: ask, never encode a guess
- whether product code may change (for example a missing `Semantics` label or `Key`): ask. The default is no product code changes
- the intent behind a vague word ("quickly", "properly", "after a while"): ask for the number or the event

Stop grilling when every step and every expected result has a concrete finder or value and no open "probably". Then go to Phase 2.

### Phase 2: Test contract (confirm before writing code)

Print the contract in this shape, with real values, nothing vague, nothing left as "TBD":

```
Test contract: apps/mobile/integration_test/<name>_test.dart   (new file | new case in <existing file>)
Claim:    <one sentence>
Proves:   <FR-/BR-/NFR-/UF-/BP- ids>
User:     fake signed-in user | signed out    Locale: en | pl    Theme: light | dark    Network: online | offline
Platform: Android emulator | iOS simulator | physical device (which)
Setup:    <data seeded, fakes and their answers, permissions>
Steps:
  1. <action> via <text "..." | Semantics label "..." | Key('...') | fake scanner emits "<barcode>">
  2. ...
Expect:
  E1. <finder> shows "<exact>" (timeout: default | <n> s, reason)
  E2. <stored row / fake call count> equals <value>
Must NOT happen:
  N1. <...> is absent / the fake API received no call
Time:     ~<n> s (measured assertion: none | <n> ms p95 over <k> runs, rule)
New helpers / product changes: <none | list, each approved>
Stays in unit tests: <what this test deliberately does not cover>
```

Ask with `AskUserQuestion`: "Approve this contract?" with options **Approve**, **Change** (the user types what), **Cancel**. On Change, update the contract and ask again. Do not write code before an explicit Approve.

### Phase 3: Where to work and which checks (before the first edit)

Ask with ONE `AskUserQuestion` call holding two questions, every run, never assuming (skip a question only when the invoking prompt already carries its answer; skip the workspace question when the directory is not a git repository and work in place):

1. **Workspace** (single select): "Own git worktree `feature/<task-name>` (isolated, main checkout untouched)" or "Current branch `<branch>` (edit the main checkout directly)". Name the real current branch in the label. `<task-name>` = `e2e-<test file name without _test.dart>`
2. **Checks** (multi select, none required): Lint (`make lint`), **Run the new test** on a device you name (`flutter test integration_test/<name>_test.dart -d <device-id>` from `apps/mobile`; needs an emulator, simulator or phone; slow). If the user picks it, list `flutter devices` and ask which one. "None" is valid. Never offer the whole `integration_test/` folder; if the user types it under Other, run it as they say

Workspace procedure: follow `lean-implement` Phase 0b "Worktree mode" / "Current-branch mode" (read `<repo>/.claude/skills/lean-implement/SKILL.md`), with `<work>` = the worktree or `<repo>`. There is no spec file here, so skip its spec-copy and spec-log steps. In worktree mode `flutter pub get` in `<work>/apps/mobile` and the git-ignored env copy are the only setup commands (never print env files). Never commit, merge, push, switch branches or remove a worktree.

### Phase 4: Write the test

Work only in `<work>`. Edit only `apps/mobile/integration_test/` files and docs the change makes stale. Match the neighbouring tests; the contract is the source of truth, implement it literally, no extra assertions and no extra scenarios.

**Conventions** (copy from the existing tests, do not invent a new style):

- File `apps/mobile/integration_test/<name>_test.dart`, snake_case (`quick_add_test.dart`). `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` in `main`; helpers from `integration_test/support/`
- A header comment names what the test proves (`// UF-003, BR-010: ...`). Test names are a sentence that ends with the ids in parentheses: `'a used product moves to the top of recents (BR-010)'`
- The app starts through the composition root with test overrides (fake API client, fake OFF, fake scanner, fake notifications, fake `Clock` and `Uuid`, a fresh temporary Drift database). Never reach into a module's internals to bypass the layers
- Finders by visible text from the locale's ARB strings, `Semantics` label or an existing `Key`. Adding a `Key` or label is a product code change: only if the contract lists it as approved
- Assertions via `expect(finder, findsOneWidget)` and friends after `pumpAndSettle`; for state in the database read it through the module's repository, not raw SQL. **No** `Future.delayed` as synchronization, no retries or looser assertions added to hide flakiness. A custom timeout only with a comment naming the rule or time it covers
- Offline: switch the fake network to offline through the helper, never by disabling the device radio
- Parallel safety: each test creates its own temporary database and deletes it in `tearDown`; no shared files, no global state left behind
- API checks are assertions on the fake API client's recorded calls, not on a real server. Never call the hosted Supabase project, Cloud Run or Open Food Facts. Never put real credentials or tokens in a test
- One new helper only if two places need it; it goes in `integration_test/support/`, typed, with a one-line comment. Otherwise keep the code in the test. No `dynamic`, no unchecked casts
- Comments explain why, citing the BR-/FR-/NFR-/UF-/BP- or decision id; no narration of what the line does

**Keep docs true**, in the same change: if `ARCHITECTURE.md` (Layout, §Testing, a decision row) or a README now says something false about the integration tests, fix that line. List doc edits separately in the summary.

### Phase 5: Verify what the user selected

Run exactly the checks selected in Phase 3, in `<work>`, nothing more. In the foreground, one after another.

- Lint: fix failures in code you just wrote
- Run the new test: from `<work>/apps/mobile`, on the chosen device. If no device or emulator is available, say so and stop; do not start emulators or install SDKs on your own
- **A failing new test is a result, not an error to hide.** Read the output and decide which it is:
  - Test bug (wrong finder, wrong text, missing settle, shared data): fix the test, run it again, once or twice. Never add a sleep or loosen an assertion to get green
  - The product does not behave as the contract says: do **not** edit product code and do not change the contract to match. Report it as a finding: the contract line, what was observed, `file:line` of the likely cause, and ask the user whether the contract or the product is wrong
- Remove nothing the run produced outside git-ignored paths
- If you could not run something (missing tool, device, target), report that instead of installing or inventing it

### Phase 6: Output

1. **Mode and files**: `MODE: worktree|current-branch|in-place`, `WORKTREE:` = `<work>`, `BRANCH:`; files created or modified under `CHANGED:`, relative to `<work>` (in current-branch mode leave out files that were already modified before the task)
2. **Contract coverage**: each Expect / Must-NOT line mapped to the test and line that asserts it
3. **Checks**: which ran with PASS/FAIL (exact errors with `file:line` for FAIL), which were not selected, and plainly: "the new test was not run" when it was not
4. **Docs edited**, listed separately
5. **Open items**: anything the contract left for the user, any product finding from Phase 5
6. **Next move**: Worktree mode: the user commits in the worktree (`git -C <work> ...`) and merges `feature/<task-name>`. Current-branch and in-place modes: the user commits. Commit guidance: Conventional Commits, subject ≤50 chars, imperative, no body, no co-author line, e.g. `test: add integration test for quick add`. **Do NOT commit**; integration tests are not run by CI

## Rules

- **The user's words are the spec.** Every assertion traces to a line of the approved contract. No bonus assertions, no extra scenarios
- **Ask, don't guess.** An unsure label, text, timing, key, count or behavior is a question with options. A wrong guess here becomes a test that passes for the wrong reason
- **One claim per test.** Several claims mean several tests, each with its own contract line
- **Cheap and stable first.** Fakes for everything outside the app, fresh database per test, no fixed sleeps. A slow or flaky test is paid on every review
- **No product code changes** without an approved contract line. A failing test never edits the product
- **Workspace and checks are the user's choice, asked every run.** Only selected checks run; never the whole folder unless the user names it
- **Never commit, merge, push, switch branches or remove a worktree.** Never deploy, never touch the hosted Supabase project, never read or print env files

## What Good Looks Like

**Good run:** the user says "after a product is used, it appears first in Recents and the 21st removes the oldest"; the skill asks only what is missing (how the 20 are seeded, which products, which screen, which texts), confirms an exact contract, writes the test in the style of the neighbours with fakes injected through the composition root and a fresh database, runs lint and only that test on the chosen emulator as selected, and reports coverage line by line.

**Weak run:** starts coding from a topic, guesses text from memory, adds `Future.delayed`, asserts things the user never asked for, edits product code to make the test pass, loosens an assertion when the test fails, calls a real server, leaves data on the device, runs the whole folder, or commits.
