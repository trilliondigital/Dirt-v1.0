#!/bin/bash

# Cleanup script for Dirt v1.0
# This will:
# 1. Remove redundant directories
# 2. Consolidate files
# 3. Clean up temporary files

set -e

# Move to project root
cd "$(dirname "$0")"

echo "🚀 Starting cleanup..."

# 1. Remove redundant DirtApp folder (contents are in ios/)
if [ -d "DirtApp" ]; then
    echo "Removing redundant DirtApp directory..."
    rm -rf DirtApp
fi

# 2. Check for any unique files in Legacy_iOS_Backup
if [ -d "Legacy_iOS_Backup_1754175146" ]; then
    echo "Checking for unique files in Legacy_iOS_Backup..."
    
    # Check for any unique documentation
    if [ -f "Legacy_iOS_Backup_1754175146/Documentation/Dirt — Whitepaper.md" ] && [ ! -f "docs/whitepaper.md" ]; then
        echo "  - Moving whitepaper to docs/"
        mkdir -p docs
        mv "Legacy_iOS_Backup_1754175146/Documentation/Dirt — Whitepaper.md" "docs/whitepaper.md"
    fi
    
    # Clean up the backup directory
    echo "  - Removing Legacy_iOS_Backup directory"
    rm -rf Legacy_iOS_Backup_1754175146
fi

# 3. Clean up macOS system files
find . -name ".DS_Store" -delete
find . -name "*.swp" -delete
find . -name "*.swo" -delete

# 4. Ensure proper directory structure
mkdir -p backend/migrations
mkdir -p docs
mkdir -p ios/DirtApp/Sources/{App,Features,Services,Models,Resources}

# 5. Verify all critical files exist
if [ ! -f "backend/setup_supabase.sh" ]; then
    echo "⚠️  Warning: setup_supabase.sh not found in backend/"
fi

if [ ! -d "ios/DirtApp/Sources/App" ]; then
    echo "⚠️  Warning: iOS app directory structure incomplete"
fi

echo "✅ Cleanup complete!"
echo "Project structure:"
tree -L 3

# Make the script executable
chmod +x cleanup.sh

echo "\nTo complete the cleanup, run: ./cleanup.sh"
