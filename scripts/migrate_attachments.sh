#!/bin/bash

# Enable debug mode to see what's happening
set -x

# Create necessary directories if they don't exist
mkdir -p "content/Blog-Attachments"
mkdir -p "public/blog-posts/Blog-Attachments"

# Remove any incorrect directory if it exists
rm -rf "public/Blog-Attachments"

# Define source directories with absolute paths to avoid any confusion
ATTACHMENTS_DIR="/Users/tucker/Documents/00-Vault/03 - Resources/Attachments"
BLOG_ATTACHMENTS="$(pwd)/content/Blog-Attachments"
PUBLIC_ATTACHMENTS="$(pwd)/public/blog-posts/Blog-Attachments"

echo "Content directory: $BLOG_ATTACHMENTS"
echo "Public directory: $PUBLIC_ATTACHMENTS"

# Process each markdown file
find "content/Blog-Posts" -name "*.md" | while read -r post; do
    echo "Processing $post..."

    # Find both wiki-style and standard markdown image references
    # First, find wiki-style references
    grep -o '!\[\[[^]]*\]\]' "$post" 2>/dev/null | while read -r image_ref; do
        image_path=$(echo "$image_ref" | sed -E 's/!\[\[(.*)\]\]/\1/')
        image_name=$(basename "$image_path")

        echo "Processing wiki-style image: $image_name"

        # Handle the image
        if [[ -f "$ATTACHMENTS_DIR/$image_name" ]]; then
            cp "$ATTACHMENTS_DIR/$image_name" "$BLOG_ATTACHMENTS/$image_name"
            cp "$ATTACHMENTS_DIR/$image_name" "$PUBLIC_ATTACHMENTS/$image_name"
            echo "Copied $image_name to both directories"

            # Convert to standard markdown format
            escaped_image_ref=$(echo "$image_ref" | sed 's/[[\/*]/\\&/g')
            new_ref="![](../Blog-Attachments/$image_name)"
            sed -i.bak "s|$escaped_image_ref|$new_ref|g" "$post"
        fi
    done

    # Then, find standard markdown references
    grep -o '!\[.*\]([^)]*Blog-Attachments[^)]*\.png)' "$post" 2>/dev/null | while read -r image_ref; do
        # Extract image path from standard markdown ![alt](path)
        image_path=$(echo "$image_ref" | sed -E 's/!\[.*\]\((.*)\)/\1/')
        image_name=$(basename "$image_path")

        echo "Processing standard markdown image: $image_name"

        # If the file exists in content/Blog-Attachments, ensure it's in public too
        if [[ -f "$BLOG_ATTACHMENTS/$image_name" ]]; then
            echo "Copying $image_name to public directory"
            cp "$BLOG_ATTACHMENTS/$image_name" "$PUBLIC_ATTACHMENTS/$image_name"
        elif [[ -f "$ATTACHMENTS_DIR/$image_name" ]]; then
            echo "Copying new image from attachments"
            cp "$ATTACHMENTS_DIR/$image_name" "$BLOG_ATTACHMENTS/$image_name"
            cp "$ATTACHMENTS_DIR/$image_name" "$PUBLIC_ATTACHMENTS/$image_name"
        fi
    done
done

# Clean up backup files
find "content/Blog-Posts" -name "*.bak" -delete

# Verify the correct directory structure
echo "Final directory check:"
echo "Content attachments:"
ls -la "content/Blog-Attachments"
echo "Public attachments:"
ls -la "public/blog-posts/Blog-Attachments"

# Ensure no wrong directory exists
if [ -d "public/Blog-Attachments" ]; then
    echo "ERROR: Incorrect directory public/Blog-Attachments exists!"
    rm -rf "public/Blog-Attachments"
fi

echo "Migration complete!"

# Disable debug mode
set +x
