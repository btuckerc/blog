#!/bin/bash

# Create necessary directories if they don't exist
mkdir -p content/Blog-Attachments
mkdir -p public/blog-posts/Blog-Attachments

# Define source directories
ATTACHMENTS_DIR="/Users/tucker/Documents/00-Vault/03 - Resources/Attachments"
BLOG_ATTACHMENTS="content/Blog-Attachments"
PUBLIC_ATTACHMENTS="public/blog-posts/Blog-Attachments"

# Process each markdown file
find "content/Blog-Posts" -name "*.md" | while read -r post; do
    echo "Processing $post..."

    # Find all wiki-style image references in the file
    grep -o '!\[\[[^]]*\]\]' "$post" | while read -r image_ref; do
        # Extract image name from wiki-style link ![[../Blog-Attachments/image.png]]
        image_path=$(echo "$image_ref" | sed -E 's/!\[\[(.*)\]\]/\1/')
        image_name=$(basename "$image_path")

        # If it's already in Blog-Attachments, convert the format but keep the path
        if [[ "$image_path" == *"Blog-Attachments"* ]]; then
            echo "Converting format for $image_name"
            escaped_image_ref=$(echo "$image_ref" | sed 's/[[\/*]/\\&/g')
            new_ref="![](../Blog-Attachments/$image_name)"
            sed -i.bak "s|$escaped_image_ref|$new_ref|g" "$post"
            echo "Updated reference format in $post"
            continue
        fi

        # Source and destination paths
        source_path="$ATTACHMENTS_DIR/$image_name"

        # Copy the file if it exists
        if [[ -f "$source_path" ]]; then
            # Copy to both content and public directories
            cp "$source_path" "$BLOG_ATTACHMENTS/$image_name"
            cp "$source_path" "$PUBLIC_ATTACHMENTS/$image_name"
            echo "Copied $image_name to Blog-Attachments directories"

            # Update the reference to use Blog-Attachments with standard markdown
            escaped_image_ref=$(echo "$image_ref" | sed 's/[[\/*]/\\&/g')
            new_ref="![](../Blog-Attachments/$image_name)"
            sed -i.bak "s|$escaped_image_ref|$new_ref|g" "$post"
            echo "Updated reference in $post"
        else
            echo "Warning: Image $source_path not found"
        fi
    done
done

# Clean up backup files
find "content/Blog-Posts" -name "*.bak" -delete

echo "Migration complete!"
