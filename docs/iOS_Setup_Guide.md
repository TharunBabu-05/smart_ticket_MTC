# iOS Setup Guide for Smart Ticket MTC

## Prerequisites for iOS Development on Windows
Since you're on Windows, you'll need a Mac to properly test and deploy iOS apps. However, we can set up the configuration files now.

## What Has Been Configured:

### 1. ✅ Firebase iOS Configuration
- `GoogleService-Info.plist` added to `ios/Runner/`
- Bundle identifier updated to `com.smart.ticket.system`
- Firebase iOS options configured in `firebase_options.dart`

### 2. ✅ iOS Permissions
Added to `ios/Runner/Info.plist`:
- Location permissions (NSLocationWhenInUseUsageDescription)
- Motion sensors (NSMotionUsageDescription)  
- Camera access (NSCameraUsageDescription)
- Face ID (NSFaceIDUsageDescription)

### 3. ✅ AppDelegate Configuration
- Firebase initialization added to `AppDelegate.swift`
- Import Firebase framework

### 4. ✅ Dependencies
- Firebase Cloud Messaging added for push notifications
- All required iOS dependencies configured

## Next Steps (Requires Mac):

### 1. Install CocoaPods (on Mac)
```bash
sudo gem install cocoapods
```

### 2. Install iOS Dependencies (on Mac)
```bash
cd ios
pod install
```

### 3. Open in Xcode (on Mac)
```bash
open ios/Runner.xcworkspace
```

### 4. Configure Signing & Capabilities in Xcode
- Set your Apple Developer Team
- Enable Push Notifications capability
- Enable Background Modes (if needed)

## Testing on Windows (Limited)
You can test the Android version and use iOS Simulator through cloud services or remote Mac access.

## Bundle Identifier
- iOS: `com.smart.ticket.system`
- Android: `com.smart.ticket_system`

Both are properly configured in Firebase console.
