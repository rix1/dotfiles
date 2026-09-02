function conf --wraps git --description 'alias for a bare git repo to manage dotfiles'
    switch "$argv[1]"
        case sync
            # rebase this machine's branch onto origin/main, then dotfiles-setup
            dotfiles-sync $argv[2..]
        case setup
            # idempotent per-machine provisioning (fish, fisher, tpm, fonts, ghostty)
            dotfiles-setup $argv[2..]
        case '*'
            /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
    end
end
