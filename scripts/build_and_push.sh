#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print styled messages
print_step() {
    echo -e "${BLUE}=>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is required but not installed."
        exit 1
    fi
}

# Check required commands
check_command "hugo"
check_command "git"

# Ensure we're in the git repository root
if [ ! -d ".git" ]; then
    print_error "Please run this script from the root of the git repository"
    exit 1
fi

# Clear screen for better presentation
clear

echo -e "${BLUE}┌────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC}      Blog Build and Push Tool       ${BLUE}│${NC}"
echo -e "${BLUE}└────────────────────────────────────┘${NC}"
echo

# Step 1: Run migrate_attachments.sh
print_step "Running attachment migration..."
if ./scripts/migrate_attachments.sh; then
    print_success "Attachment migration completed"
else
    print_error "Attachment migration failed"
    exit 1
fi

# Step 2: Remove existing public directory
print_step "Removing existing public directory..."
if [ -d "public" ]; then
    rm -rf public
    print_success "Existing public directory removed"
else
    print_warning "No existing public directory found"
fi

# Step 3: Generate new site
print_step "Generating new site with Hugo..."
if hugo -t paper --baseURL "https://btuckerc.github.io/Blog/"; then
    print_success "Site generated successfully"
else
    print_error "Failed to generate site"
    exit 1
fi

# Step 4: Git status check
print_step "Checking git status..."
git status

# Check if only public directory has changes
only_public_changes=true
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*[MADRCU] && ! "$line" =~ ^[[:space:]]*[MADRCU][[:space:]]public/ ]]; then
        only_public_changes=false
        break
    fi
done < <(git status --porcelain)

# Step 5: Ask for confirmation
echo
read -p "$(echo -e ${BLUE}?${NC}) Would you like to commit these changes? [y/N] " response
if [[ "$response" =~ ^[Yy]$ ]]; then
    # Set default commit message based on changes
    default_message="update public [script]"
    if ! $only_public_changes; then
        default_message="Update site content and rebuild"
    fi

    # Get commit message
    echo
    read -p "$(echo -e ${BLUE}?${NC}) Enter commit message (default: $default_message): " commit_message

    if [ -z "$commit_message" ]; then
        commit_message="$default_message"
    fi

    # Add and commit changes
    print_step "Committing changes..."
    if git add .; then
        if git commit -m "$commit_message"; then
            print_success "Changes committed successfully"

            # Push to main
            print_step "Pushing to main branch..."
            if git push origin main; then
                print_success "Changes pushed to main successfully"
                echo
                echo -e "${GREEN}┌────────────────────────────────────┐${NC}"
                echo -e "${GREEN}│${NC}    All operations completed successfully ${GREEN}│${NC}"
                echo -e "${GREEN}└────────────────────────────────────┘${NC}"
            else
                print_error "Failed to push changes"
                exit 1
            fi
        else
            print_error "Failed to commit changes"
            exit 1
        fi
    else
        print_error "Failed to stage changes"
        exit 1
    fi
else
    print_warning "Operation cancelled by user"
    exit 0
fi
