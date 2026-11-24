function _tv_pick --description "Pick from a tv channel and insert the picks at the cursor"
    # Usage: _tv_pick CHANNEL [tv options...]
    # enter is bound to an action (checkout, ssh, ...) in several channels;
    # here it always means "insert this".
    set -l picks (_tv_inline $argv --keybindings 'enter="confirm_selection"')
    or return
    # Esc exits 0 with nothing picked.
    set -q picks[1]; or return

    for pick in $picks
        commandline -i -- (string escape -- $pick)' '
    end
end
