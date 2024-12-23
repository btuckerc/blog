#!/bin/bash

# Create necessary directories if they don't exist
mkdir -p "content/Blog-Attachments"
mkdir -p "public/blog-posts/Blog-Attachments"

# Remove any incorrect directory if it exists
rm -rf "public/Blog-Attachments"

# Define source directories with absolute paths to avoid any confusion
# Use environment variable for ATTACHMENTS_DIR if provided, otherwise use default
ATTACHMENTS_DIR="${ATTACHMENTS_DIR:-/Users/tucker/Documents/00-Vault/03 - Resources/Attachments}"
BLOG_ATTACHMENTS="$(pwd)/content/Blog-Attachments"
PUBLIC_ATTACHMENTS="$(pwd)/public/blog-posts/Blog-Attachments"

echo "Using attachments directory: $ATTACHMENTS_DIR"
echo "Blog attachments directory: $BLOG_ATTACHMENTS"
echo "Public attachments directory: $PUBLIC_ATTACHMENTS"

# Process each markdown file
find "content/Blog-Posts" -name "*.md" 2>/dev/null | while read -r post; do
    post_name=$(basename "$post")
    echo "Processing: $post_name"

    # Find both wiki-style and standard markdown image references
    # First, find wiki-style references
    grep -o '!\[\[[^]]*\]\]' "$post" 2>/dev/null | while read -r image_ref; do
        image_path=$(echo "$image_ref" | sed -E 's/!\[\[(.*)\]\]/\1/' 2>/dev/null)
        image_name=$(basename "$image_path" 2>/dev/null)

        # Handle the image
        if [[ -f "$ATTACHMENTS_DIR/$image_name" ]]; then
            cp "$ATTACHMENTS_DIR/$image_name" "$BLOG_ATTACHMENTS/$image_name" 2>/dev/null
            cp "$ATTACHMENTS_DIR/$image_name" "$PUBLIC_ATTACHMENTS/$image_name" 2>/dev/null
            echo "  ↳ Copied: $image_name"

            # Convert to standard markdown format
            escaped_image_ref=$(echo "$image_ref" | sed 's/[[\/*]/\\&/g' 2>/dev/null)
            new_ref="![](../Blog-Attachments/$image_name)"
            sed -i.bak "s|$escaped_image_ref|$new_ref|g" "$post" 2>/dev/null
        else
            echo "  ⚠️ Warning: Image not found: $image_name"
        fi
    done

    # Then, find standard markdown references
    grep -o '!\[.*\]([^)]*Blog-Attachments[^)]*\.\(png\|jpg\|jpeg\|gif\))' "$post" 2>/dev/null | while read -r image_ref; do
        # Extract image path from standard markdown ![alt](path)
        image_path=$(echo "$image_ref" | sed -E 's/!\[.*\]\((.*)\)/\1/' 2>/dev/null)
        image_name=$(basename "$image_path" 2>/dev/null)

        # If the file exists in content/Blog-Attachments, ensure it's in public too
        if [[ -f "$BLOG_ATTACHMENTS/$image_name" ]]; then
            cp "$BLOG_ATTACHMENTS/$image_name" "$PUBLIC_ATTACHMENTS/$image_name" 2>/dev/null
            echo "  ↳ Updated: $image_name"
        elif [[ -f "$ATTACHMENTS_DIR/$image_name" ]]; then
            cp "$ATTACHMENTS_DIR/$image_name" "$BLOG_ATTACHMENTS/$image_name" 2>/dev/null
            cp "$ATTACHMENTS_DIR/$image_name" "$PUBLIC_ATTACHMENTS/$image_name" 2>/dev/null
            echo "  ↳ Copied: $image_name"
        else
            echo "  ⚠️ Warning: Image not found: $image_name"
        fi
    done
done

# Clean up backup files
find "content/Blog-Posts" -name "*.bak" -delete 2>/dev/null

# Verify the correct directory structure
echo "Verifying directory structure..."
ls -la "content/Blog-Attachments"
ls -la "public/blog-posts/Blog-Attachments"

# Ensure no wrong directory exists
if [ -d "public/Blog-Attachments" ]; then
    echo "Found incorrect public/Blog-Attachments directory, moving files..."
    mkdir -p "public/blog-posts/Blog-Attachments"
    mv public/Blog-Attachments/* "public/blog-posts/Blog-Attachments/" 2>/dev/null || true
    rm -rf "public/Blog-Attachments"
    echo "Files moved to correct location"
fi

echo "Attachment migration complete!"
