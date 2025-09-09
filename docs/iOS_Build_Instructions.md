# iOS Build Instructions for Mac

## Prerequisites
1. macOS system
2. Xcode installed (latest version)
3. Apple Developer account (for device testing/App Store)
4. CocoaPods installed

## Step-by-Step Instructions:

### 1. Install CocoaPods (if not installed)
```bash
sudo gem install cocoapods
```

### 2. Transfer your project to Mac
- Copy your entire `smart_ticket_mtc` folder to the Mac

### 3. Install iOS dependencies
```bash
cd smart_ticket_mtc/ios
pod install
```

### 4. Open Xcode workspace
```bash
open Runner.xcworkspace
```

### 5. Configure Xcode Project
- Select your Apple Developer Team in Signing & Capabilities
- Set Bundle Identifier: `com.smart.ticket.system`
- Enable required capabilities:
  - Push Notifications
  - Background Modes (if needed)
  - Location Services

### 6. Build for iOS Device
```bash
# Navigate back to project root
cd ..

# Build iOS release
flutter build ios --release

# Or build for specific device
flutter build ipa --release
```

### 7. Generate .ipa file
After building, the .ipa file will be located at:
`build/ios/ipa/smart_ticket_mtc.ipa`

### 8. Install on iOS Device
- Use Xcode to install directly
- Or use TestFlight for distribution
- Or use third-party tools like 3uTools, AltStore

## Troubleshooting
- Ensure all certificates are valid
- Check bundle identifier matches Firebase configuration
- Verify all required permissions are set
- Make sure Firebase GoogleService-Info.plist is properly added
