function csv2query
    set -l csv_file ""
    set -l query ""

    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -q --query
                set i (math $i + 1)
                set query $argv[$i]
            case '*'
                set csv_file $argv[$i]
        end
        set i (math $i + 1)
    end

    # Validate inputs
    if test -z "$csv_file"
        echo "Error: No CSV file specified" >&2
        return 1
    end

    if test -z "$query"
        echo "Error: No query specified with -q" >&2
        return 1
    end

    if not test -f "$csv_file"
        echo "Error: File '$csv_file' not found" >&2
        return 1
    end

    # Create temporary database
    set -l table_name 'data'
    set -l tmpdb (mktemp -t query.XXXXXX.db)

    # Import CSV
    sqlite3 $tmpdb ".mode csv" ".import $csv_file $table_name"

    # Run query
    sqlite3 -header -csv $tmpdb "$query"

    # Clean up
    rm -f $tmpdb
end
