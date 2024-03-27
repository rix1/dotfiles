
alias l='ls -l'
alias ll='ls -la'
alias gcmsg='git commit -m'

alias cat=bat

# Region Cloud
alias rss='gunicorn -w2 -t120 --reload cloud.wsgi'
# Endregion Cloud

alias pp=pnpm

# Region kubernetes
alias kb=kubectl
alias cs='kubectl exec -it (kubectl get pods -o custom-columns=:metadata.name -n cloud | grep web | head -n1) -n cloud -- bash -c "python manage.py shell"'
