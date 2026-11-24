# Welcome 👋

This is my personal dotfiles in its current (most likely not final) form. It's
a git bare repo with `$HOME` as the work tree, a Brewfile, and two small scripts
that keep each machine in sync and provisioned.

## What's included?

![Rex with fish, Starship and Claude Code](https://github.com/user-attachments/assets/9aa71898-a9d7-46a2-8024-cf47eb5682b6)

- [Fish shell](https://fishshell.com/) & [Fisher](https://github.com/jorgebucaran/fisher). Comes with [git aliases](https://github.com/jhillyerd/plugin-git), [fzf](https://github.com/PatrickF1/fzf.fish) for easy search and [z](https://github.com/jethrokuan/z) for jumping around directories, plus a pile of small functions.
- [Starship](https://starship.rs/) prompt, with a counter for LLM conversations in the current directory, drawn with a tiny font of LLM logos
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling, [television](https://github.com/alexpasmantier/television) pickers, [Zed](https://zed.dev/) keymap and snippets
- Scripts in `~/.local/bin`: `repo-status` (every repo under a folder, sorted by what needs attention), `claude-agent-view` (follow a Claude Code subagent in its own pane), `reflect-personal` (build my own [Reflect](https://reflect.app) from feature branches)
- [Claude Code](https://claude.com/claude-code) skills in `~/.claude/skills`, among them `dotfiles` (commits to this repo), `grill-me` (stress-test a plan), `under-construction` (pick up Slack messages I flagged to build) and `company-governance` (research a company's board and cap table)
- git with [delta](https://github.com/dandavison/delta), neovim, and the CLI tools the above relies on, all in one [Brewfile](../.config/Brewfile)

The terminal is [Rex](https://www.superlogical.com/rex/docs/installation). tmux config and its pickers are still here, but no
longer the daily driver.

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
- your 1Password login. The SSH key the Macs use to reach each other lives
  only in 1Password, so you never run `ssh-keygen` on a new Mac.

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

**4. Sync and set up.** Still in zsh, in Terminal:

```sh
~/.local/bin/dotfiles-sync --no-push
```

This rebases the machine branch onto the latest `main` first (a branch made
on an earlier attempt may be behind it), then runs `dotfiles-setup`. Use
`--no-push` because `gh` isn't logged in yet. `dotfiles-setup` works through
these steps in order, and each one checks before it acts:

| Step         | What it does                                                                 |
| ------------ | ---------------------------------------------------------------------------- |
| homebrew     | stops here if `brew` is missing                                              |
| brewfile     | `brew bundle install` for anything in `~/.config/Brewfile` that is missing   |
| login shell  | adds fish to `/etc/shells` (sudo), then `chsh -s` (asks for your password)   |
| fisher       | registers the checked-out plugins with fisher, then `fisher update`          |
| tmux         | clones tpm, installs the plugins from `tmux.conf`                            |
| fonts        | copies `~/.config/fonts/*.otf` to `~/Library/Fonts`                          |
| ghostty      | adds the `font-codepoint-map` line for the LLM logo glyphs                   |
| starship     | builds the conversation counter with `rustc`, or links the Python fallback   |
| link router  | where the Search browser is installed: clones Link Router to `~/Development`, builds it into `~/Applications`, says how to make it the default browser |
| ssh          | points `~/.ssh/config` at the 1Password agent, trusts `~/.config/ssh/authorized_keys`; checks the switches in step 8 |
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

`conf sync` runs `conf setup` again. With Search installed and `gh` logged in,
it can now clone Link Router (a private repo) and build it; it prints the one
command that makes it the default browser.

**8. SSH between the Macs.** One key, "SSH – Macs", lives in 1Password and
every Mac trusts it. [`agent.toml`](../.config/1Password/ssh/agent.toml) makes
the 1Password agent offer only that key, and `conf setup` has already written
`~/.ssh/config` and `authorized_keys`. Three switches have no reliable CLI, so
flip them by hand; `conf setup` reports which are still off:

- 1Password: sign in, then Settings → Developer → **Use the SSH agent**.
  Quit and reopen 1Password once, so it picks up `agent.toml`.
- System Settings → General → Sharing → **Remote Login**.
- [Tailscale](https://tailscale.com/download): install and log in. Leave
  Tailscale SSH off; plain sshd with the key is what the Macs use.

Then check both directions from the other Mac and from this one. Both must
work with 1Password unlocked, without a password prompt:

```fish
ssh -o BatchMode=yes <other-mac> true; and echo ok
```

## Day to day

Every machine has its own branch (`mbp`, `imac`) that is `main` plus a few
machine-specific commits. Shared changes go on `main`, machine-specific ones on
the machine branch. `conf sync` rebases this machine's branch onto `main`,
pushes it, and runs `conf setup` (`dotfiles-setup`); both are idempotent, so
run them whenever. A tool that every machine needs goes in the Brewfile, and
the next `conf sync` installs it everywhere.

The full workflow, including how to commit to `main` without checking it out
in `$HOME`, is in [`.config/AGENTS.md`](../.config/AGENTS.md). What the
individual tools do and how to rebuild them is in
[`.config/README.md`](../.config/README.md).

### Navigating the configuration

```
$HOME
├── .claude/skills/       # Claude Code skills (SKILL.md + scripts); the rest of .claude is ignored
├── .config/              # Most config goes here
│      ├── AGENTS.md      # How the repo works: branches, conf, what to commit where
│      ├── Brewfile       # What every machine needs; installed by dotfiles-setup
│      ├── README.md      # What the tools do
│      ├── 1Password/ssh/agent.toml   # the one key the SSH agent offers
│      ├── aerospace/
│      ├── bin/ src/      # Starship conversation counter (Rust, Python fallback), vtt2text
│      ├── fish/
│      ├── fonts/         # LLM Logos font and its build script
│      ├── gh/ git/       # gh config, global gitignore
│      ├── pgcli/ litecli/
│      ├── ssh/authorized_keys      # public keys every Mac trusts
│      ├── starship.toml
│      ├── television/
│      ├── tmux/
│      └── zed/
├── .dotfiles/            # Bare repo - you shouldn't change anything here
├── .gitconfig .gitignore .editorconfig .vimrc
├── .github/README.md     # This file
└── .local/bin/           # dotfiles-sync, dotfiles-setup, repo-status, tmux-picker, ...
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

- Is something wrong with the fonts? Every character should render as a
  distinct glyph, not a box:
  ```fish
  echo \ue0b0 \u00b1 \ue0a0 \u27a6 \u2718 \u26a1 \u2699
  ```
- `dotfiles-setup` changes the login shell when it runs in a terminal. To do
  it by hand: `echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells`, then
  `chsh -s /opt/homebrew/bin/fish`.
- `conf: command not found` or `dotfiles-sync: command not found`: `conf` is a
  fish function and the scripts are in `~/.local/bin`, which
  `conf.d/00_path.fish` puts on PATH. In zsh, use the alias from step 3 and
  the full path `~/.local/bin/dotfiles-setup`.

- `fisher: Cannot install "…": please remove or move conflicting files
  first`, and `fish_plugins` is gone afterwards: plain `fisher update` on a
  machine where fisher has no record of the plugins (whose files are tracked
  here) does that. Run `conf setup` instead: it restores `fish_plugins` and
  registers the plugins with fisher before updating them.
