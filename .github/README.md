# Welcome 👋

This is my personal dotfiles in its current (most likely not final) form. It's
a git bare repo with `$HOME` as the work tree, plus two small scripts that keep
each machine in sync and provisioned.

## What's included?

- [Fish shell](https://fishshell.com/) & [Fisher](https://github.com/jorgebucaran/fisher). Comes with [git aliases](https://github.com/jhillyerd/plugin-git), [fzf](https://github.com/PatrickF1/fzf.fish) for easy search and [z](https://github.com/jethrokuan/z) for jumping around directories.
- [Starship](https://starship.rs/) prompt, with a counter for LLM conversations in the current directory
- [tmux](https://github.com/tmux/tmux) with resurrect and continuum
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling, [television](https://github.com/alexpasmantier/television) pickers, [Zed](https://zed.dev/) settings and snippets
- git config, and a tiny font with the LLM logos the prompt uses
- Bare repo with no symlinks for dotfiles 🎉

![example](https://user-images.githubusercontent.com/2470775/227767097-0907205d-33ee-4566-8a76-22621d1b985b.png)

## Installation and setup instructions

The repo is cloned as a `git --bare` repository with `$HOME` as its work tree,
so the files live where their programs expect them and nothing is symlinked.
See this [guide for more details](https://www.ackama.com/what-we-think/the-best-way-to-store-your-dotfiles-a-bare-git-repository-explained/).

```sh
git clone --bare https://github.com/rix1/dotfiles ~/.dotfiles
alias conf='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
conf config status.showUntrackedFiles no
conf checkout mbp               # or imac; for a new machine: conf checkout -b <name> main
~/.local/bin/dotfiles-sync      # from then on: conf sync
```

`dotfiles-sync` rebases the machine branch onto `main` and then runs
`dotfiles-setup`, which installs fish plugins, tmux plugins and fonts, and
reports any CLI tools that are missing. Both are idempotent, so run
`conf sync` whenever.

If you are using PGP and have your GPG key stored on Keybase, check out this
guide: https://blog.scottlowe.org/2017/09/06/using-keybase-gpg-macos/

Sidenote to self: I really recommend authenticating with Github using their CLI (`gh`), this is a lot easier than generating and setting SSH keys.

## Updating your dotfiles

Every machine has its own branch (`mbp`, `imac`) that is `main` plus a few
machine-specific commits. Shared changes go on `main`, machine-specific ones on
the machine branch, and `conf sync` puts the machine branch back on top of
`main`. The full workflow, including how to commit to `main` without checking
it out in `$HOME`, is in [`.config/AGENTS.md`](../.config/AGENTS.md). What the
individual tools do and how to rebuild them is in
[`.config/README.md`](../.config/README.md).

### Navigating the configuration

```
$HOME
├── .config/          # Most config should go here
│      ├── AGENTS.md  # How the repo works: branches, conf, what to commit where
│      ├── README.md  # What the tools do
│      ├── fish
│      ├── fonts
│      ├── starship.toml
│      ├── television
│      ├── tmux
│      └── zed
├── .dotfiles/        # Bare repo - you shouldn't change anything here
├── .gitconfig
├── .github           # Dotfiles README (the one you're currently reading)
│      └── README.md
└── .local/bin/       # dotfiles-sync and dotfiles-setup
```

## Fonts

`~/.config/fonts/` holds LLM Logos, a tiny font with the Claude and OpenAI
glyphs the Starship prompt uses. `conf setup` installs it into
`~/Library/Fonts`; see `.config/README.md` for how it is built.

The terminal font is not in the repo. Starship and the fish plugins use Nerd
Font glyphs, so pick a patched font such as
[FiraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraCode).

### Troubleshooting

- Is something wrong with the fonts? Try `echo \ue0b0 \u00b1 \ue0a0 \u27a6
\u2718 \u26a1 \u2699`. Every character should render as a distinct glyph, not a box.
- The setup script should change shell for you, but in case it doesn't here's
  how you do it: `chsh -s $(which fish)`. You might have to add
  `/opt/homebrew/bin/fish` to `/etc/shells` for this to work: `sudo echo
/opt/homebrew/bin/fish >> /etc/shells`.

- For Celery (GDAL really) to work make sure `DYLD_LIBRARY_PATH` is set:
  ```
  ~/Desktop via  v19.3.0 on ☁️  (eu-central-1)
  ❯ echo $DYLD_LIBRARY_PATH
  /opt/homebrew/lib/
  ```
