#!/bin/bash

# iOS Build Script for Smart Ticket MTC
# Run this script on a Mac to build the iOS IPA file

echo "🍎 Starting iOS Build Process for Smart Ticket MTC..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Install iOS dependencies
echo "🔧 Installing iOS dependencies (CocoaPods)..."
cd ios

# Install CocoaPods if not installed
if ! command -v pod &> /dev/null; then
    echo "📱 Installing CocoaPods..."
    sudo gem install cocoapods
fi

# Install pods
pod install

# Go back to project root
cd ..

echo "🔨 Building iOS release..."

# Option 1: Build IPA (signed - requires Apple Developer account)
echo "Choose build option:"
echo "1) Build signed IPA (requires Apple Developer account)"
echo "2) Build unsigned (for testing/development)"
read -p "Enter choice (1 or 2): " choice

if [ "$choice" == "1" ]; then
    echo "🔐 Building signed IPA..."
    flutter build ipa --release
    
    if [ $? -eq 0 ]; then
        echo "✅ Signed IPA built successfully!"
        echo "📍 Location: build/ios/ipa/smart_ticket_mtc.ipa"
        
        # Open the directory
        open build/ios/ipa/
    else
        echo "❌ Build failed. Please check your signing configuration."
    fi
    
elif [ "$choice" == "2" ]; then
    echo "🛠️ Building unsigned iOS app..."
    flutter build ios --release --no-codesign
    
    if [ $? -eq 0 ]; then
        echo "📦 Creating unsigned IPA..."
        mkdir -p build/ios/ipa
        cd build/ios/iphoneos
        mkdir -p Payload
        cp -r Runner.app Payload/
        zip -r ../ipa/smart_ticket_mtc_unsigned.ipa Payload/
        cd ../../..
        
        echo "✅ Unsigned IPA created successfully!"
        echo "📍 Location: build/ios/ipa/smart_ticket_mtc_unsigned.ipa"
        echo "⚠️  Note: This IPA can only be installed on jailbroken devices or simulators"
        
        # Open the directory
        open build/ios/ipa/
    else
        echo "❌ Build failed."
    fi
else
    echo "❌ Invalid choice"
    exit 1
fi

echo "🎉 iOS build process completed!"
echo ""
echo "📱 To install on your iOS device:"
echo "   1. Use Xcode: Window > Devices and Simulators"
echo "   2. Use TestFlight (for signed builds)"
echo "   3. Use third-party tools like 3uTools or AltStore"
