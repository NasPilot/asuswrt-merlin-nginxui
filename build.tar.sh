#!/bin/bash

NGINXUI_VERSION=${1:-"1.0.0"}

NODE_ENV=production npx vite build

# Create a temporary directory for packaging
mkdir -p temp_build/nginxui

# Copy all dist files to the nginxui subdirectory
cp -r dist/* temp_build/nginxui/

# Update version in webapp.sh if it exists
if [ -f "temp_build/nginxui/webapp.sh" ]; then
    echo "Updating NGINXUI_VERSION to $NGINXUI_VERSION in webapp.sh"
    sed -i.bak "s/^NGINXUI_VERSION=.*/NGINXUI_VERSION=\"$NGINXUI_VERSION\"/" temp_build/nginxui/webapp.sh
    rm -f temp_build/nginxui/webapp.sh.bak
fi

# Create tar.gz file
tar -czf asuswrt-merlin-nginxui.tar.gz -C temp_build .

# Clean up
rm -rf temp_build

echo "Build completed: asuswrt-merlin-nginxui.tar.gz"
