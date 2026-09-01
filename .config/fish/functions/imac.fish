function imac
    if test "$argv[1]" = "-d"
        ssh -o SendEnv=LC_NO_TMUX -o SetEnv=LC_NO_TMUX=1 rikards-imac
    else
        ssh rikards-imac
    end
end
