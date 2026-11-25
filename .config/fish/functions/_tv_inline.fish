function _tv_inline --description "Run tv below the prompt and print what was picked"
    # The picker draws in the free space under the prompt (--inline), so step
    # onto a fresh line first and back up afterwards; fish then repaints the
    # prompt where it was. Callers capture stdout, hence stderr for the moves.
    printf "\n" >&2

    # A source that prints nothing (no treehouse pool here, a clean git
    # status) makes tv list this notice as if it were an entry. Never return it.
    # A pipe rather than a command substitution: tv has to keep this
    # function's stdin, which is how _tv_history hands it the entries.
    tv $argv --inline --no-status-bar \
        | string match -v -- 'Command produced no output on stdout, checking stderr...'
    set -l picked $pipestatus[1]

    printf "\033[A" >&2
    commandline -f repaint
    return $picked
end
