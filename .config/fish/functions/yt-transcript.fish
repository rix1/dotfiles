function yt-transcript --description "Download a YouTube video's captions as plain text (for LLM context etc.)"
    set -l converter $HOME/.config/bin/vtt2text.py

    argparse --name=yt-transcript h/help 'l/lang=' 'o/output=' llm no-timestamps list -- $argv
    or return 2

    if set -q _flag_help; or test (count $argv) -ne 1
        echo "Usage: yt-transcript [options] 'URL'"
        echo
        echo "Download the captions of a YouTube video with yt-dlp and print them as plain text."
        echo "Subtitles uploaded by the channel are preferred; otherwise YouTube's auto-generated"
        echo "captions are used. Output goes to stdout, so pipe it to pbcopy or redirect to a file."
        echo "Quote the URL: fish treats '?' in watch?v=... as a wildcard."
        echo
        echo "Options:"
        echo "  -l, --lang LANG     Caption language code (default: en). Matches LANG, LANG-orig and"
        echo "                      LANG-<source> tracks, preferring the original. yt-dlp regex is allowed."
        echo "  -o, --output FILE   Write to FILE instead of stdout"
        echo "      --llm           Prepend a preamble (title, channel, date, caveats) for use as LLM context"
        echo "      --no-timestamps Omit the per-minute [m:ss] markers"
        echo "      --list          List the caption languages available for URL and exit"
        echo "  -h, --help          Show this help"
        echo
        echo "Examples:"
        echo "  yt-transcript --llm 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' | pbcopy"
        echo "  yt-transcript -l nb -o talk.txt https://youtu.be/dQw4w9WgXcQ"
        echo
        echo "The VTT to text conversion lives in $converter and can be used on its own."
        if set -q _flag_help
            return 0
        end
        return 2
    end

    set -l url $argv[1]

    for tool in yt-dlp python3
        if not type -q $tool
            echo "yt-transcript: $tool not found (brew install $tool)" >&2
            return 1
        end
    end
    if not test -f $converter
        echo "yt-transcript: converter script missing: $converter" >&2
        return 1
    end

    if set -q _flag_list
        yt-dlp --quiet --no-warnings --no-playlist --list-subs -- $url
        return
    end

    set -l lang en
    if set -q _flag_lang
        set lang $_flag_lang
    end
    # yt-dlp anchors the pattern, so this matches LANG itself or LANG-<source>
    # (translated auto captions are named e.g. en-no: English from Norwegian).
    set -l sub_langs "(?:$lang)(-.*)?"

    set -l tmp (mktemp -d -t yt-transcript.XXXXXX)
    or return 1

    echo "yt-transcript: fetching '$lang' captions…" >&2
    yt-dlp --quiet --no-warnings --no-progress --no-playlist --skip-download \
        --write-subs --write-auto-subs --sub-langs $sub_langs --sub-format vtt \
        --write-info-json \
        --output "$tmp/%(id)s.%(ext)s" -- $url
    if test $status -ne 0
        rm -rf $tmp
        return 1
    end

    set -l vtts $tmp/*.vtt
    if test (count $vtts) -eq 0
        echo "yt-transcript: no '$lang' captions found. Try 'yt-transcript --list URL' to see what is available." >&2
        rm -rf $tmp
        return 1
    end

    # yt-dlp names the spoken-language auto track LANG-orig on some videos, and
    # translations either LANG or LANG-<source>. Prefer the original, then the
    # exact code, then whatever else matched.
    set -l vtt $vtts[1]
    for pattern in "*.$lang-orig.vtt" "*.$lang.vtt"
        set -l matched (string match -- $pattern $vtts)
        if test (count $matched) -gt 0
            set vtt $matched[1]
            break
        end
    end
    set -l track (string replace -r '^.*\.([^.]+)\.vtt$' '$1' -- (basename $vtt))
    if test "$track" != "$lang"
        echo "yt-transcript: using caption track '$track'" >&2
    end

    set -l converter_args
    set -q _flag_llm; and set -a converter_args --llm
    set -q _flag_no_timestamps; and set -a converter_args --no-timestamps
    set -l infos $tmp/*.info.json
    test (count $infos) -gt 0; and set -a converter_args --info $infos[1]

    if set -q _flag_output
        python3 $converter $converter_args -- $vtt >$_flag_output
        set -l exit_code $status
        test $exit_code -eq 0; and echo "yt-transcript: wrote $_flag_output" >&2
        rm -rf $tmp
        return $exit_code
    end

    python3 $converter $converter_args -- $vtt
    set -l exit_code $status
    rm -rf $tmp
    return $exit_code
end
