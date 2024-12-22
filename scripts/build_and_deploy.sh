#!/bin/bash

# Exit on error
set -e

echo "🔄 Starting build and deploy process..."

# Initialize git if needed
if [ ! -d ".git" ]; then
    echo "📦 Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit"
fi

# Create main branch if it doesn't exist
if ! git rev-parse --verify main >/dev/null 2>&1; then
    echo "🌱 Creating main branch..."
    git checkout -b main
fi

# Ensure we're on the main branch
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "none")
if [ "$current_branch" != "main" ]; then
    echo "🔄 Switching to main branch..."
    git checkout main || git checkout -b main
fi

# Check for uncommitted changes and handle them interactively
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 Uncommitted changes detected:"
    git status --short

    read -p "Would you like to commit these changes? (y/n): " should_commit
    if [[ $should_commit =~ ^[Yy]$ ]]; then
        git add .
        read -p "Enter commit message (default: 'Update content'): " commit_msg
        commit_msg=${commit_msg:-"Update content"}
        git commit -m "$commit_msg"
    else
        echo "❌ Please handle the uncommitted changes before deploying."
        exit 1
    fi
fi

# Run the image migration script to ensure all images are in the right place
echo "🖼️  Checking image locations..."
./scripts/migrate_attachments.sh

# Build the static site first while on main branch
echo "🏗️  Building static site..."
hugo --minify

# Store the absolute path to the public directory
PUBLIC_DIR="$(pwd)/public"

# Create and switch to public branch
echo "📋 Setting up public branch..."
if git show-ref --verify --quiet refs/heads/public; then
    git checkout public
    # Clean the branch but keep .git
    git rm -rf .
    git clean -fdx
else
    git checkout --orphan public
    git rm -rf .
    git clean -fdx
fi

# Copy the built site from the stored public directory
echo "📋 Copying new content..."
cp -r "$PUBLIC_DIR"/* .
cp -r "$PUBLIC_DIR"/.[!.]* . 2>/dev/null || true

# Add and commit
echo "💾 Committing changes..."
git add .
git commit -m "Update site: $(date +"%Y-%m-%d %H:%M:%S")" || true

# Add remote if it doesn't exist
if ! git remote | grep -q "^origin$"; then
    echo "⚠️  No remote 'origin' found."
    read -p "Would you like to add a GitHub remote now? (y/n): " add_remote
    if [[ $add_remote =~ ^[Yy]$ ]]; then
        read -p "Enter your GitHub repository URL: " repo_url
        git remote add origin "$repo_url"
    else
        echo "Please add a remote later with: git remote add origin <your-repo-url>"
        git checkout main
        exit 1
    fi
fi

# Push changes
echo "⬆️  Pushing to public branch..."
git push origin public -f

# Push main branch as well
echo "⬆️  Pushing main branch..."
git checkout main
git push -u origin main

echo "✅ Deploy complete! The static site is now in the public branch."
echo "🌐 You can now use the contents of the public branch for hosting."
