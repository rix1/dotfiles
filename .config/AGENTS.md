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
  `imac` SSH helper, `fish_variables`.
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

## Committing to `main` from a machine

`$HOME` has the machine branch checked out. **Do not `conf checkout main` in
`$HOME`.** That rewrites live files (Zed's prompt database, AeroSpace config)
and deletes files that only the machine branch tracks, such as
`fish_variables`, while fish is running.

A `conf rebase` in `$HOME` does the same thing for a moment, so don't do that
either. Use a linked worktree for both steps:

```sh
W=/tmp/dotfiles-main
conf fetch
conf branch -f main origin/main                    # main is never checked out in $HOME, so this is safe
conf worktree add $W main
rsync -R .config/path/to/changed-file $W/          # copy the changed files in, paths preserved
git -C $W add .config/path/to/changed-file
git -C $W commit --no-gpg-sign -m "scope: what changed"
git -C $W push origin main
```

Then rebase the machine branch (`mbp` here, `imac` there) without touching
`$HOME`:

```sh
BRANCH=mbp
git -C $W checkout -b rebase-tmp $BRANCH
git -C $W -c commit.gpgsign=false rebase main      # rebase re-creates commits, so it would try to sign
conf update-ref refs/heads/$BRANCH rebase-tmp      # move the branch pointer
conf reset -q                                      # resync the index in $HOME (mixed reset, no file changes)
conf worktree remove --force $W
conf branch -D rebase-tmp
conf push --force-with-lease origin $BRANCH
```

`conf status` should afterwards show the same thing it showed before, except
that the shared change is now committed. On the other machine, skip the
commit block and run just the fetch, `branch -f`, `worktree add` and the
rebase block for its own branch.

Expect one recurring conflict: `main` stopped tracking
`.config/fish/fish_variables` (see below) while older overlay commits still
modify it. Resolve each one by keeping the deletion:

```sh
git -C $W rm -q .config/fish/fish_variables
GIT_EDITOR=true git -C $W -c commit.gpgsign=false rebase --continue
```

Overlay commits that duplicate something `main` did in the meantime become
empty and are dropped automatically; if `--continue` complains that a
commit is empty, `rebase --skip` it. Verified on 2026-09-02: rebasing
`origin/imac` onto `main` hits this twice and ends with three overlay
commits.

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
- `~/.github/README.md`: the public-facing README. Partly stale (it still
  describes a deleted Deno installer); this file is the current source of
  truth for the workflow.
