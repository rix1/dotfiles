function ds -w "git" -d "Work with git in my dotfiles bare repo"
  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
end