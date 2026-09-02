# Config Notes

How the dotfiles repo itself works (bare repo, `conf`, the `main` vs
`mbp`/`imac` branch model, what to commit where) is documented in
[`AGENTS.md`](AGENTS.md). This file is about what the individual tools do.

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

Plugins are not committed. `dotfiles-setup` (`conf setup`) clones TPM and
installs the plugins listed in `tmux.conf`; `~/.config/tmux/resurrect` is
machine-local state and stays untracked.

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

Current markers (private-use glyphs, rendered by the "LLM Logos" font). Each
logo exists in two sizes: a single-cell glyph sized to cap height, and a
two-cell version (about 2x) made of a left and a right half that are printed
back to back. The two-cell version is the default.

| Logo          | Single cell | Two cells (left + right) |
| ------------- | ----------- | ------------------------ |
| Claude        | `U+F8001`   | `U+F8011` `U+F8021`      |
| OpenAI/Codex  | `U+F8002`   | `U+F8012` `U+F8022`      |
| Anthropic "A" | `U+F8003`   | `U+F8013` `U+F8023`      |

The glyphs are set in `~/.config/fish/config.fish` through
`LLM_COUNT_CLAUDE_ICON` / `LLM_COUNT_CODEX_ICON`, and Ghostty maps the
codepoint range to the font with
`font-codepoint-map = U+F8000-U+F80FF=LLM Logos` in its config
(`~/Library/Application Support/com.mitchellh.ghostty/config`). Any machine that
displays the prompt (the one running Ghostty, also when SSHing into another)
needs the font installed and the Ghostty line present; `dotfiles-setup`
(`conf setup`) does both.

See the "Fonts" section below for how the font is built. The old text fallbacks
were `✻` (Claude) and the Nerd Font robot `󰚩` (Codex); set the env vars to
those if the font is missing.

The active counter command is a compiled Rust binary:

```text
~/.config/bin/llm-conversation-count
```

The Rust source and Python fallback live at:

```text
~/.config/src/llm-conversation-count.rs
~/.config/bin/llm-conversation-count.py
```

Rebuild after changing the Rust source (`dotfiles-setup` does this whenever
the source is newer than the binary, and links the Python fallback when
there is no `rustc`):

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

## Fonts

`~/.config/fonts/` holds a tiny OpenType font, `LLMLogos.otf`, with nine
glyphs at private-use codepoints (see the Starship section). It is generated
from the Simple Icons SVGs (CC0) in `fonts/simple-icons/` by
`fonts/build-llm-logos.py`, which reads the units-per-em, advance width, cap
height and ascent/descent from `~/Library/Fonts/iAWriterMonoV.ttf`. The
single-cell glyphs fit one cell centred on cap height. The two-cell glyphs are
the same logo at ~2x, centred in the full line height, split down the middle
with skia-pathops so each half is clipped to its own cell and nothing relies
on the terminal drawing outside a cell.

Rebuild after changing the SVGs or the sizing, then `conf setup` installs it:

```fish
uv run --with fonttools --with skia-pathops python ~/.config/fonts/build-llm-logos.py ~/.config/fonts/LLMLogos.otf ~/.config/fonts/simple-icons
```

Ghostty picks up new fonts in new windows/tabs. `ghostty +list-fonts
--family="LLM Logos"` confirms it resolves. The range `U+F8000`–`U+F8FFF` was
chosen because Nerd Fonts do not use it, so the mapping cannot shadow an
existing icon.
