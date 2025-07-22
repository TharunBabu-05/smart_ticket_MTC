# Smart Ticket MTC - Setup Instructions

## Google Maps API Key Setup

The map functionality requires a Google Maps API key to work properly. Follow these steps:

1. **Get Google Maps API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the "Maps SDK for Android" API
   - Create credentials (API Key)
   - Restrict the API key to your app's package name for security

2. **Configure the API Key:**
   - Open `android/app/src/main/AndroidManifest.xml`
   - Find the line: `android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"`
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

3. **Example:**
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"/>
   ```

## App Features

- **Bus Ticket Booking:** Book bus tickets with real-time location tracking
- **Monthly Pass:** Purchase monthly bus passes
- **Live Map:** View nearby bus stops and your current location
- **Route Information:** Get information about bus routes and stops

## Build Instructions

1. Run `flutter pub get` to install dependencies
2. Configure Google Maps API key (see above)
3. Run `flutter build apk --release` to build the app

## Troubleshooting

- If the map doesn't show, check that the Google Maps API key is correctly configured
- Ensure location permissions are granted in device settings
- Make sure "Maps SDK for Android" is enabled in Google Cloud Console
