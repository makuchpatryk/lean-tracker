# Claude Code Guidelines for Lean Tracker

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

Skills live in the main checkout: read them by absolute path from there, also from inside a linked worktree. Skills output changes only; the user decides when to commit and merge the worktree branch.

## Git worktrees

- **Ask where to work, every run**: implementation asks whether to use its own git worktree (`.claude/worktrees/<task-name>` on branch `feature/<task-name>`, `<task-name>` = spec file name without `.md`, created from the current `HEAD`; main checkout untouched) or the current branch. Review asks which one to review. Never assume. If the directory is not a git repository, skills work in place and say so
