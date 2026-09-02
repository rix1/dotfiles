set -x LANG en_US.UTF-8
set -x GPG_TTY (tty)
set -gx EDITOR zed

fish_add_path /opt/homebrew/bin

source $HOME/.config/fish/aliases.fish

fzf_configure_bindings --directory=\cf

# pyenv init - | source

starship init fish | source

# Starship LLM conversation counter icons: private-use glyphs from the
# "LLM Logos" font (~/.config/fonts, mapped in Ghostty via font-codepoint-map).
# Two glyphs per logo = a two-cell, 2x-size icon. Single-cell: \U000F8001 / \U000F8002.
set -gx LLM_COUNT_CLAUDE_ICON \U000F8011\U000F8021
set -gx LLM_COUNT_CODEX_ICON \U000F8012\U000F8022
direnv hook fish | source

if test "$TERM" = "xterm-ghostty"
    set -gx TERM xterm-256color
end

if status is-interactive; and test -n "$SSH_CONNECTION"; and not set -q TMUX; and not set -q LC_NO_TMUX
    ts
end

if test -z "$SSH_AUTH_SOCK"
    set -x SSH_AUTH_SOCK (launchctl getenv SSH_AUTH_SOCK)
end


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
