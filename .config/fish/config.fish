set -x LANG en_US.UTF-8
set -x GPG_TTY (tty)
set -gx EDITOR subl

fish_add_path /opt/homebrew/bin

source $HOME/.config/fish/aliases.fish

fzf_configure_bindings --directory=\cf

# pyenv init - | source

starship init fish | source
direnv hook fish | source


