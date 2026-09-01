complete -c reader-upload -s h -l help -d "Show help"
complete -c reader-upload -f -n "__fish_is_first_token" -a "(__fish_complete_path (commandline -ct) 'File to upload')"
