
alias l='exa'
alias ll="exa -l -g --icons --git"
alias llt="exa -1 --icons --tree --git-ignore"

alias gcmsg='git commit -m'

alias cat=bat

# Region Cloud
alias woc='z cloud && vf activate cloud'
alias rss='gunicorn -w2 -t120 --reload cloud.wsgi'
# Endregion Cloud

alias pp=pnpm

# Region kubernetes
alias kb=kubectl
alias cs='kubectl exec -it (kubectl get pods -o custom-columns=:metadata.name -n cloud | grep web | head -n1) -n cloud -- bash -c "python manage.py shell"'
