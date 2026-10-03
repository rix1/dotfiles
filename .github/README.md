# Welcome 👋

This is my personal dotfiles in its current (most likely not final) form. It's
a git bare repo with `$HOME` as the work tree, a Brewfile, and two small scripts
that keep each machine in sync and provisioned.

## What's included?

- [Fish shell](https://fishshell.com/) & [Fisher](https://github.com/jorgebucaran/fisher). Comes with [git aliases](https://github.com/jhillyerd/plugin-git), [fzf](https://github.com/PatrickF1/fzf.fish) for easy search and [z](https://github.com/jethrokuan/z) for jumping around directories.
- [Starship](https://starship.rs/) prompt, with a counter for LLM conversations in the current directory
- [tmux](https://github.com/tmux/tmux) with resurrect and continuum
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling, [television](https://github.com/alexpasmantier/television) pickers, [Zed](https://zed.dev/) settings and snippets
- git config, and a tiny font with the LLM logos the prompt uses
- [Claude Code](https://claude.com/claude-code) skills in `~/.claude/skills` (`company-governance`, `dotfiles`, `grill-me`): reusable prompts plus the scripts they need
- Bare repo with no symlinks for dotfiles 🎉

![example](https://user-images.githubusercontent.com/2470775/227767097-0907205d-33ee-4566-8a76-22621d1b985b.png)

## Setting up a new Mac

The repo is cloned as a `git --bare` repository with `$HOME` as its work tree,
so the files live where their programs expect them and nothing is symlinked.
See this [guide for more details](https://www.ackama.com/what-we-think/the-best-way-to-store-your-dotfiles-a-bare-git-repository-explained/).

### What you start with

A Mac straight out of the setup assistant: an admin account, signed in to your
Apple ID, macOS updated, and nothing else installed. Have these at hand, they
come up along the way:

- the password of your user account (`sudo`, `chsh`)
- a GitHub login (`gh auth login`; pushing a machine branch needs it)
- your GPG key, because commits are signed (`.gitconfig` has
  `commit.gpgsign = true`). If it lives on Keybase, see
  [this guide](https://blog.scottlowe.org/2017/09/06/using-keybase-gpg-macos/).

### Why the order matters

1. **Install tools before fish starts for the first time.** Fish sources
   starship, direnv, fnm and fzf on every start, so they have to exist first.
   They are all in [`~/.config/Brewfile`](../.config/Brewfile), which
   `dotfiles-setup` installs before it makes fish the login shell.
2. **Be in fish before running any `curl | sh` installer.** The installers for
   Claude Code, rustup, bun, deno and OrbStack look at the shell you run them
   from and add their PATH lines and completions to *its* config. Run them from
   zsh and they edit `~/.zshrc`, which you never use. Homebrew packages don't
   care: their fish completions go to
   `/opt/homebrew/share/fish/vendor_completions.d` and fish finds them there.
3. **Check out the dotfiles before configuring any app.** Apps then find their
   config on first launch, and the checkout can't fail because an app already
   wrote a file of the same name.

### Steps

**1. Command Line Tools.** They provide `git`, `curl` and the compilers
Homebrew needs.

```sh
xcode-select --install
```

**2. Homebrew**, using the command on [brew.sh](https://brew.sh). Skip the
"add Homebrew to your PATH" lines it prints for `~/.zprofile`: zsh is only
used for the next two steps, and fish gets Homebrew from
`~/.config/fish/conf.d/00_path.fish`.

**3. The dotfiles.** The repo is public, so cloning over HTTPS needs no login.

```sh
git clone --bare https://github.com/rix1/dotfiles ~/.dotfiles
alias conf='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
conf config status.showUntrackedFiles no
conf checkout mbp               # or imac; for a new machine: conf checkout -b <name> main
```

**4. `dotfiles-setup`.** Still in zsh, in Terminal:

```sh
~/.local/bin/dotfiles-setup
```

It works through these steps in order, and each one checks before it acts:

| Step         | What it does                                                                 |
| ------------ | ---------------------------------------------------------------------------- |
| homebrew     | stops here if `brew` is missing                                              |
| brewfile     | `brew bundle install` for anything in `~/.config/Brewfile` that is missing   |
| login shell  | adds fish to `/etc/shells` (sudo), then `chsh -s` (asks for your password)   |
| fisher       | installs the plugins listed in `~/.config/fish/fish_plugins`                 |
| tmux         | clones tpm, installs the plugins from `tmux.conf`                            |
| fonts        | copies `~/.config/fonts/*.otf` to `~/Library/Fonts`                          |
| ghostty      | adds the `font-codepoint-map` line for the LLM logo glyphs                   |
| starship     | builds the conversation counter with `rustc`, or links the Python fallback   |
| claude hooks | registers the dotfiles skill hooks in `~/.claude/settings.json`              |

**5. Switch to fish.** Quit Terminal and open Ghostty, which was installed in
step 4. You get the Starship prompt and no errors. From here on, install
everything from fish.

**6. Installers that edit shell config**, now that you are in fish. Only the
ones you need:

```fish
curl -fsSL https://claude.ai/install.sh | bash                       # Claude Code
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh       # rustc, for the Starship counter
```

Then run `conf setup` again: it now has `rustc` to build the counter binary.

**7. Accounts, then the first sync.** The git credential helper for github.com
is `gh`, so log in with it instead of setting up SSH keys:

```fish
gh auth login
conf sync                       # pushes a new machine branch; afterwards just run it whenever
```

Import your GPG key before your first commit (see "What you start with").

### Day to day

`conf sync` rebases this machine's branch onto `main`, pushes it, and runs
`conf setup` (`dotfiles-setup`). Both are idempotent, so run them whenever. A
tool that every machine needs goes in the Brewfile, and the next `conf sync`
installs it everywhere.

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
├── .claude/skills/   # Claude Code skills (SKILL.md + scripts); the rest of .claude is ignored
├── .config/          # Most config should go here
│      ├── AGENTS.md  # How the repo works: branches, conf, what to commit where
│      ├── Brewfile   # What every machine needs; installed by dotfiles-setup
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

The terminal font is iA Writer Mono, installed from the Brewfile (the LLM Logos
build script measures it). Starship and the fish plugins also use Nerd Font
glyphs. Ghostty ships those built in, so any font works there; in another
terminal, pick a patched font such as
[FiraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraCode).

### Troubleshooting

- Is something wrong with the fonts? Try `echo \ue0b0 \u00b1 \ue0a0 \u27a6
\u2718 \u26a1 \u2699`. Every character should render as a distinct glyph, not a box.
- `dotfiles-setup` changes the login shell when it runs in a terminal. To do
  it by hand: `echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells`, then
  `chsh -s /opt/homebrew/bin/fish`.
- `conf: command not found` or `dotfiles-sync: command not found`: `conf` is a
  fish function and the scripts are in `~/.local/bin`, which
  `conf.d/00_path.fish` puts on PATH. In zsh, use the alias from step 3 and
  the full path `~/.local/bin/dotfiles-setup`.

- For Celery (GDAL really) to work make sure `DYLD_LIBRARY_PATH` is set:
  ```
  ~/Desktop via  v19.3.0 on ☁️  (eu-central-1)
  ❯ echo $DYLD_LIBRARY_PATH
  /opt/homebrew/lib/
  ```
