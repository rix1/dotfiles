function csv2sqlite
    argparse 'local' -- $argv
    or return

    set csv_file $argv[1]
    set table_name (basename $csv_file .csv)

    if set -q _flag_local
        set db_file "$table_name.db"
    else
        set db_file (mktemp -t import.XXXXXX.db)
    end

    sqlite3 $db_file ".import --csv $csv_file $table_name"
    and litecli $db_file

    # Only remove if it's a temp file
    if not set -q _flag_local
        rm $db_file
    end
end
