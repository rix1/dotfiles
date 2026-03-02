function conf --wraps git --description 'alias for a bare git repo to manage dotfiles'
    /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
end
