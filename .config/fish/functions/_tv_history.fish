function _tv_history --description "Search fish history with tv and put the pick on the command line"
    # History is read in this shell rather than through the fish-history
    # channel (`fish -c history`): this session's commands are included, and
    # NUL-separated entries keep multi-line commands in one piece.
    #
    # Text already on the command line narrows the list here, in fish, instead
    # of being handed to tv as --input. tv 0.15 sometimes lists unsorted
    # results oldest first when it starts with a query, and history is only
    # useful newest first.
    set -l typed (commandline | string collect)
    set -l header History
    set -l entries --null
    if test -n "$typed"; and test -n "$(builtin history search --contains --max 1 -- $typed)"
        set header "History containing: $typed"
        set entries search --contains --null -- $typed
    else if test -n "$typed"
        # Nothing contains it literally: fall back to a fuzzy search.
        set header History --input $typed
    end

    set -l cmd (builtin history $entries | _tv_inline --source-entry-delimiter '\0' --no-sort --no-preview \
        --input-header $header | string collect)
    test $pipestatus[2] -eq 0; or return

    test -n "$cmd"; and commandline -r -- $cmd
end
