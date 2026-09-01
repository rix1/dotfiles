# Add EXIF thumbnails to image files
#
# This command works in any terminal, not just Secure ShellFish
#
# put this file inside $HOME/.config/fish/functions

function thumbnail
  if not set -q argv[1]
    echo 'Usage: thumbnail <image-file> [image-file-2] ...'
    echo
    echo 'Add Exif thumbnails to image files using ImageMagick convert and exiftool.'
    return 0
  else
    # make sure ImageMagick and exiftool are available
    if not command -v convert >/dev/null 2>&1
      echo "ImageMagick convert needs to be installed"
      return 1
    end

    if not command -v exiftool >/dev/null 2>&1
      echo "exiftool needs to be installed"
      return 1
    end

    set --local THUMBNAIL /tmp/thumbnail.jpg
    for arg in $argv
      echo "$arg"
      convert "$arg" -thumbnail 160x120^ "$THUMBNAIL"
      exiftool -q -overwrite_original "-thumbnailimage<=$THUMBNAIL" "$arg"
      rm -f "$THUMBNAIL"
    end
  end
end