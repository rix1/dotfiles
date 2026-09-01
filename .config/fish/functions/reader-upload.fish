function reader-upload --description "Upload a local Markdown/text file to Readwise Reader"
    set -l file $argv[1]

    if test -z "$file"; or test "$file" = "-h"; or test "$file" = "--help"
        echo "Usage: reader-upload FILE"
        echo
        echo "Interactive wizard for creating a Readwise Reader document from a local file."
        echo "Always adds the tag: fish-upload"
        return 2
    end

    if not test -f "$file"
        echo "reader-upload: file not found: $file" >&2
        return 1
    end

    if not type -q readwise
        echo "reader-upload: readwise CLI not found. Install/login with the Readwise CLI first." >&2
        return 1
    end

    set -l filename (basename -- "$file")
    set -l default_title (string replace -r '\.[^.]*$' '' -- "$filename")
    set default_title (string replace -a '_' ' ' -- "$default_title")
    set default_title (string replace -a '-' ' ' -- "$default_title")

    read -l -P "Title [$default_title]: " title
    if test -z "$title"
        set title "$default_title"
    end

    read -l -P "Author (optional): " author
    read -l -P "Summary (optional): " summary
    read -l -P "Notes (optional): " notes

    read -l -P "Category [article]: " category
    if test -z "$category"
        set category article
    end

    read -l -P "Published date ISO-8601 (optional): " published_date
    read -l -P "Image URL (optional): " image_url

    set -l slug (string lower -- "$title")
    set slug (string replace -ra '[^a-z0-9]+' '-' -- "$slug")
    set slug (string trim -c '-' -- "$slug")
    if test -z "$slug"
        set slug (string replace -ra '[^a-z0-9]+' '-' -- (string lower -- "$filename"))
        set slug (string trim -c '-' -- "$slug")
    end
    if test -z "$slug"
        set slug document
    end

    set -l timestamp (date -u "+%Y%m%dT%H%M%SZ")
    set -l default_url "https://rix1.local/readwise-upload/$slug-$timestamp"
    read -l -P "Source URL [$default_url]: " source_url
    if test -z "$source_url"
        set source_url "$default_url"
    end

    read -l -P "Extra tags, comma-separated (fish-upload added automatically): " raw_tags
    set -l tags fish-upload
    for tag in (string split ',' -- "$raw_tags")
        set tag (string trim -- "$tag")
        if test -n "$tag"; and not contains -- "$tag" $tags
            set -a tags "$tag"
        end
    end
    set -l tags_arg (string join ',' -- $tags)

    echo
    echo "Document:"
    echo "  File: $file"
    echo "  Title: $title"
    if test -n "$author"
        echo "  Author: $author"
    end
    echo "  Category: $category"
    echo "  Tags: $tags_arg"
    echo "  URL: $source_url"
    echo

    read -l -P "Upload to Readwise Reader? [Y/n]: " confirm
    switch (string lower -- "$confirm")
        case n no
            echo "Cancelled."
            return 0
    end

    set -l markdown (string collect < "$file")
    set -l args --json reader-create-document \
        --url "$source_url" \
        --markdown "$markdown" \
        --title "$title" \
        --category "$category" \
        --tags "$tags_arg"

    if test -n "$author"
        set -a args --author "$author"
    end
    if test -n "$summary"
        set -a args --summary "$summary"
    end
    if test -n "$notes"
        set -a args --notes "$notes"
    end
    if test -n "$published_date"
        set -a args --published-date "$published_date"
    end
    if test -n "$image_url"
        set -a args --image-url "$image_url"
    end

    echo "Uploading..."
    set -l output (readwise $args 2>&1)
    set -l exit_code $status

    if test $exit_code -ne 0
        echo "$output" >&2
        return $exit_code
    end

    set -l reader_url
    if type -q jq
        set reader_url (printf "%s\n" "$output" | jq -r '.url // empty' 2>/dev/null)
    end

    if test -n "$reader_url"
        echo "Created: $reader_url"
    else
        echo "$output"
    end
end
