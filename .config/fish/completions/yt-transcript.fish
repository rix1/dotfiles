complete -c yt-transcript -f
complete -c yt-transcript -s h -l help -d "Show help"
complete -c yt-transcript -s l -l lang -x -a "en nb no sv da de fr es" -d "Caption language code (regex allowed)"
complete -c yt-transcript -s o -l output -r -F -d "Write transcript to file"
complete -c yt-transcript -l llm -d "Prepend an LLM context preamble"
complete -c yt-transcript -l no-timestamps -d "Omit the per-minute [m:ss] markers"
complete -c yt-transcript -l list -d "List available caption languages"
