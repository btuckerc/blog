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

# Clear screen for better presentation
clear

echo -e "${BLUE}┌────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC}      Local Testing Environment      ${BLUE}│${NC}"
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

# Step 2: Start Hugo server
print_step "Starting Hugo server..."
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo
hugo server -t paper --baseURL http://localhost:1313/
