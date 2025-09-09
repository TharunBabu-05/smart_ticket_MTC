# Cloud-Based iOS Build Services

## 1. Codemagic (Recommended)
- **Website**: https://codemagic.io
- **Free Tier**: 500 build minutes/month
- **Features**: 
  - Automated iOS builds
  - Direct .ipa generation
  - TestFlight integration
  - App Store deployment

### Setup Steps:
1. Create account at codemagic.io
2. Connect your GitHub repository
3. Configure build settings for iOS
4. Add your Apple Developer certificates
5. Trigger build to generate .ipa

## 2. GitHub Actions with Mac Runners
- **Cost**: $0.08 per minute for macOS runners
- **Setup**: Create `.github/workflows/ios.yml`

```yaml
name: iOS Build
on:
  push:
    branches: [ main ]

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.32.6'
    - name: Install dependencies
      run: flutter pub get
    - name: Build iOS
      run: flutter build ipa --release
    - name: Upload IPA
      uses: actions/upload-artifact@v3
      with:
        name: ios-ipa
        path: build/ios/ipa/*.ipa
```

## 3. Bitrise
- **Website**: https://bitrise.io
- **Free Tier**: 200 builds/month
- **Features**: Similar to Codemagic

## 4. Azure DevOps
- **Free Tier**: 1800 minutes/month for macOS
- **Setup**: Create pipeline with macOS agent

## 5. CircleCI
- **Cost**: Paid service for macOS builds
- **Features**: Professional CI/CD pipeline
