function ts --description "Browse and select tmux sessions with tv"
    set -l sessions (tmux list-sessions 2>/dev/null)

    if test -z "$sessions"
        read -P "No sessions. Create one? Name (empty for default): " session_name
        if test -n "$session_name"
            tmux new-session -s $session_name
        else
            tmux new-session
        end
        return
    end

    # Rows and preview come from ~/.local/bin/tmux-picker, sized to this terminal.
    set -lx TMUX_PICKER_COLS (tput cols)
    set -lx TMUX_PICKER_LINES (tput lines)
    set -l session (tv tmux-picker-sessions)

    or return 0

    if set -q TMUX
        tmux switch-client -t $session
    else
        tmux attach -t $session
    end
end
