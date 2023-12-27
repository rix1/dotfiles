function configure -w "configure dotfiles" -d "Rix: Alias git to work with dotfiles"
  echo "🚧 Entering maintenance mode for $USERNAME: git will be aliased to work with dotfiles"
  alias git='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
end

