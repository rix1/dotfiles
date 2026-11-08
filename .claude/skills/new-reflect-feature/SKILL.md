---
name: new-reflect-feature
description: Start, build, or ship a feature for the user's own Reflect build (their fork of team-reflect/reflect-open, assembled with the `reflect-personal` script). Use when the user wants to add or change something in Reflect, port or rebase one of their Reflect feature branches, open an upstream Reflect PR, or rebuild/install their personal Reflect app. Covers the branch-per-feature + `personal` integration branch workflow, keeping patches rebase-friendly, and the checks a change must pass.
---

# New Reflect feature

The user runs their own Reflect, built from feature branches on top of
upstream `team-reflect/reflect-open`. Features ship to their app whether or
not upstream merges them; upstream PRs are opened only when the user asks.

## The setup

| Thing | Where |
| --- | --- |
| Main checkout | `~/Development/reflect-open` (`origin` = team-reflect, `fork` = rix1/reflect-open, public) |
| Integration branch | `personal`, in worktree `~/Development/reflect-personal`. Generated, never edited by hand |
| Branch list | `git -C ~/Development/reflect-open config --get-all personal.branch` (merge order) |
| Script | `reflect-personal status \| rebuild \| build \| install \| push \| all` (`~/.local/bin`, in dotfiles) |
| Built app | `~/Development/reflect-personal/target/release/bundle/macos/Reflect Dev.app` |

`rebuild` resets `personal` to `origin/master` and merges each listed branch.
git rerere is on (with autoupdate), so a conflict resolved once is replayed
on every later rebuild. "Reflect Dev" has its own bundle id and a no-op
updater feed, so it sits beside official Reflect and is never overwritten by
an update. Warn the user not to open the same graph in both apps at once.

Read `AGENTS.md` in the repo before writing code, every time: it holds the
architecture (services, stores, commands) and conventions this skill does
not repeat.

## Starting a feature

1. `git -C ~/Development/reflect-open fetch origin`, then branch from
   `origin/master` in a new worktree:
   `git worktree add ../reflect-open-<slug> -b feat/<slug> origin/master`,
   then `pnpm install --frozen-lockfile` there. The pre-commit hook needs it.
2. Check whether upstream already has it, or something close:
   `git log origin/master --grep`, open PRs, `git grep`.
3. When it works, add it to the build:
   `git -C ~/Development/reflect-open config --add personal.branch feat/<slug>`,
   then `reflect-personal all`.

## Keep the patch rebase-friendly

Upstream lands roughly 80 commits a week. Every line changed in an upstream
file is a future conflict, so:

- **New logic goes in new files.** Prefer a feature folder, as with
  `apps/desktop/src/focus-mode/` (`perf-hud/` is the upstream precedent).
  Give it its own CSS, imported by the module (`import './x.css'`, like
  `swipe-row.css`), its own settings hooks (call `useSelector` with
  module-level selectors; inline selectors are not stable), and a schema
  file whose shape `schema.ts` spreads in.
- **Hooks into upstream files stay one or two lines:** an import plus a
  component, a spread, or a list entry. Don't re-indent upstream JSX to wrap
  a provider; wrap the narrowest single-line child instead.
- **Read through upstream's own seams** before adding one: export an
  existing helper, read a stable `aria-label`/`data-testid` from CSS, or
  mount a ProseKit extension inside `NoteEditor` with `useExtension`. Don't
  widen `CommandContext` or shared interfaces when the command can reach
  `context.services` / `context.app` itself.
- **Context providers return a safe default ("off") when absent,** so
  upstream tests that render a lone component need no changes. Put the
  feature's tests in its own test files.
- **Don't fork dependencies.** The user ruled out forking Meowdown. Build on
  its public API from Reflect, and accept that hooking its internals
  (decoration classes, mark names) is fragile: pin those names with a test.
- **Formatting:** `pnpm exec oxfmt <files>` only. Never `npx prettier`; it
  reformats whole files in the wrong style.

## Checks before calling it done

- `pnpm check` (typecheck + oxfmt + oxlint + eslint + knip).
- Tests under Node 24 or later via fnm. The default Node 22 lacks
  `Promise.try`/`URLPattern`, so hundreds of unrelated tests fail.
  Targeted: `fnm exec --using=24 -- pnpm test --run <paths>`. Full:
  `fnm exec --using=24 -- pnpm test --run`. A browser test queried by role
  can't see `display: none` elements; query by attribute for "is hidden"
  checks.
- `cd apps/desktop && pnpm exec vite build`. Production builds run React
  Compiler, which rejects `??=`, `||=` and `&&=`; dev and `pnpm check` miss it.
- A user-visible change gets a What's New item at the end of the current
  marketing version's list in
  `packages/app/src/whats-new/whats-new-content.ts`. Every branch appends
  there, so branches conflict pairwise in `personal`: resolve by keeping both.
- Then `reflect-personal all`. If `rebuild` stops on a conflict, resolve it in
  `~/Development/reflect-personal`, `git add`, `git commit --no-verify`, and
  run `rebuild` again (rerere records it).

## Keeping current

`reflect-personal status` shows each branch's distance from upstream. A
branch only moves when rebased: open PR or not, it goes stale. Rebase one
with `git rebase origin/master` in its worktree. When upstream rewrote the
area, port the feature onto the new architecture rather than forcing the old
code through. Afterwards run the checks again and `reflect-personal all`.

## Publishing

- Commit freely on feature branches. Never rewrite published history without
  asking. The user's permission mode blocks `git commit --amend`; add a commit
  instead (upstream squash-merges).
- Back branches up to `fork` with plain pushes. A rebased branch needs
  `--force-with-lease`. If there is no local tracking ref, pass the expected
  SHA: `--force-with-lease=<branch>:<sha>`. Force-pushing a branch with an
  open upstream PR changes that PR, so confirm with the user first. `personal`
  is regenerated, so `reflect-personal push` always force-pushes it.
- Upstream PRs only when asked:
  `gh pr create -R team-reflect/reflect-open --head rix1:<branch>`.
  - The title is a conventional commit describing behaviour, with a scope
    when it helps (`feat(sidebar): …`).
  - The body uses the user's format: Problem, Before → After table, Demo (ask
    the user for a recording), Design notes, Testing.
  - When editing a PR body, keep the bot sections (codesmith footer, Sourcery
    and CodeRabbit summaries) as they are.
- Changed `reflect-personal` or this skill? Commit it with the `dotfiles`
  skill (both live on dotfiles `main`).
