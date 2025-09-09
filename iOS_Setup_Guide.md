# iOS Setup Guide for FareGuard Smart Ticket MTC App

## Prerequisites for iOS Development on macOS

This app is now configured to run on both Android and iOS. However, iOS development requires a macOS system with Xcode installed.

### 1. Required Software (macOS only):
- macOS 10.15 or later
- Xcode 12.0 or later
- CocoaPods (install with: `sudo gem install cocoapods`)

### 2. Firebase Configuration Added:
✅ GoogleService-Info.plist added to ios/Runner/
✅ Firebase initialized in AppDelegate.swift
✅ Bundle identifier updated to: com.smart.ticket.system
✅ Firebase options configured for iOS in firebase_options.dart
✅ Firebase Cloud Messaging added to pubspec.yaml

### 3. iOS Permissions Added:
✅ Location permissions (when in use and always)
✅ Motion sensor permissions
✅ Camera permissions (for QR scanning)
✅ Face ID permissions
✅ Embedded views support

### 4. Setup Instructions (macOS required):

#### Step 1: Install CocoaPods (if not already installed)
```bash
sudo gem install cocoapods
```

#### Step 2: Navigate to iOS directory and install pods
```bash
cd ios
pod install
```

#### Step 3: Open iOS project in Xcode
```bash
open Runner.xcworkspace
```

#### Step 4: Configure iOS Signing
1. In Xcode, select the Runner project
2. Go to Signing & Capabilities
3. Select your development team
4. Ensure bundle identifier is: com.smart.ticket.system

#### Step 5: Run on iOS
```bash
# From project root
flutter run -d ios
# or from Xcode, click Run button
```

### 5. Features Enabled on iOS:
- ✅ Firebase Authentication
- ✅ Cloud Firestore database
- ✅ Firebase Realtime Database
- ✅ Push notifications via FCM
- ✅ Location tracking with GPS
- ✅ Motion sensor monitoring
- ✅ Google Maps integration
- ✅ QR code scanning
- ✅ Biometric authentication (Face ID/Touch ID)
- ✅ Secure storage
- ✅ Fraud detection system
- ✅ Real-time bus tracking
- ✅ Payment processing via Razorpay

### 6. iOS-Specific Notes:
- All required permissions have been added to Info.plist
- Firebase configuration matches your project settings
- Bundle identifier correctly configured
- Minimum iOS version: 12.0
- All Flutter plugins support iOS

### 7. Testing on iOS:
- Use iOS Simulator for initial testing
- Use physical device for full sensor testing
- Fraud detection requires actual device sensors
- Location tracking requires device with GPS

## Current Status: ✅ Ready for iOS Development

Your app is now fully configured to run on iOS! You just need a macOS system with Xcode to build and run the iOS version.

## Build Commands:
```bash
# For iOS (requires macOS)
flutter build ios --release

# For Android (works on any platform)
flutter build apk --release
```

## Firebase Project Configuration:
- Project ID: smart-ticket-mtc
- iOS Bundle ID: com.smart.ticket.system
- Android Package: com.smart.ticket_system
- Database URL: https://smart-ticket-mtc-default-rtdb.firebaseio.com
