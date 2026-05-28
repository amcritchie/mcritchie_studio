# Git Protocol for Parallel Agent Work

The binding code of version-control ethics for every agent operating in any McRitchie repo. Every `soul.md` references this doc. These rules supersede individual preference.

## Why this exists

When multiple agent instances share a codebase, naïve git workflows produce: branches switching under you mid-edit, files mutating during Edit, stashes drifting from their labels, and merge conflicts masquerading as bugs. We have been bitten by all of these. The rules below are recovery, not theory.

## Worktrees, not shared checkouts

Every agent instance gets its own git worktree — an independent working directory sharing the underlying `.git` database. A branch can only be checked out in one worktree at a time; git enforces this for us.

```
~/projects/<repo>                          # lead worktree (Alex, manual)
~/projects/<repo>.work/<role>-<instance>   # per-agent worktrees
~/projects/<repo>.work/carl-001
~/projects/<repo>.work/shannon-005
```

Create:
```
git worktree add ../<repo>.work/<role>-<instance> -b <role>-<instance>/<feature-slug> origin/main
```

Remove when done:
```
git worktree remove ../<repo>.work/<role>-<instance>
```

Each worktree shares the host database by default. If two backend agents need to migrate concurrently, see `exclusive-lanes.md` (the `backend_migration` lane prevents this from breaking).

## Branch naming

`<role>-<instance>/<feature-slug>`

Examples:
- `carl-001/agent-page-banner`
- `shannon-005/dark-mode-cards`
- `jasper-002/usdc-vault-refactor`
- `steffon-001/heroku-buildpack-bump`

A pre-commit hook validates the prefix matches the executing agent's identity. The lead `main` branch and agentless personal branches are exempt.

## PR ownership

| Step | Owner | Meaning |
|---|---|---|
| Branch + PR opened | Dev | From their own worktree, against `origin/main` |
| Spec-adherence review | Avi (PO) | "This matches the ticket" |
| QA pass | Steffon | "Tests green, acceptance criteria met, no regression" |
| Merge | Avi | Only after spec ✓ AND QA ✓ |
| Release tag | Avi | Avi is accountable to Alex for throughput and quality |

Two approvers, either can block. Disagreement between Avi and Steffon escalates to Alex.

## Send-back format (rejected PR)

When Steffon (or Avi) rejects, the chat message goes in the PR's chat thread using this template:

```
@<author> — Rejected
Reason: <one line>
Acceptance criterion not met: <which>
Evidence: <test failure / screenshot / repro steps>
Look at: <file:line>
Suggested direction: <if obvious> | Open: <if unsure>
```

A rejection is a teaching moment, not a punishment. Be specific about what *would* pass.

## The ethics (binding rules)

1. **Never stash unfamiliar uncommitted changes.** If you open a worktree and find work you didn't create, stop. Log to chat, escalate. Stash labels often lie about contents — never trust them.
2. **Always branch off `origin/main`.** Never off another agent's branch unless coordinated explicitly in chat.
3. **`--force-with-lease`, never `--force`.** `--force` can silently overwrite a colleague's push.
4. **Re-read a file before Edit** when in a shared worktree. Files mutate under you.
5. **Pre-commit hooks always run.** Never `--no-verify`. If a hook fails, investigate. Don't work around.
6. **Your branch is your responsibility.** Never push to another agent's branch.
7. **Rebase, don't merge, when `main` advances.** Before opening a PR, `git fetch origin && git rebase origin/main`. Keep history linear.
8. **One in-flight branch per agent instance.** If you need to start something else, finish or abandon the current branch first.

## When in doubt

Ask in chat. Git mistakes are recoverable; pushing through ambiguity rarely is.
