#!/bin/bash

# Create necessary directories if they don't exist
mkdir -p content/Blog-Attachments

# Function to convert a path to a relative path from the blog post
make_relative_path() {
    local post_dir=$(dirname "$1")
    local image_path="$2"
    realpath --relative-to="$post_dir" "content/Blog-Attachments/$(basename "$image_path")"
}

# Find all markdown files in Blog-Posts
find content/Blog-Posts -name "*.md" | while read -r post; do
    echo "Processing $post..."

    # Find all image references in the markdown file
    # This looks for standard markdown image syntax ![alt](path) and Hugo shortcode {{< figure src="path" >}}
    grep -Eo '\!\[.*\]\(.*\)|\{\{<\s*figure\s*src="[^"]*"' "$post" | while read -r image_ref; do
        # Extract the image path
        if [[ $image_ref == "!["* ]]; then
            image_path=$(echo "$image_ref" | sed -E 's/!\[.*\]\((.*)\)/\1/')
        else
            image_path=$(echo "$image_ref" | sed -E 's/.*src="([^"]*)".*/\1/')
        fi

        # Skip if it's already in Blog-Attachments or is a web URL
        if [[ $image_path == *"Blog-Attachments"* ]] || [[ $image_path == http* ]]; then
            continue
        fi

        # If it's a relative path, resolve it relative to the post location
        if [[ $image_path != /* ]]; then
            image_path="$(dirname "$post")/$image_path"
        fi

        # Check if the source image exists
        if [[ -f "$image_path" ]]; then
            # Create a new path in Blog-Attachments
            new_path="content/Blog-Attachments/$(basename "$image_path")"

            # Copy the file
            cp "$image_path" "$new_path"
            echo "Moved $image_path to $new_path"

            # Get the relative path from the post to the new location
            relative_path=$(make_relative_path "$post" "$image_path")

            # Update the reference in the post
            if [[ $image_ref == "!["* ]]; then
                sed -i.bak "s|$image_path|$relative_path|g" "$post"
            else
                sed -i.bak "s|src=\"$image_path\"|src=\"$relative_path\"|g" "$post"
            fi

            echo "Updated reference in $post"
        else
            echo "Warning: Image $image_path not found"
        fi
    done
done

# Remove backup files
find content/Blog-Posts -name "*.bak" -delete

# Verify images are servable by Hugo
echo "Verifying images are servable by Hugo..."
hugo server -D --cleanDestinationDir --watch=content,static,themes &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Check each image in Blog-Attachments
find content/Blog-Attachments -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | while read -r image; do
    relative_path=${image#content/}
    url="http://localhost:1313/$relative_path"

    if curl -s -f -I "$url" > /dev/null; then
        echo "✓ $relative_path is servable"
    else
        echo "✗ $relative_path is not servable"
    fi
done

# Stop Hugo server
kill $SERVER_PID

echo "Migration complete!"
