# Completions for baton: hand a Claude Code session, with its code, to another Mac.
# Machines and sessions are read from baton itself, so they are always current.

# Positional words typed so far, starting with the subcommand.
function __baton_words
    set -l skip 0
    for token in (commandline -xpc)[2..]
        if test $skip -eq 1
            set skip 0
            continue
        end
        switch $token
            case --session --name --from --as --reachable-as
                set skip 1
            case '-*'
            case '*'
                echo -- $token
        end
    end
end

function __baton_no_command
    test (count (__baton_words)) -eq 0
end

# __baton_in to pull   → the subcommand is one of these
function __baton_in
    set -l words (__baton_words)
    contains -- "$words[1]" $argv
end

# __baton_at pull 1    → the cursor is on the first argument of "pull"
function __baton_at -a command position
    set -l words (__baton_words)
    test "$words[1]" = $command; and test (count $words) -eq $position
end

# Paired machines, with the SSH name each one is reached by.
function __baton_machines
    set -l dir ~/.config/baton
    set -q BATON_CONFIG_DIR; and set dir $BATON_CONFIG_DIR
    test -r $dir/config.json; or return
    string join ' ' <$dir/config.json \
        | string match -rag '"([^"]+)":\s*\{\s*"ssh":\s*"([^"]*)"' \
        | while read -l name; and read -l ssh
        printf '%s\t%s\n' $name $ssh
    end
end

# Sessions this machine knows. "away" keeps only the ones on another machine.
function __baton_sessions -a which
    command baton status --offline --json 2>/dev/null \
        | string match -rag '"session":"([^"]+)","project":"([^"]*)","on":"([^"]*)","here":(true|false)' \
        | while read -l name; and read -l project; and read -l on; and read -l here
        test "$which" = away -a $here = true; and continue
        printf '%s\t%s on %s\n' $name $project $on
    end
end

# Claude conversations started in this worktree, newest first.
function __baton_conversations
    set -l top (command git rev-parse --show-toplevel 2>/dev/null); or return
    set -l claude ~/.claude
    set -q CLAUDE_CONFIG_DIR; and set claude $CLAUDE_CONFIG_DIR
    set -l files $claude/projects/(string replace -ra '[^A-Za-z0-9]' - -- $top)/*.jsonl
    test (count $files) -gt 0; or return
    for file in (command ls -t $files)
        printf '%s\t%s\n' (string sub -l 8 -- (path basename $file)) (command stat -f '%Sm' -t '%d %b %H:%M' $file)
    end
end

complete -c baton -f

# Commands
complete -c baton -n __baton_no_command -a to -d 'Send the session in this worktree to another machine'
complete -c baton -n __baton_no_command -a pull -d 'Bring a session back and open Claude on it here'
complete -c baton -n __baton_no_command -a status -d 'Where every session is and what Claude is doing'
complete -c baton -n __baton_no_command -a pair -d 'Connect this machine with another'
complete -c baton -n __baton_no_command -a doctor -d 'Check both machines are ready'
complete -c baton -n __baton_no_command -a project -d 'Say where a repository lives on this machine'
complete -c baton -n __baton_no_command -a recover -d 'Settle a handoff that was cut off'
complete -c baton -n __baton_no_command -a forget -d 'Stop tracking a session here'
complete -c baton -n __baton_no_command -a help -d 'Help for a command'
complete -c baton -n __baton_no_command -l version -d 'Print the version'

# Everywhere
complete -c baton -s h -l help -d 'Help for this command'
complete -c baton -l json -d 'Machine-readable output'
complete -c baton -s v -l verbose -d 'Show error codes and traces'
complete -c baton -l no-color -d 'Plain output'

# to [machine]
complete -c baton -n '__baton_at to 1' -a '(__baton_machines)'
complete -c baton -n '__baton_in to' -l session -x -k -a '(__baton_conversations)' -d 'Move this conversation instead of the newest'
complete -c baton -n '__baton_in to' -l name -x -d 'Call the session something other than its branch'
complete -c baton -n '__baton_in to' -l idle -d 'Claude waits for your next message (default)'
complete -c baton -n '__baton_in to' -l remote-control -d 'Start Claude there with Remote Control'

# pull [session]
complete -c baton -n '__baton_at pull 1' -a '(__baton_sessions away)'
complete -c baton -n '__baton_in pull' -l from -x -a '(__baton_machines)' -d 'Where the session is'

# to and pull
complete -c baton -n '__baton_in to pull' -l continue -d 'Claude picks up the task where it stopped'
complete -c baton -n '__baton_in to pull' -l interrupt -d 'Stop Claude even if it is mid-turn'
complete -c baton -n '__baton_in to pull' -l no-launch -d 'Move everything but do not start Claude'
complete -c baton -n '__baton_in to pull' -s n -l dry-run -d 'Show what would happen and change nothing'
complete -c baton -n '__baton_in to pull' -s y -l yes -d 'Do not ask for confirmation'

# status
complete -c baton -n '__baton_in status' -l offline -d 'Do not ask the other machines'

# pair <name> <ssh-host>
complete -c baton -n '__baton_at pair 2' -a '(__fish_print_hostnames)'
complete -c baton -n '__baton_in pair' -l as -x -d 'What this machine is called'
complete -c baton -n '__baton_in pair' -l reachable-as -x -a '(__fish_print_hostnames)' -d 'How the other machine reaches this one'

# project add [name] [path] | ls
complete -c baton -n '__baton_at project 1' -a add -d 'Say where a repository lives here'
complete -c baton -n '__baton_at project 1' -a ls -d 'Repositories baton knows here'
complete -c baton -n '__baton_in project; and test (count (__baton_words)) -ge 2' -a '(__fish_complete_directories)'

# recover [session], forget <session>
complete -c baton -n '__baton_at recover 1' -a '(__baton_sessions)'
complete -c baton -n '__baton_at forget 1' -a '(__baton_sessions)'

# help <command>
complete -c baton -n '__baton_at help 1' -a 'to pull status pair doctor project recover forget'
