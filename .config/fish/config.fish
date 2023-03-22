set -x LANG en_US.UTF-8
set -x GPG_TTY (tty)
set -gx EDITOR subl

fish_add_path /opt/homebrew/bin

starship init fish | source

source $HOME/.config/fish/aliases.fish

fzf_configure_bindings --git_log=\cl --directory=\cf

pyenv init - | source

# set -x ANDROID_HOME $HOME/Library/Android/sdk
# set -U fish_user_paths $HOME/Library/Android/sdk/platform-tools $fish_user_paths


# Kubernetis autocompletion
# kubectl completion fish | source


__fish_complete_django django-admin.py
__fish_complete_django manage.py
