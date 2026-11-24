function _tv_complete --description "Complete the token under the cursor with tv"
    # Usage: _tv_complete [CHANNEL]
    # Without a channel, tv picks one from the command being typed
    # ([shell_integration.channel_triggers] in television/config.toml), so
    # `git checkout <ctrl-t>` lists branches and `cat <ctrl-t>` lists files.
    #
    # A token that starts with an existing directory (`src/comp`) becomes the
    # directory to search in (`src/`) and the query (`comp`).
    set -l token (commandline --current-token --tokens-expanded | string collect)
    set -l dir ''
    set -l query $token
    if string match -q '*/*' -- $token
        set -l base (string replace -r '[^/]*$' '' -- $token)
        if test -d "$base"
            set dir $base
            set query (string replace -r '^.*/' '' -- $token)
        end
    end

    set -l target --autocomplete-prompt (commandline --current-process --cut-at-cursor | string collect)
    set -q argv[1]; and set target $argv[1]

    set -l in_dir
    test -n "$dir"; and set in_dir $dir

    set -l picks (_tv_inline $target $in_dir --input "$query" --keybindings 'enter="confirm_selection"')
    or return
    # Esc exits 0 with nothing picked.
    set -q picks[1]; or return

    commandline -t ''
    for pick in $picks
        commandline -i -- (string escape -- $dir$pick)' '
    end
end
