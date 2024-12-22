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

# Remove public directory if it exists
echo "🗑️  Cleaning public directory..."
rm -rf public

# Auto-commit blog post changes, check other changes interactively
if [ -n "$(git status --porcelain)" ]; then
    # Check if there are changes only in content/Blog-Posts
    if [ -n "$(git status --porcelain | grep -v "content/Blog-Posts" | grep -v "public/" | grep -v "D public")" ]; then
        echo "📝 Changes detected outside of blog posts:"
        git status --short | grep -v "content/Blog-Posts" | grep -v "public/" | grep -v "D public"

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
    else
        # Auto-commit blog post changes
        if [ -n "$(git status --porcelain | grep "content/Blog-Posts")" ]; then
            echo "📝 Auto-committing blog post changes..."
            git add content/Blog-Posts
            git commit -m "Updating blog post [script]"
        fi
    fi
fi

# Store the current directory
CURRENT_DIR=$(pwd)

# Create and switch to public branch (force clean)
echo "📋 Setting up public branch..."
if git show-ref --verify --quiet refs/heads/public; then
    # Delete the local public branch
    git branch -D public
fi

# Create a new public branch from main
git checkout -b public main

# Remove everything except .git
echo "🗑️  Cleaning public branch..."
git rm -rf .
git clean -fdx

# Update submodules
echo "📦 Updating submodules..."
git submodule update --init --recursive

# Build the static site with the paper theme
echo "🏗️  Building static site..."
hugo -t paper --minify

# Add and commit public content
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

# Push public branch
echo "⬆️  Pushing public branch..."
git push origin public -f

# Switch back to main branch and reinitialize submodules
echo "↩️  Switching back to main branch and reinitializing submodules..."
git checkout main
git submodule update --init --recursive

echo "✅ Deploy complete! The static site is now in the public branch."
echo "🌐 You can now use the contents of the public branch for hosting."
