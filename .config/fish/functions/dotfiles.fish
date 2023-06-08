function dotfiles -w "git" -d "Work with git in my dotfiles bare repo"
  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
  echo ''
  echo '💡 ds => dotfiles'
end