function lowres --description 'Drop the main display to a low non-Retina mode for remote Screen Sharing'
    # lowres [WxH]   switch to WxH without Retina scaling (default 1920x1080), saving the current mode
    # lowres off     restore the saved mode
    # lowres status  show the current mode and whether one is saved
    #
    # Fewer pixels means less to upload, which matters on a slow uplink. The
    # restore command is built here rather than taken from `displayplacer list`,
    # whose suggestion says `enabled:false` while the panel is asleep and would
    # switch the display off.
    if not type -q displayplacer
        echo "lowres: displayplacer is not installed (brew install displayplacer)" >&2
        return 1
    end

    set -l state_dir (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo ~/.local/state)/lowres
    set -l saved $state_dir/restore

    # displayplacer cannot change the mode of a sleeping panel (it reports it as
    # disabled), so declare user activity first; this wakes the display.
    if contains -- "$argv[1]" '' on off restore; or string match -qr '^\d+x\d+$' -- "$argv[1]"
        caffeinate -u -t 5 &
        disown
        sleep 1
    end

    # id, res, hz, color depth, scaling of the main display
    set -l cur (displayplacer list | awk '
        /^Persistent screen id:/ { id = $4 }
        /^Resolution:/           { res = $2 }
        /^Hertz:/                { hz = $2 }
        /^Color Depth:/          { cd = $3 }
        /^Scaling:/              { sc = $2 }
        /^Origin:.*main display/ { main = 1 }
        /^Resolutions for/ && main { print id; print res; print hz; print cd; print sc; exit }')
    if test (count $cur) -ne 5
        echo "lowres: could not read the main display from displayplacer" >&2
        return 1
    end
    set -l id $cur[1]

    switch "$argv[1]"
        case status
            echo "main display: $cur[2] @ $cur[3]Hz, scaling $cur[5]"
            if test -f $saved
                echo "saved mode:   "(cat $saved)
            else
                echo "saved mode:   none"
            end

        case off restore
            if not test -f $saved
                echo "lowres: no saved mode; nothing to restore" >&2
                return 1
            end
            displayplacer (cat $saved); or return
            rm $saved
            echo "restored: "(displayplacer list | awk '/^Resolution:/ { print $2; exit }')

        case '' on '*x*'
            set -l res 1920x1080
            string match -qr '^\d+x\d+$' -- "$argv[1]"; and set res $argv[1]
            set -l scaling
            test "$cur[5]" = on; and set scaling scaling:on
            set -l original "id:$id res:$cur[2] hz:$cur[3] color_depth:$cur[4] $scaling origin:(0,0) degree:0"
            displayplacer "id:$id res:$res hz:$cur[3] color_depth:$cur[4] origin:(0,0) degree:0"; or return
            # Save only the first time, so a second `lowres` cannot overwrite
            # the real mode with the low one.
            if not test -f $saved
                mkdir -p $state_dir
                echo $original >$saved
            end
            echo "main display now $res (no Retina scaling); `lowres off` restores "(string match -r 'res:\S+' <$saved)

        case '*'
            echo "usage: lowres [WxH | off | status]" >&2
            return 1
    end
end
