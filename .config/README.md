# Config Notes

## tmux

The active tmux config lives at:

```text
~/.config/tmux/tmux.conf
```

Current local setup:

- TPM is installed at `~/.config/tmux/plugins/tpm`.
- `tmux-resurrect` is installed at `~/.config/tmux/plugins/tmux-resurrect`.
- `tmux-continuum` is installed at `~/.config/tmux/plugins/tmux-continuum`.
- Resurrect saves are stored in `~/.config/tmux/resurrect`.
- Pane contents are captured with resurrect, including full scrollback available to tmux.
- tmux history limit is set to `100000`.
- Continuum auto-save interval is set to `5` minutes.
- Continuum auto-restore is enabled when a new tmux server starts.

Useful keys:

- `prefix + Ctrl-s`: manually save the current tmux environment.
- `prefix + Ctrl-r`: manually restore the last saved tmux environment.
- `prefix + I`: install TPM plugins listed in `tmux.conf`.
- `prefix + x`: detach client. This replaces the default `prefix + d`.
- `F12`: enter copy mode without using the prefix key.

Before rebooting:

1. Press `prefix + Ctrl-s` to force a fresh save.
2. Reboot.
3. Open a terminal and run `tmux`.
4. Continuum should restore automatically. If it does not, press `prefix + Ctrl-r`.

Restore expectations:

- Sessions, windows, panes, layouts, active panes, working directories, and many common pane processes are restored.
- Pane scrollback is restored as captured pane contents.
- Arbitrary long-running commands are not guaranteed to restart unless `tmux-resurrect` knows how to restore that process.
- Shell command history is separate from pane contents and is handled by the shell, not by resurrect.

Dotfiles follow-up:

- Mirror `tmux/tmux.conf`.
- Decide whether plugin directories should be committed, bootstrapped by TPM, or installed by a dotfiles script.
- Ensure `~/.config/tmux/resurrect` is treated as machine-local state, not shared dotfile state.

## Starship

The active Starship config lives at:

```text
~/.config/starship.toml
```

The prompt includes a custom LLM conversation counter on the main prompt info
line, just before the prompt arrow:

```text
rix1 🖥️ repo on  branch via  v3.11.11 ✻ 1 󰚩 2
➜
```

Current markers:

- `✻`: Claude / Anthropic conversations.
- `󰚩`: Codex / OpenAI conversations.

The active counter command is a compiled Rust binary:

```text
~/.config/bin/llm-conversation-count
```

The Rust source and Python fallback live at:

```text
~/.config/src/llm-conversation-count.rs
~/.config/bin/llm-conversation-count.py
```

Rebuild after changing the Rust source:

```fish
rustc -O ~/.config/src/llm-conversation-count.rs -o ~/.config/bin/llm-conversation-count
```

How it works:

- The binary checks the current working directory.
- If the directory is inside a git repo, it also checks the git root so
  subdirectories share the repo-level count.
- Claude conversations are counted from
  `~/.claude/projects/<path-encoded-directory>/*.jsonl`.
- Codex conversations are counted from `~/.codex/state_5.sqlite`, using the
  `threads.cwd` field through the system SQLite library.
- Providers with a zero count are hidden.

The icons can be overridden with environment variables:

```fish
set -gx LLM_COUNT_CLAUDE_ICON "C"
set -gx LLM_COUNT_CODEX_ICON "O"
```

Keep these as regular terminal-renderable characters. Icon-font fallback in
Ghostty was avoided because web icon fonts can break terminal text rendering.
