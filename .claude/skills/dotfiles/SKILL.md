---
name: dotfiles
description: Commit changes to the dotfiles repo (the bare git repo at ~/.dotfiles whose work tree is $HOME, driven by the `conf` fish function). Use right after creating or editing anything the dotfiles track: a Claude Code skill in ~/.claude/skills, fish functions or config, tmux, starship, television, ghostty, git config, AGENTS.md or the READMEs, ~/.local/bin/dotfiles-*. Also use when a Stop hook reports uncommitted dotfiles changes, or when the user says "dotfiles", "conf", "commit my dotfiles", "sync dotfiles", "track this skill". Works out whether each change belongs on main or the machine branch, asks once, then commits through a linked worktree and syncs. Never checks out main in $HOME.
---

# Dotfiles: commit what changed

The rules live in `~/.config/AGENTS.md`; read it if it is not already in
context. This skill is the procedure. The scripts live in this skill's
`scripts/` directory; call them by absolute path.

## 1. See what changed

```sh
~/.claude/skills/dotfiles/scripts/changes
```

It prints the checked-out machine branch, tracked files that are modified or
deleted (each tagged `main` or the machine branch), new files in tracked
locations, untracked skill directories, and lines that look like secrets or
personal data. If a hook just told you which files changed this turn, deal
with those; leave pre-existing changes alone unless the user asks.

## 2. Decide where each change goes

| Change | Branch |
| --- | --- |
| A skill in `~/.claude/skills` that the user, or you in this session, wrote | `main` |
| Fish functions, completions, tmux, television, git, docs, `~/.local/bin/dotfiles-*` | `main` |
| A file `changes` tags with the machine branch (an overlay file: `starship.toml`, `config.fish`, aerospace, zed) | the machine branch. If the edit is something the other machine wants too, ask the user how to split it. |
| Skills installed from a marketplace or synced from claude.ai, caches, credentials, `fish_variables`, anything on the "Never commit" list in AGENTS.md | nowhere |

Ask "would the other machine want this line?". If a candidate contains
something the `changes` report flags (an email, this machine's name, a
key-shaped string), do not commit it; tell the user instead.

## 3. Ask once

Use AskUserQuestion with the plan: each file and its branch, plus the commit
message. Options: "Commit and push" (recommended) and "Not now". The repo is
public, so never push without this confirmation unless the user said earlier
in the session to commit without asking.

Commit message: `scope: Imperative summary`, where scope is the tool
(`skills`, `fish`, `tmux`, `zed`, `starship`, `television`, `fonts`, `docs`,
`setup`). Body only when the why is not obvious. One logical change per
commit. Pass any attribution trailers your harness requires as extra `-m`
arguments.

## 4. Commit

```sh
~/.claude/skills/dotfiles/scripts/commit --to main    -m "skills: Add foo skill" -- .claude/skills/foo
~/.claude/skills/dotfiles/scripts/commit --to machine -m "starship: Bigger prompt glyph" -- .config/starship.toml
```

`--to main` fetches, fast-forwards the local `main` to `origin/main`, checks
it out in a temporary linked worktree, copies the named paths in (deletions
included), commits without GPG, pushes, removes the worktree, and runs
`dotfiles-sync --no-setup` so the machine branch sits on the new `main`
again. `$HOME` is never checked out. It refuses overlay files unless you pass
`--allow-overlay`, and when you pass a directory it leaves out files that only
the machine branch tracks.

`--to machine` is `conf add -A -- <paths>`, `conf commit --no-gpg-sign`,
then `dotfiles-sync --no-setup`, which pushes with `--force-with-lease`.

Pass files, or a skill directory. A directory with unrelated untracked files
in it (`.config/television/cable`) would take them all. `--no-push` commits
only. `--setup` also runs `dotfiles-setup` afterwards; needed after changing
`fish_plugins`, fonts or tmux plugins.

## 5. Report

One or two lines: commit hash, branch, pushed or not, and anything you left
uncommitted and why. If the Stop hook started this, do not begin new work
afterwards.

## The hooks

`scripts/hook prompt` (UserPromptSubmit) snapshots `changes --porcelain` for
the session. `scripts/hook stop` (Stop) compares, and if tracked files or
skills changed during the turn without being committed, blocks the stop once
with the list and asks Claude to run this skill. Pre-existing changes never
trigger it, and it never blocks twice in a row. `dotfiles-setup` registers
both hooks in `~/.claude/settings.json`, which is machine-local; `/hooks`
shows them. To silence a skill that must never be tracked, add its directory
to `~/.gitignore` (on `main`).
