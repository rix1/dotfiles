function _tv_inline --description "Run tv below the prompt and print what was picked"
    # The picker draws in the free space under the prompt (--inline), so step
    # onto a fresh line first and back up afterwards; fish then repaints the
    # prompt where it was. Callers capture stdout, hence stderr for the moves.
    printf "\n" >&2
    tv $argv --inline --no-status-bar
    set -l picked $status
    printf "\033[A" >&2
    commandline -f repaint
    return $picked
end
