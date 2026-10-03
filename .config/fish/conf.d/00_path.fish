# fish sources conf.d alphabetically and before config.fish, so this runs
# first: everything after it (fnm, starship, direnv, ...) can assume Homebrew
# and ~/.local/bin are on PATH, also on a machine where fish never ran before.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

# dotfiles-sync, dotfiles-setup, tmux-picker, and curl-installed tools (claude, uv)
fish_add_path --global $HOME/.local/bin
