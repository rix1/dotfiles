function open-pr --description "Browse and open PRs with fzf"
    gh pr list \
        | tail -n +4 \
        | fzf --header="Select PR to open" \
              --preview 'echo {} | awk "{print \$1}" | xargs gh pr view' \
              --preview-window=right:60%:wrap \
        | awk '{print $1}' \
        | xargs gh pr view --web
end
