function fmtmsg --description "Convert \\n sequences to real newlines (for LLM commit messages)"
    if test (count $argv) -gt 0
        printf '%b' (string join ' ' $argv)
    else
        while read -l line
            printf '%b\n' "$line"
        end
    end
end
