set -x LANG en_US.UTF-8
set -x GPG_TTY (tty)
set -gx EDITOR subl

fish_add_path /opt/homebrew/bin

source $HOME/.config/fish/aliases.fish

fzf_configure_bindings --git_log=\cl --directory=\cf

# set -x ANDROID_HOME $HOME/Library/Android/sdk
# set -U fish_user_paths $HOME/Library/Android/sdk/platform-tools $fish_user_paths
fish_add_path /opt/homebrew/opt/postgresql@15/bin/

# Kubernetis autocompletion
# kubectl completion fish | source


__fish_complete_django django-admin.py
__fish_complete_django manage.py

starship init fish | source
