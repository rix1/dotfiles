function git-summary
    set -l argc (count $argv)
    
    if test $argc -eq 0
        # No arguments: show last 10 commits
        set from_commit "HEAD~10"
        set to_commit "HEAD"
    else if test $argc -eq 1
        # One argument: treat as "from" commit, to HEAD
        set from_commit $argv[1]
        set to_commit "HEAD"
    else if test $argc -eq 2
        # Two arguments: from and to commits
        set from_commit $argv[1]
        set to_commit $argv[2]
    else
        echo "Usage: git-summary [from-commit] [to-commit]"
        echo "Examples:"
        echo "  git-summary                    # Last 10 commits"
        echo "  git-summary HEAD~5             # Last 5 commits"
        echo "  git-summary 2d3dcc2fd 7096c4375 # Between specific commits"
        return 1
    end
    
    echo "Summary from $from_commit to $to_commit:"
    echo ""
    
    # Show the commit log
    git log --oneline --graph $from_commit..$to_commit
    
    echo ""
    
    # Show file changes stats
    git diff --stat $from_commit $to_commit
end