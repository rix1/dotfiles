function git-lm --description "Browse files by when they were last modified (git last-modified); preview that commit's diff"
    set -l target_path $argv[1]; or set -l target_path '.'

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'git-lm: Not in a git repository.' >&2
        return 1
    end

    # One row per file: "<hash> [<age>] <author><TAB><path>". The tab keeps
    # the path apart from an author name that may contain spaces.
    git last-modified $target_path -r | while read -l commit file
        printf '%s\t%s\n' (git show -s --format='%h [%ar] %an' --abbrev=7 $commit | string sub -l 70) $file
    end | tv --no-sort \
        --input-header 'Last modified' \
        --source-output '{split:\t:1}' \
        --preview-command "git show --color=always -p '{split: :0}' -- '{split:\t:1}'" \
        --preview-size 60
end
