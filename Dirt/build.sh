#!/bin/bash

# Build script for Dirt iOS app
echo "Building Dirt iOS app..."

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Build the iOS app
xcodebuild -project Dirt.xcodeproj \
           -scheme Dirt \
           -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
           -configuration Debug \
           build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "You can now open Dirt.xcodeproj in Xcode to run the app."
else
    echo "❌ Build failed. Check the errors above."
    exit 1
fi