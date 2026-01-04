function copy_commit
    if test (count $argv) -eq 0
        echo "Error: Please provide a commit SHA"
        return 1
    end
    
    set -l sha $argv[1]
    git show -s $sha --format="%B" | pbcopy
    echo "Commit message for $sha copied to clipboard"
end