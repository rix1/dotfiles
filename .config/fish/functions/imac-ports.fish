function imac-ports --description 'Forward the dev servers in the iMac'"'"'s Rex terminals to imac.localhost here'
    set -l rex rex -S imac
    set -l me (hostname -s)

    if contains -- "$argv[1]" -h --help
        echo "imac-ports        forward every port a terminal on the iMac listens on"
        echo "imac-ports stop   close the forwards"
        return
    end

    # Close the forwards this machine made; their `rex forward new` pane exits with them.
    set -l mine ($rex forward ls -A --json | jq -r --arg me $me '.forwards[] | select(.client_label == $me) | .block_id')
    test (count $mine) -gt 0; and $rex forward close $mine >/dev/null

    if test "$argv[1]" = stop
        echo "Closed all forwards to the iMac."
        return
    end

    # One "port<TAB>command<TAB>cwd" row per port a Rex terminal on the iMac listens on.
    set -l rows
    for b in ($rex block ls -A -q --short=false)
        set -a rows ($rex block call -b $b ports 2>/dev/null | jq -r '
            (.processes | map({(.pid | tostring): .}) | add // {}) as $p
            | .ports[]? | $p[.pid | tostring] as $proc
            | [.port, ($proc.script // $proc.path // "" | split("/") | last), ($proc.cwd // "" | sub("^" + env.HOME; "~"))]
            | @tsv')
    end
    set rows (printf '%s\n' $rows | sort -un)

    if test (count $rows) -eq 0
        echo "No dev servers listening in the iMac's terminals."
        return
    end

    # Same port here as on the iMac, or 1<port> when something local already has it.
    set -l flags
    for row in $rows
        set -l cols (string split \t -- $row)
        set -l l $cols[1]
        lsof -nP -iTCP:$l -sTCP:LISTEN >/dev/null 2>&1; and set l 1$cols[1]
        set -a flags -L $l:localhost:$cols[1]
        echo "http://imac.localhost:$l  $cols[2]  $cols[3]"
    end

    # The forwards live in a small pane below this one, so they stay visible.
    rex split --split=below --ratio 15 --focus=false -- $rex forward new -v $flags >/dev/null
end
