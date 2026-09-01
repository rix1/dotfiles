function sigma --description "Sync new photo folders from Sigma camera to Dropbox"
    # Parse arguments
    set eject_after false
    for arg in $argv
        switch $arg
            case --eject -e
                set eject_after true
            case '*'
                echo "Unknown option: $arg"
                echo "Usage: sigma [--eject|-e]"
                return 1
        end
    end

    set CAMERA_PATH "/Volumes/Sigma BF/DCIM"
    set DESTINATION_PATH "$HOME/Dropbox/Photos/Sigma"
    set CAMERA_VOLUME "/Volumes/Sigma BF"
    
    # Get today's date in the camera's format (YYMMDD)
    set today_date (date "+%y%m%d")
    echo "🗓️  Today's date: $today_date"

    # Check if camera is connected
    if not test -d "$CAMERA_PATH"
        echo "❌ Camera not found at $CAMERA_PATH"
        echo "Please connect your Sigma camera and try again."
        return 1
    end

    echo "📷 Sigma camera detected"
    echo "🔍 Scanning for new folders..."

    # Create destination directory if it doesn't exist
    if not test -d "$DESTINATION_PATH"
        echo "📁 Creating destination directory: $DESTINATION_PATH"
        mkdir -p "$DESTINATION_PATH"
    end

    set new_folders_count 0
    set updated_folders_count 0
    set copied_folders ()
    set updated_folders ()
    set pending_source_files ()
    set pending_relative_files ()
    set pending_destination_folders ()
    set pending_folder_names ()

    function __sigma_render_progress --argument-names current total folder_name file_name
        if test "$total" -le 0
            return
        end

        set bar_width 24
        set filled (math "floor(($current * $bar_width) / $total)")
        set empty (math "$bar_width - $filled")
        set bar (string repeat -n $filled '#')(string repeat -n $empty '-')

        printf "\r[%s] %s/%s files | %s | %s" "$bar" "$current" "$total" "$folder_name" "$file_name"
    end

    # Loop through camera folders
    for folder in "$CAMERA_PATH"/*
        # Skip if not a directory or if it's a hidden folder
        if not test -d "$folder"
            continue
        end
        
        set folder_name (basename "$folder")
        
        # Skip hidden folders (starting with .)
        if string match -q ".*" "$folder_name"
            continue
        end
        
        set destination_folder "$DESTINATION_PATH/$folder_name"
        
        # Check if this is today's folder (starts with today's date)
        set is_today_folder false
        if string match -q "$today_date*" "$folder_name"
            set is_today_folder true
            echo "📅 Found today's folder: $folder_name"
        end
        
        # Check if folder already exists in destination
        if test -d "$destination_folder"
            if test "$is_today_folder" = true
                echo "📋 Checking today's folder for new files: $folder_name"

                set folder_has_new_files false
                for source_file in (find "$folder" -type f 2>/dev/null | sort)
                    set prefix "$folder/"
                    set prefix_len (string length -- "$prefix")
                    set relative_path (string sub -s (math "$prefix_len + 1") -- "$source_file")
                    set target_file "$destination_folder/$relative_path"

                    if test -e "$target_file"
                        continue
                    end

                    set folder_has_new_files true
                    set pending_source_files $pending_source_files "$source_file"
                    set pending_relative_files $pending_relative_files "$relative_path"
                    set pending_destination_folders $pending_destination_folders "$destination_folder"
                    set pending_folder_names $pending_folder_names "$folder_name"
                end

                if test "$folder_has_new_files" = true
                    set updated_folders_count (math $updated_folders_count + 1)
                    set updated_folders $updated_folders "$folder_name"
                else
                    echo "⏭️  No new files in today's folder: $folder_name"
                end
            else
                echo "⏭️  Skipping $folder_name (already exists)"
            end
            continue
        end

        echo "📋 Queuing new folder: $folder_name"
        mkdir -p "$destination_folder"

        set folder_file_count 0
        for source_file in (find "$folder" -type f 2>/dev/null | sort)
            set prefix "$folder/"
            set prefix_len (string length -- "$prefix")
            set relative_path (string sub -s (math "$prefix_len + 1") -- "$source_file")

            set folder_file_count (math $folder_file_count + 1)
            set pending_source_files $pending_source_files "$source_file"
            set pending_relative_files $pending_relative_files "$relative_path"
            set pending_destination_folders $pending_destination_folders "$destination_folder"
            set pending_folder_names $pending_folder_names "$folder_name"
        end

        if test $folder_file_count -gt 0
            set new_folders_count (math $new_folders_count + 1)
            set copied_folders $copied_folders "$folder_name"
        else
            echo "⏭️  No files found in $folder_name"
        end
    end

    set total_files_to_copy (count $pending_source_files)

    echo ""
    echo "📦 Files queued for copy: $total_files_to_copy"

    if test $total_files_to_copy -gt 0
        set copied_file_count 0
        set copy_failed false

        for idx in (seq $total_files_to_copy)
            set source_file $pending_source_files[$idx]
            set relative_path $pending_relative_files[$idx]
            set destination_folder $pending_destination_folders[$idx]
            set folder_name $pending_folder_names[$idx]
            set destination_file "$destination_folder/$relative_path"
            set destination_parent (dirname "$destination_file")

            mkdir -p "$destination_parent"
            __sigma_render_progress $idx $total_files_to_copy "$folder_name" (basename "$source_file")

            if cp -p "$source_file" "$destination_file"
                set copied_file_count $idx
            else
                set copy_failed true
                printf "\n❌ Failed to copy %s\n" "$source_file"
            end
        end

        printf "\n"

        if test "$copy_failed" = false
            echo "✅ Finished copying $copied_file_count file(s)"
        else
            echo "⚠️  Finished with copy errors"
        end
    end

    functions -e __sigma_render_progress

    # Summary
    echo ""
    echo "📊 Summary:"
    echo "   • Copied $new_folders_count new folder(s)"
    echo "   • Updated $updated_folders_count today's folder(s)"
    echo "   • Queued $total_files_to_copy new file(s)"
    
    if test $new_folders_count -gt 0
        echo "   • New folders:"
        for folder in $copied_folders
            echo "     - $folder"
        end
    end
    
    if test $updated_folders_count -gt 0
        echo "   • Updated folders:"
        for folder in $updated_folders
            echo "     - $folder"
        end
    end
    
    if test $total_files_to_copy -gt 0
        echo ""
        echo "🎉 Ready for Lightroom! Open: $DESTINATION_PATH"
    else
        echo "   • No new files to copy"
    end

    # Eject camera if requested
    if test "$eject_after" = true
        echo ""
        echo "⏏️  Ejecting camera..."
        if diskutil eject "$CAMERA_VOLUME"
            echo "✅ Camera ejected successfully"
        else
            echo "❌ Failed to eject camera"
            return 1
        end
    end
end
