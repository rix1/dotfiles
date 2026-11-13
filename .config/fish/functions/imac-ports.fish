function imac-ports --description 'Forward the dev servers listening on the iMac to localhost here'
    set -l host rikards-imac
    set -q IMAC_HOST; and set host $IMAC_HOST
    set -l sock ~/.ssh/imac-ports.sock
    set -l state ~/.local/state/imac-ports
    set -l ctl ssh -S $sock

    if contains -- "$argv[1]" -h --help
        echo "imac-ports              forward every dev server on $host, drop the ones that are gone"
        echo "imac-ports 4200         forward one port"
        echo "imac-ports 14200:4200   forward remote 4200 to local 14200"
        echo "imac-ports stop         close all forwards"
        return
    end

    set -l alive 0
    $ctl -O check $host 2>/dev/null; and set alive 1
    test $alive = 1; or rm -f $state

    if test "$argv[1]" = stop
        test $alive = 1; and $ctl -O exit $host 2>/dev/null
        rm -f $state
        echo "Closed all forwards to $host."
        return
    end

    if test $alive = 0
        mkdir -p (path dirname $state)
        ssh -M -S $sock -fN -o ServerAliveInterval=30 -o ServerAliveCountMax=3 $host; or return 1
    end

    # state: one "local remote kind" line per forward the master holds
    set -l have_l
    set -l have_r
    set -l have_k
    if test -f $state
        while read -l l r k
            set -a have_l $l
            set -a have_r $r
            set -a have_k $k
        end <$state
    end

    # port, command and cwd of every dev-ish listener started under $HOME, below the ephemeral range
    set -l discover '
lsof -nP -iTCP -sTCP:LISTEN -Fpcn 2>/dev/null | awk \'
/^p/ { pid = substr($0, 2) }
/^c/ { cmd = substr($0, 2) }
/^n/ { n = $0; sub(/.*:/, "", n)
       if (cmd ~ /^(node|workerd|deno|bun)/ && n + 0 < 49152) print n, pid, cmd }\' |
sort -un | while read -r port pid cmd; do
  cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n \'s/^n//p\')
  case "$cwd" in "$HOME"/*) printf "%s\t%s\t%s\n" "$port" "$cmd" "${cwd/#$HOME/\~}" ;; esac
done'
    set -l rows (echo $discover | $ctl $host bash -s)
    set -l found
    for row in $rows
        set -a found (string split \t -- $row)[1]
    end

    set -l want_l
    set -l want_r
    set -l kind auto
    if test (count $argv) -gt 0
        set kind manual
        for arg in $argv
            set -l parts (string split : -- $arg)
            set -a want_l $parts[1]
            set -a want_r $parts[-1]
        end
    else
        set want_l $found
        set want_r $found

        # drop the forwards whose server is gone
        set -l keep_l
        set -l keep_r
        set -l keep_k
        for i in (test (count $have_l) -gt 0; and seq (count $have_l))
            if test $have_k[$i] = auto; and not contains -- $have_r[$i] $found
                $ctl -O cancel -L $have_l[$i]:localhost:$have_r[$i] $host 2>/dev/null
                echo "closed   localhost:$have_l[$i]"
            else
                set -a keep_l $have_l[$i]
                set -a keep_r $have_r[$i]
                set -a keep_k $have_k[$i]
            end
        end
        set have_l $keep_l
        set have_r $keep_r
        set have_k $keep_k
    end

    for i in (test (count $want_l) -gt 0; and seq (count $want_l))
        set -l l $want_l[$i]
        set -l r $want_r[$i]
        contains -- $l $have_l; and continue
        if lsof -nP -iTCP:$l -sTCP:LISTEN >/dev/null 2>&1
            echo "skipped  $r: local port $l is taken, try `imac-ports 1$r:$r`"
            continue
        end
        if $ctl -O forward -L $l:localhost:$r $host
            set -a have_l $l
            set -a have_r $r
            set -a have_k $kind
        end
    end

    rm -f $state
    for i in (test (count $have_l) -gt 0; and seq (count $have_l))
        echo $have_l[$i] $have_r[$i] $have_k[$i] >>$state
        set -l info
        for row in $rows
            set -l cols (string split \t -- $row)
            test $cols[1] = $have_r[$i]; and set info $cols[2..3]
        end
        set -l via
        test $have_l[$i] = $have_r[$i]; or set via "(remote $have_r[$i])"
        echo "http://localhost:$have_l[$i]  $info $via"
    end
    test (count $have_l) -gt 0; or echo "No dev servers listening on $host."
end
