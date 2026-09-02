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

## Fish

Custom commands live in `~/.config/fish/functions/`, with tab completions in
`~/.config/fish/completions/`. Helper scripts they depend on live in
`~/.config/bin/`.

### yt-transcript

Downloads the captions of a YouTube video and prints them as plain text, for
pasting into an LLM conversation or saving as notes.

```fish
yt-transcript --llm 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' | pbcopy
yt-transcript -l nb -o talk.txt https://youtu.be/dQw4w9WgXcQ
yt-transcript --list 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
```

Quote URLs that contain `?`: fish 3.x treats `?` as a wildcard (the
`qmark-noglob` feature flag turns that off, `set -U fish_features qmark-noglob`).

Options:

- `-l, --lang LANG`: caption language code, default `en`. yt-dlp names
  auto-caption tracks inconsistently: the spoken-language track is often
  `en-orig`, and translations are either plain codes (`no`) or
  `<target>-<source>` (`en-no`). The pattern therefore matches `LANG`,
  `LANG-orig` and `LANG-<source>`, preferring the original, then the exact
  code. A track other than `LANG` is reported on stderr. yt-dlp regex syntax
  is accepted.
- `-o, --output FILE`: write to a file instead of stdout.
- `--llm`: prepend a preamble with title, channel, publish date, duration,
  URL, caption source (uploader subtitles or auto-generated), download date
  and chapters, and wrap the text in `--- BEGIN/END TRANSCRIPT ---` markers.
- `--no-timestamps`: drop the per-minute `[m:ss]` markers.
- `--list`: show the caption languages yt-dlp can see for the video.

How it works:

- `yt-dlp --skip-download --write-subs --write-auto-subs --sub-format vtt
  --write-info-json` fetches the VTT and metadata into a temp dir. Uploader
  subtitles win over auto-generated captions for the same language.
- `~/.config/bin/vtt2text.py` (Python, stdlib only) removes YouTube's rolling
  duplicate lines and inline timing tags, decodes HTML entities, and groups
  the text into one paragraph per minute of video. It works on any `.vtt`
  file on its own:

```fish
python3 ~/.config/bin/vtt2text.py --llm --info video.info.json video.en.vtt
```

Requires `yt-dlp` and `python3` (`brew install yt-dlp`).
