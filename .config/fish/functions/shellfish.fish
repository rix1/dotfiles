# ShellFish integration for Fish shell
#
# This file should be placed in ~/.config/fish/conf.d/
# It provides environment configuration and ShellFish-specific functions
# that only work when LC_TERMINAL=ShellFish.
#
# Universal functions (widget, notify, thumbnail) that work from any terminal
# are installed separately in ~/.config/fish/functions/

# Helper function for URI encoding (available in all contexts)
function ios_printURIComponent
  awk 'BEGIN {while (y++ < 125) z[sprintf("%c", y)] = y
  while (y = substr(ARGV[1], ++j, 1))
  q = y ~ /[a-zA-Z0-9]/ ? q y : q sprintf("%%%02X", z[y])
  printf("%s", q)}' "$argv[1]"
end

# Only configure when running in ShellFish
if test "$LC_TERMINAL" = "ShellFish"

  # Secure ShellFish supports 24-bit colors
  set -gx COLORTERM truecolor

  # Enable tmux passthrough if we're in a tmux session
  if set -q TMUX
    # Ignore error from old versions of tmux without this command
    tmux set -g allow-passthrough on 2>/dev/null || true
    # Enable tmux mouse mode for scrolling with swipe and mouse wheel
    tmux set -g mouse on 2>/dev/null || true
  end

  # Update terminal current working directory for better filename detection
  # This sends OSC 7 escape sequence when the directory changes
  function update_terminal_cwd --on-variable PWD
    if status is-interactive
      # Prepare the escape sequence
      if set -q TMUX
        printf "\033Ptmux;\033\033]"
      else
        printf "\033]"
      end

      # Send OSC 7 with file URL
      printf "7;file://%s" (hostname)
      # URL encode the PWD
      echo -n "$PWD" | sed 's/ /%20/g' | sed 's/#/%23/g'

      # Close the escape sequence
      if set -q TMUX
        printf "\a\033\\"
      else
        printf "\a"
      end
    end
  end

  # Trigger the function once to set initial directory
  if status is-interactive
    update_terminal_cwd
  end

  # Define ShellFish-specific functions

  function sharesheet
    if not set -q argv[1]
      if isatty
        echo Usage: sharesheet [FILE]...
        echo
        echo Present share sheet for files and directories.
        echo Alternatively you can pipe in text and call it without arguments.
        echo
        echo If arguments exist inside the Finder or Files app changes made are written back to the server.
        return 0
      end
    end

    set FIFO $(mktemp)
    rm -f $FIFO
    mkfifo $FIFO

    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "6;sharesheet://?ver=2&respond="
    echo -n "$FIFO" | base64
    printf "&pwd="
    echo -n "$PWD" | base64
    printf "&home="
    echo -n "$HOME" | base64
    if count $argv > /dev/null
      for var in $argv
        printf "&path="
        echo -n "$var" | base64
      end
    else
      printf "&text="
      cat - | base64
    end

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end

    read <$FIFO -s REPLY
    rm -f $FIFO

    if test -z "$REPLY"
      return 0
    end

    if string match -q "error=*" "$REPLY"
      echo (string replace -r "^error=" "" "$REPLY") | base64 -d
      return 1
    end

    if string match -q "result=*" "$REPLY"
      echo (string replace -r "^result=" "" "$REPLY") | base64 -d
    end
  end

  function quicklook
    if not set -q argv[1]
      if isatty
        echo Usage: quicklook [FILE]...
        echo
        echo Show QuickLook preview for files and directories.
        echo Alternatively you can pipe in text and call it without arguments.
        return 0
      end
    end

    set FIFO $(mktemp)
    rm -f $FIFO
    mkfifo $FIFO

    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "6;quicklook://?ver=2&respond="
    echo -n "$FIFO" | base64
    printf "&pwd="
    echo -n "$PWD" | base64
    printf "&home="
    echo -n "$HOME" | base64
    if count $argv > /dev/null
      for var in $argv
        printf "&path="
        echo -n "$var" | base64
      end
    else
      printf "&text="
      cat - | base64
    end

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end

    read <$FIFO -s REPLY
    rm -f $FIFO

    if test -z "$REPLY"
      return 0
    end

    if string match -q "error=*" "$REPLY"
      echo (string replace -r "^error=" "" "$REPLY") | base64 -d
      return 1
    end

    if string match -q "result=*" "$REPLY"
      echo (string replace -r "^result=" "" "$REPLY") | base64 -d
    end
  end

  function textastic
    if not set -q argv[1]
      echo 'Usage: textastic <text-file>'
      echo
      echo Open in Textastic 9.5 or later.
      echo File must be in directory represented in the Files app to allow writing back edits.
      return 0
    end

    # make sure file exists
    if not test -e "$argv[1]"
      touch "$argv[1]"
    end

    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "6;textastic://?ver=2&pwd="
    echo -n "$PWD" | base64
    printf "&home="
    echo -n "$HOME" | base64
    printf "&path="
    echo -n "$argv" | base64

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end
  end

  function setbarcolor
    if not set -q argv[1]
      echo 'Usage: setbarcolor <css-style color>'
      echo
      echo 'Set color of terminal toolbar color with values such as'
      echo '  red, #f00, #ff0000, rgb(255,0,0), color(p3 1.0 0.0 0.0)'
      return 0
    end

    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "6;settoolbar://?ver=2&color="
    echo -n "$argv[1]" | base64

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end
  end

  function openUrl
    if not set -q argv[1]
      echo 'Usage: openUrl <url>'
      echo
      echo Open URL on iOS.
      return 0
    end

    set FIFO $(mktemp)
    rm -f $FIFO
    mkfifo $FIFO

    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "6;open://?ver=2&respond="
    echo -n "$FIFO" | base64
    printf "&url="
    echo -n "$argv[1]" | base64

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end

    read <$FIFO -s REPLY
    rm -f $FIFO

    if test -z "$REPLY"
      return 0
    end

    if string match -q "error=*" "$REPLY"
      echo (string replace -r "^error=" "" "$REPLY") | base64 -d
      return 1
    end

    if string match -q "result=*" "$REPLY"
      echo (string replace -r "^result=" "" "$REPLY") | base64 -d
    end
  end

  function runShortcut
    set --local baseUrl "shortcuts://run-shortcut"

    # Check for --x-callback option
    if test "$argv[1]" = "--x-callback"
      set baseUrl "shortcuts://x-callback-url/run-shortcut"
      set argv $argv[2..-1]  # Remove first argument
    end

    if not set -q argv[1]
      echo 'Usage: runShortcut [--x-callback] <shortcut-name> [input-for-shortcut]'
      echo
      echo 'Run in Shortcuts app bringing back results if --x-callback is included.'
      return 0
    end

    # Encode shortcut name
    set --local name (ios_printURIComponent "$argv[1]")
    set argv $argv[2..-1]  # Remove shortcut name from arguments

    # Handle input
    set --local input
    if test "$argv" = "-"
      # Read from stdin
      set --local text (cat -)
      set input (ios_printURIComponent "$text")
    else if set -q argv[1]
      # Use remaining arguments
      set --local args (string join " " $argv)
      set input (ios_printURIComponent "$args")
    else
      set input ""
    end

    # Call openUrl with the constructed URL
    openUrl "$baseUrl?name=$name&input=$input"
  end

  function pbcopy
    # copy standard input or arguments to iOS clipboard
    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "52;c;"
    if test (count $argv) -eq 0
      base64 | tr -d '\n'
    else
      echo -n "$argv" | base64 | tr -d '\n'
    end

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end
  end

  function pbpaste
    # paste from iOS device clipboard to standard output
    set FIFO $(mktemp)
    rm -f $FIFO
    mkfifo $FIFO

    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "6;pbpaste://?ver=2&respond="
    echo -n "$FIFO" | base64

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end

    read <$FIFO -s REPLY
    rm -f $FIFO

    if test -z "$REPLY"
      return 0
    end

    if string match -q "error=*" "$REPLY"
      echo (string replace -r "^error=" "" "$REPLY") | base64 -d
      return 1
    end

    if string match -q "result=*" "$REPLY"
      echo (string replace -r "^result=" "" "$REPLY") | base64 -d
    end
  end

  function snip
    if not set -q argv[1]
      echo 'Usage: snip <text for snippet>'
      return 0
    end

    # Combine all arguments into text
    set --local text (string join " " $argv)

    if test "$TMUX" = ""
      printf "\033]"
    else
      printf "\033Ptmux;\033\033]"
    end

    printf "6;addsnippet://?ver=2&text="
    echo -n "$text" | base64

    if test "$TMUX" = ""
      printf "\a"
    else
      printf "\a\033\\"
    end
  end

end # end of LC_TERMINAL=ShellFish check