# Dotfiles: how this repository works

Read this before committing anything under `$HOME` that the dotfiles repo
tracks. It applies to humans and agents alike.

## Layout

The dotfiles are a **bare git repository** at `~/.dotfiles` whose work tree is
`$HOME`. There are no symlinks; files live where their programs expect them,
and git only knows about the ones that were explicitly added
(`status.showUntrackedFiles = no`, so untracked files are invisible).

Always talk to it through the `conf` fish function (`ds` is the same thing):

```sh
conf status
conf add .config/fish/functions/ts.fish
conf commit --no-gpg-sign -m "fish: add ts session picker"
conf log --oneline -10
```

`conf` expands to `git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`. Plain
`git` in `$HOME` does nothing useful. Agents cannot sign commits (no GPG
passphrase), so always pass `--no-gpg-sign`.

## Branch model

```text
 main ──●──●──●──●──●──●──●──▶   shared configuration
          \                 \
 imac      ●──●              ●──●    machine overlay, checked out on the iMac
                              \
 mbp                           ●──●──●──●   machine overlay, checked out on the MacBook
```

- **`main`** holds everything that is the same on every machine: fish
  functions and config, television, tmux, git, starship, the fonts, this file.
- **`mbp`** and **`imac`** are *machine overlays*. Each is `main` plus a
  handful of commits with machine-specific values: AeroSpace gaps and borders,
  Zed remote projects and prompt library, the Starship prompt symbol, the
  `imac` SSH helper.
- The machine branches are **never merged into `main`** and never into each
  other. They are always **rebased on top of `main`**, so that `main..mbp`
  and `main..imac` stay short lists of overrides. Their history is rewritten
  on every rebase and they are pushed with `--force-with-lease`.
- Each machine has its own branch checked out in `$HOME`. This machine (the
  MacBook) is on `mbp`.

## Where does a change go?

| The change...                                             | Commit on |
| --------------------------------------------------------- | --------- |
| would be correct on both machines                         | `main`    |
| only makes sense here (paths, hosts, screen sizes, fonts) | the machine branch |
| is machine *state* (caches, plugin checkouts, credentials) | nowhere: leave it untracked |

Ask "would the other machine want this line?" If yes, it is `main`.

## Day to day: `conf sync` and `conf setup`

Getting shared changes onto a machine is one command:

```sh
conf sync              # fetch, rebase this machine's branch onto origin/main, push, then conf setup
conf sync --dry-run    # only say what would happen
```

`conf sync` runs `~/.local/bin/dotfiles-sync`. It rebases in a temporary
linked worktree, moves the branch pointer, and then updates `$HOME` with
git's two-tree merge: only files that changed on `main` are written, local
edits to other files are kept, and a local edit to a file `main` also
changed aborts the whole run with nothing touched. Files `main` stopped
tracking that you have edited locally (`fish_variables`) stay on disk and
become untracked. Overlay commits that conflict only because `main` deleted
a file are resolved by keeping the deletion; any other conflict aborts and
tells you. It is idempotent and pushes with `--force-with-lease`.

`conf setup` runs `~/.local/bin/dotfiles-setup`, the per-machine
provisioning: fish >= 4, fisher plugins from `fish_plugins`, tpm and the tmux
plugins, fonts from `~/.config/fonts` into `~/Library/Fonts`, the Ghostty
`font-codepoint-map` line, the Starship counter binary, and a list of missing
CLI tools (reported, never installed). Every step checks before acting, so
run it whenever.

Fresh machine, before the scripts exist locally:

```sh
git clone --bare https://github.com/rix1/dotfiles ~/.dotfiles
alias conf='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
conf config status.showUntrackedFiles no
conf checkout imac              # this machine's branch; for a new machine: conf checkout -b <name> main
~/.local/bin/dotfiles-sync      # from then on: conf sync
```

## Committing to `main` from a machine

`$HOME` has the machine branch checked out. **Do not `conf checkout main` in
`$HOME`.** That rewrites live files (Zed's prompt database, AeroSpace config,
`starship.toml`) underneath the programs using them, and deletes anything
only the machine branch tracks. A `conf rebase` in `$HOME` does the same
thing for a moment. Commit through a linked worktree instead, then let
`conf sync` put the machine branch back on top:

```sh
W=$(mktemp -d)/main
conf fetch
conf branch -f main origin/main                    # main is never checked out in $HOME, so this is safe
conf worktree add $W main
rsync -R .config/path/to/changed-file $W/          # copy the changed files in, paths preserved
git -C $W add .config/path/to/changed-file
git -C $W commit --no-gpg-sign -m "scope: what changed"
git -C $W push origin main
conf worktree remove --force $W
conf sync
```

`conf status` shows the same thing before and after, minus the change that
is now committed.

## Seeing all branches

Only your own machine's branch is checked out locally. The other machine's
branch lives on `origin`, and a local copy of it (if one exists) is probably
stale. Always look at `origin/<branch>`:

```sh
conf fetch
conf show-branch main mbp origin/imac
conf log --oneline --graph --decorate --simplify-by-decoration main mbp origin/imac
```

## Committing to the machine branch

Ordinary `conf add` / `conf commit` in `$HOME`. Prefix the message with the
tool and say which machine when it matters, e.g. `aerospace: mbp overrides —
no borders`.

## Never commit

- Secrets and credentials: `.config/sanity/`, `.config/GAMConfig/`,
  `gh/hosts.yml`, anything under `op/`, `gcloud/`, `stripe/`. `~/.gitignore`
  lists the known ones and the repo is public.
- Machine state: tmux plugin checkouts and `tmux/resurrect/`, fish's
  `conf.d/fish_frozen_key_bindings.fish` (generated by fish 4.3 during
  upgrade), caches, `*.local.json`.
- `.config/fish/fish_variables`: fish's universal variables. Fish rewrites it
  on every start, so it is permanently dirty when tracked. It is in
  `~/.gitignore`, the plugin list is in `fish_plugins` instead, and theme
  colours belong in `config.fish` (`fish_config theme choose`). Keep it out
  of every branch.

## Commit messages

`scope: Imperative summary`, where scope is the tool (`fish`, `tmux`, `zed`,
`starship`, `television`, `fonts`, `docs`). Body only when the *why* is not
obvious. One logical change per commit.

## Related docs

- `~/.config/README.md`: what the tmux, Starship, fish and font setups do and
  how to rebuild them.
- `~/.github/README.md`: the public-facing README: what is included and how
  to install on a fresh machine. This file is the source of truth for the
  workflow.
