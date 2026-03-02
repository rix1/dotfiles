function gbda -d "Delete all branches merged in current HEAD, including squashed"
  argparse g/gone -- $argv; or return

  # Default branch: prefer origin/HEAD if available, else main/master
  set -l default_branch (command git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | string replace -r '^origin/' '')
  if test -z "$default_branch"
    for b in main master develop
      if command git show-ref --verify --quiet refs/heads/$b
        set default_branch $b
        break
      end
    end
  end
  test -n "$default_branch"; or begin
    echo "gbda: could not determine default branch" >&2
    return 1
  end

  if set -ql _flag_gone
    for b in (command git for-each-ref refs/heads/ --format="%(refname:short) %(upstream:track)" | command awk '$2 == "[gone]" { print $1 }')
      command git branch -D -- $b
    end
  end

  for b in (command git branch --merged | command grep -vE '^\*|^\+|^\s*(master|main|develop)\s*$' | string trim)
    command git branch -d -- $b
  end

  command git for-each-ref refs/heads/ --format="%(refname:short)" | while read -l branch
    set -l merge_base (command git merge-base $default_branch $branch)
    if string match -q -- '-*' (command git cherry $default_branch (command git commit-tree (command git rev-parse $branch\^{tree}) -p $merge_base -m _))
      command git branch -D -- $branch
    end
  end
end
