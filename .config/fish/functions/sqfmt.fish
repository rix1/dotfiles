function sqfmt --description 'Format SQL with sqruff and optionally copy to clipboard'
    # Define option for clipboard copying
    argparse 'c/copy' -- $argv

    # If arguments are provided, use them as input
    if test (count $argv) -gt 0
        # Join all arguments with spaces in case input was quoted
        set input (string join ' ' $argv)
    else
        # If no arguments, try to read from clipboard
        set input (pbpaste)
    end

    # Format the SQL using sqruff and preserve newlines
    set formatted (echo $input | sqruff fix - | string collect)

    # Always print the formatted result
    echo (set_color green)"✅ Formatted SQL with sqruff:"(set_color normal)
    printf '%s\n' $formatted

    # If -c flag is present, copy to clipboard
    if set -q _flag_copy
        printf '%s\n' $formatted | pbcopy
        echo (set_color cyan)"📋 Formatted SQL copied to clipboard!"(set_color normal)
    end
end
