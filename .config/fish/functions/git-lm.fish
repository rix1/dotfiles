function git-lm --description "Search files by last modification time with git last-modified, preview diffs."
    set -l target_path $argv[1]; or set -l target_path '.'

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'git-lm: Not in a git repository.' >&2
        return 1
    end

    # Set preview command
    set -f preview_cmd 'git show --color=always -p {1} -- {2..}'
    if set --query fzf_diff_highlighter
        set preview_cmd "$preview_cmd | $fzf_diff_highlighter"
    end

    # Format git last-modified output with colors
    git last-modified $target_path -r | while read -la line
        set parts (string split '        ' $line)
        # echo "$(string sub -l 10 $parts[1]) $parts[2]"
        # echo "$(git show -s --format='%h [%ar] %an %s' $parts[1] --abbrev=7)" | string sub -l 70
        set result (echo "$(git show -s --format='%h [%ar] %an' $parts[1] --abbrev=7)" | string sub -l 70)
        echo "$result $parts[2]"
    end | _fzf_wrapper --ansi \
        --multi \
        --prompt="Git Last Modified> " \
        --preview=$preview_cmd \
        --preview-window=right:60% \
        --header 'Select files to view changes (last modified)' \
        $fzf_git_log_opts

    commandline --function repaint
end
