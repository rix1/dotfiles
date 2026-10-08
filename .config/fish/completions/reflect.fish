# Reflect CLI (bundled in Reflect.app). Note names come from `reflect search`,
# so private notes never show up.

function __reflect_notes
    set -l token (commandline -ct)
    for offset in 0 1 2 3 4 5 6
        date -v-{$offset}d +%F
    end
    test (string length -- $token) -ge 2; or return
    reflect search --json --limit 20 -- $token 2>/dev/null \
        | jq -r '.results[] | "\(.title)\t\(.path)"'
end

set -l subcommands today search show path open help

complete -c reflect -f
complete -c reflect -l graph -d 'Graph directory' -r -F
complete -c reflect -l json -d 'Emit JSON on stdout'
complete -c reflect -s h -l help -d 'Print help'
complete -c reflect -s V -l version -d 'Print version'

complete -c reflect -n "not __fish_seen_subcommand_from $subcommands" -a today -d "Print today's daily note"
complete -c reflect -n "not __fish_seen_subcommand_from $subcommands" -a search -d 'Full-text search over the graph'
complete -c reflect -n "not __fish_seen_subcommand_from $subcommands" -a show -d 'Print a note'
complete -c reflect -n "not __fish_seen_subcommand_from $subcommands" -a path -d "Resolve a note to its absolute path"
complete -c reflect -n "not __fish_seen_subcommand_from $subcommands" -a open -d 'Open a note in the Reflect app'
complete -c reflect -n "not __fish_seen_subcommand_from $subcommands" -a help -d 'Print help for a subcommand'

complete -c reflect -n '__fish_seen_subcommand_from today' -l path -d "Print the daily note's path instead"
complete -c reflect -n '__fish_seen_subcommand_from search' -l limit -d 'Maximum number of results' -x
complete -c reflect -n '__fish_seen_subcommand_from open' -l print -d 'Print the URL without launching the app'
complete -c reflect -n '__fish_seen_subcommand_from show path open' -k -a '(__reflect_notes)'
complete -c reflect -n '__fish_seen_subcommand_from help' -a "$subcommands"
