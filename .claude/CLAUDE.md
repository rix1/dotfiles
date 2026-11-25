# How I work

These hold in every repo. A repo's own CLAUDE.md wins where they disagree.
The same rules, worded for Codex, are in `~/.codex/AGENTS.md`. Change both together.

@~/.claude/about-me.md

## Git

- **Worktrees:** make them with the EnterWorktree tool, or `isolation: worktree` on a subagent,
  never `git worktree add`. The WorktreeCreate hook leases a slot from the treehouse pool, so
  `treehouse status` sees it. A slot arrives on a detached HEAD; name a branch when there is
  something to push.
- **Commits:** always `git commit --no-gpg-sign`. Agents have no GPG passphrase, and a signed
  commit hangs or fails. `settings.json` also sets `commit.gpgsign=false` through `env`, but pass
  the flag anyway, since that env doesn't reach every shell.
- **Cleanup:** "clean up branches/worktrees" means only what this session created or worked on:
  its worktree, its local and remote branches. List anything else that looks stale and ask.
  Other worktrees may belong to sessions that are still running.

## Checking UI

- Use my real Chrome through the Claude in Chrome extension, not headless Chrome. Serve the app on
  localhost rather than opening a `file://` build. My window is very wide, so screenshots come
  back small: read state with `javascript_tool` and zoom in to look.
- For look-and-feel, animation and interaction-feel tweaks, skip the browser. Typecheck, commit,
  and tell me what to look for; I judge it faster. Use the browser for correctness bugs, where the
  DOM or the data answers the question.
- Several variants of an app side by side get consecutive dev server ports (4000, 4001, 4002):
  the base branch first, then the variants in order. Check the ports are free first.

## Sessions that run while I'm away

A session blocked on a permission prompt runs no code, so "tell me if you get stuck" in its
brief can never fire. When you start or brief one:

- Ban tools that can open a prompt that auto mode won't approve (preview servers, browser tools).
  A check that needs one is skipped and listed in the final report.
- Turn on Remote Control for it right after starting it, before it can block.
- The parent schedules its own check every 30–45 minutes. Each check reads the worktree's commits
  and file times; if nothing moved, push-notify me that it has stalled. Never tell me "it will
  notify you"; say when the next check runs.
- The child commits WIP at least once per increment and pushes the branch, so nothing lives only
  on disk.
- The plan and the status live in a GitHub issue: the body is the plan as a checklist, comments
  are the status log. A brief names the issue number instead of pasting the plan. Every session
  ends with a status comment and ticks what landed.
- Work that needs my decisions or my logins goes first, while I'm here.
