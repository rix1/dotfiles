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
    set DESTINATION_PATH "/Users/rix1/Dropbox/Photos/Sigma"
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
                echo "📋 Updating today's folder: $folder_name..."
                # Copy contents, not the folder itself (since it exists)
                if cp -R "$folder"/* "$destination_folder"/
                    echo "🔄 Successfully updated $folder_name"
                    set updated_folders_count (math $updated_folders_count + 1)
                    set updated_folders $updated_folders "$folder_name"
                else
                    echo "❌ Failed to update $folder_name"
                end
            else
                echo "⏭️  Skipping $folder_name (already exists)"
            end
            continue
        end
        
        # Copy the folder (new folder)
        echo "📋 Copying $folder_name..."
        if cp -R "$folder" "$destination_folder"
            echo "✅ Successfully copied $folder_name"
            set new_folders_count (math $new_folders_count + 1)
            set copied_folders $copied_folders "$folder_name"
        else
            echo "❌ Failed to copy $folder_name"
        end
    end

    # Summary
    echo ""
    echo "📊 Summary:"
    echo "   • Copied $new_folders_count new folder(s)"
    echo "   • Updated $updated_folders_count today's folder(s)"
    
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
    
    if test (math $new_folders_count + $updated_folders_count) -gt 0
        echo ""
        echo "🎉 Ready for Lightroom! Open: $DESTINATION_PATH"
    else
        echo "   • No new folders to copy or update"
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

