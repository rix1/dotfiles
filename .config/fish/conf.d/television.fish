# television (tv) pickers on the command line. These replaced PatrickF1/fzf.fish
# and kept its keys. More in ~/.config/README.md, "television pickers".
#
#   ctrl-t      complete what is being typed: the channel follows the command
#               (git checkout -> branches, cat -> files, cd -> directories)
#   ctrl-r      history
#   ctrl-f      files
#   ctrl-alt-l  commits (inserts the short hash)
#   ctrl-alt-s  git status (inserts the paths)
#   ctrl-alt-p  processes (inserts the pid)
#   ctrl-v      environment variables (inserts the name)
#
# Which command opens which channel: [shell_integration.channel_triggers] in
# ~/.config/television/config.toml.
status is-interactive; or return
command -q tv; or return

for mode in default insert
    bind --mode $mode ctrl-t _tv_complete
    bind --mode $mode ctrl-r _tv_history
    bind --mode $mode ctrl-f '_tv_complete files'
    bind --mode $mode ctrl-alt-l '_tv_pick git-commits'
    bind --mode $mode ctrl-alt-s '_tv_pick git-status'
    bind --mode $mode ctrl-alt-p '_tv_pick procs'
    bind --mode $mode ctrl-v '_tv_pick env --source-output "{split:=:0}"'
end
