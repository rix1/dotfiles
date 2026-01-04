function compress_video
    if test (count $argv) -lt 1
        echo "Usage: compress_video <input_file> [output_file]"
        return 1
    end

    set input_file $argv[1]
    
    # If no output file is specified, create one with '_compressed' suffix
    if test (count $argv) -lt 2
        set output_file (string replace -r '\.([^\.]+)$' '_compressed.$1' $input_file)
    else
        set output_file $argv[2]
    end

    ffmpeg -i $input_file \
        -c:v libx265 \
        -c:a aac \
        -crf 25 \
        -tag:v hvc1 \
        $output_file
end
