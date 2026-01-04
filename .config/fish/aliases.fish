
# alias l='ls -hltr'
# alias ll="ls -haltr"
#
alias l='eza -lh --no-user --no-permissions --sort=modified --git --git-ignore'
alias ll='eza -lh --all --no-user --no-permissions --sort=modified --git'

alias gcmsg='git commit -m'

alias cat=bat

# Region Cloud
alias woc='z cloud'
alias rss='gunicorn -w2 -t120 --reload --bind 0.0.0.0:8000 cloud.wsgi'
alias rssp='ENVIRONMENT=production gunicorn -w2 -t120 --reload cloud.wsgi'
# Endregion Cloud

alias pp=pnpm

# Region kubernetes
alias kb=kubectl
alias cs_old='kubectl exec -it (kubectl get pods -o custom-columns=:metadata.name -n cloud | grep web | head -n1) -n cloud -- bash -c "python manage.py shell"'
alias cs='/Users/rix1/Development/otovo/cloud/scripts/k8s-shell.sh'
alias wip='git add . && git commit -m "wip"'

alias tree='eza -T'


abbr --add djl djlint --reformat
