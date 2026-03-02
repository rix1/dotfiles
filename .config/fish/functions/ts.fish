function ts --description "Browse and select tmux sessions with fzf"
    set -l selection (begin
        echo "+ New session"
        tmux list-sessions 2>/dev/null
    end | fzf --header="Select tmux session" \
              --preview 'test {} != "+ New session"; and tmux list-windows -t (echo {} | cut -d: -f1) 2>/dev/null; or echo "Create a new session"' \
              --preview-window=right:50%:wrap)

    or return 0

    if test "$selection" = "+ New session"
        read -P "Session name (leave empty for default): " session_name
        if test -n "$session_name"
            tmux new-session -s $session_name
        else
            tmux new-session
        end
    else
        set -l session (echo $selection | cut -d: -f1)
        if set -q TMUX
            tmux switch-client -t $session
        else
            tmux attach -t $session
        end
    end
end
