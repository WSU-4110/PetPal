#!/bin/bash
echo "Starting build..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run analyzer
flutter analyze

# Run all unit tests
flutter test

# Build the APK (optional)
flutter build apk

echo "Build and tests complete!"
