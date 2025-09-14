/// User Manual Content for FareGuard
/// Comprehensive guide covering all app features, troubleshooting, and usage instructions

class UserManualContent {
  static final Map<String, ManualSection> sections = {
    'getting_started': ManualSection(
      title: '🚀 Getting Started',
      icon: '🚀',
      subsections: [
        ManualSubsection(
          title: 'Welcome to FareGuard',
          content: '''
**FareGuard** is your smart bus ticketing companion for Chennai MTC buses. With advanced voice guidance, multilingual support, and AI-powered fraud detection, we make bus travel convenient and secure.

## Key Features:
- 🎤 **Voice Booking**: Book tickets by speaking
- 🌍 **Multilingual Support**: English, Tamil, Hindi
- 📍 **Smart Location**: Auto-detect nearby stations  
- 🔒 **Fraud Detection**: Advanced security algorithms
- 💳 **Multiple Payments**: UPI, Cards, Wallets
- 🎫 **Digital Tickets**: QR code based boarding
          ''',
        ),
        ManualSubsection(
          title: 'First Time Setup',
          content: '''
## Initial Setup Steps:

### 1. 📱 App Installation
- Download from Play Store/App Store
- Grant required permissions when prompted
- Complete registration with phone number

### 2. 🔐 Permissions Required
- **📍 Location**: Essential for finding nearby bus stops
- **🎤 Microphone**: Required for voice commands
- **🔔 Notifications**: Get ticket updates and alerts
- **📷 Camera**: Optional, for QR code scanning

### 3. 🌍 Language Selection
- Choose your preferred language during setup
- Options: English, தமிழ் (Tamil), हिंदी (Hindi)
- Can be changed anytime in Settings

### 4. 📍 Location Setup
- Enable GPS for accurate station detection
- Allow "Always" location access for best experience
- Test location by viewing nearby stations

### 5. 🎤 Voice Features Setup
- Test microphone by trying voice input
- Speak clearly in a quiet environment
- Voice works in your selected language
          ''',
        ),
        ManualSubsection(
          title: 'Home Screen Overview',
          content: '''
## Navigation Guide:

### 🏠 Home Screen Elements:
- **Quick Book**: Fast ticket booking
- **Popular Stations**: Commonly used stops
- **Voice Booking**: Hands-free booking option
- **Current Location**: Your detected position
- **Recent Bookings**: Quick access to history

### 🧭 Bottom Navigation:
- **Home**: Main dashboard
- **My Tickets**: Active and past tickets
- **Voice Booking**: Speech-enabled booking
- **Help**: Chatbot and user manual
- **Settings**: Preferences and account
          ''',
        ),
      ],
    ),
    
    'ticket_booking': ManualSection(
      title: '🎫 Ticket Booking',
      icon: '🎫',
      subsections: [
        ManualSubsection(
          title: 'Regular Ticket Booking',
          content: '''
## Step-by-Step Booking Guide:

### 1. 🎯 Select Journey Type
- **Single Journey**: One-way ticket
- **Return Journey**: Round-trip booking
- **Student/Senior**: Discounted tickets

### 2. 📍 Choose Stations
- **Source Station**: Your starting point
  - Type station name or select from suggestions
  - Use current location for nearby stops
- **Destination Station**: Your destination
  - Browse popular destinations
  - Search by name or area

### 3. 🚌 Select Route & Timing
- View available routes between stations
- Check estimated travel time
- See real-time bus availability

### 4. 🎫 Ticket Options
- **Regular**: Standard fare
- **AC Bus**: Air-conditioned service (+₹15)
- **Express**: Limited stops (+₹5)
- **Student**: 50% discount (ID required)
- **Senior Citizen**: 25% discount (60+ age)

### 5. 💳 Payment
- Choose payment method
- Complete secure payment
- Receive ticket confirmation

### 6. 📱 Receive Digital Ticket
- QR code generated instantly
- Show to conductor during boarding
- Ticket stored in "My Tickets"
          ''',
        ),
        ManualSubsection(
          title: 'Voice Booking Guide',
          content: '''
## 🎤 Hands-Free Ticket Booking:

### Getting Started with Voice:
1. **Tap Voice Booking** from home screen
2. **Grant microphone permission** if prompted
3. **Speak clearly** in your preferred language
4. **Follow voice prompts** for confirmation

### Voice Commands:
```
"Book ticket from Chennai Central to Egmore"
"I want to go from T Nagar to Airport"
"Student ticket from Guindy to Velachery"
"Return journey from home to Marina Beach"
```

### Voice Booking Process:
1. **🎙️ Speak Source**: "From Chennai Central"
2. **🎯 Confirm**: App repeats for verification  
3. **🎙️ Speak Destination**: "To Egmore"
4. **✅ Confirm Route**: Review detected stations
5. **💳 Complete Payment**: Choose payment method
6. **🎫 Receive Ticket**: QR code generated

### Tips for Best Voice Recognition:
- Speak in quiet environment
- Use clear, normal pace
- Pronounce station names clearly
- Use common station names
- Retry if not recognized correctly

### Supported Voice Languages:
- **English**: All station names supported
- **Tamil**: Local station names in Tamil
- **Hindi**: Major station names in Hindi
          ''',
        ),
        ManualSubsection(
          title: 'Payment Methods',
          content: '''
## 💳 Secure Payment Options:

### Available Payment Methods:
1. **🏦 UPI Payments**
   - Google Pay, PhonePe, Paytm
   - BHIM UPI, Amazon Pay
   - Bank UPI apps
   
2. **💳 Credit/Debit Cards**
   - Visa, MasterCard, RuPay
   - Domestic and international cards
   - EMI options for higher amounts
   
3. **🏛️ Net Banking**
   - All major Indian banks
   - Secure bank gateway
   - Real-time confirmation
   
4. **📱 Digital Wallets**
   - Paytm Wallet
   - Razorpay Wallet
   - FreeCharge

### Payment Security:
- **🔒 SSL Encryption**: All transactions encrypted
- **🛡️ PCI Compliance**: Industry-standard security
- **🔐 Two-Factor Authentication**: Added security layer
- **📧 Transaction Alerts**: Email/SMS confirmations

### Payment Troubleshooting:
- Check internet connection
- Verify card/account balance
- Try alternative payment method
- Contact bank if transaction fails
- Use "Retry Payment" for failed transactions
          ''',
        ),
      ],
    ),
    
    'voice_features': ManualSection(
      title: '🎤 Voice Features',
      icon: '🎤',
      subsections: [
        ManualSubsection(
          title: 'Voice Input & Commands',
          content: '''
## 🗣️ Complete Voice Command Guide:

### Basic Voice Commands:
```
✅ Booking Commands:
"Book a ticket"
"I want to travel"
"Book from [source] to [destination]"
"Student ticket to [destination]"
"Return journey to [destination]"

✅ Navigation Commands:
"Show my tickets"
"Check ticket history"
"Go to settings"
"Help me with booking"

✅ Station Commands:
"Popular stations"
"Nearby bus stops"
"Airport bus"
"Beach area buses"
```

### Voice Booking Flow:
1. **🎤 Start**: "Book a ticket"
2. **📍 Source**: "From Chennai Central"
3. **🎯 Destination**: "To Marina Beach"
4. **✅ Confirm**: "Yes, book it"
5. **💳 Payment**: Follow payment prompts

### Advanced Voice Features:
- **Smart Recognition**: Understands variations in pronunciation
- **Context Awareness**: Remembers previous inputs
- **Error Correction**: "Did you mean [station name]?"
- **Multi-language**: Switch languages mid-conversation
          ''',
        ),
        ManualSubsection(
          title: 'Multilingual Support',
          content: '''
## 🌍 Language Support Guide:

### Supported Languages:
1. **English** 🇺🇸
   - Full feature support
   - All station names
   - Complete voice commands
   
2. **Tamil** 🇮🇳
   - Chennai station names in Tamil
   - Tamil voice commands
   - Regional pronunciation support
   
3. **Hindi** 🇮🇳
   - Major station names in Hindi
   - Basic voice commands
   - North Indian pronunciation

### Language Switching:
- **Settings Method**: Go to Settings → Language
- **Voice Method**: Say "Change language to Tamil/Hindi"
- **Auto-Detection**: App detects spoken language

### Tamil Voice Examples:
```
"சென்ட்ரல்-லேருந்து எழும்பூர்" (Central to Egmore)
"கீ.ப.ரா.-லேருந்து விமான நிலையம்" (T.Nagar to Airport)
"மரீன பீச் போக வேணும்" (Want to go to Marina Beach)
```

### Hindi Voice Examples:
```
"सेंट्रल से एयरपोर्ट" (Central to Airport)
"मुझे टी नगर जाना है" (I want to go to T Nagar)
"स्टूडेंट टिकट चाहिए" (Need student ticket)
```
          ''',
        ),
        ManualSubsection(
          title: 'Voice Troubleshooting',
          content: '''
## 🔧 Voice Feature Troubleshooting:

### Common Issues & Solutions:

### 🎤 Microphone Not Working:
**Problem**: Voice input not detected
**Solutions**:
- Check microphone permission in device settings
- Test microphone in other apps
- Restart the app
- Clean microphone opening
- Check for mute/silent mode

### 🔊 Speech Not Recognized:
**Problem**: App doesn't understand speech
**Solutions**:
- Speak more slowly and clearly
- Reduce background noise
- Use common station names
- Try different pronunciation
- Switch to manual typing

### 🌐 Voice Commands Not Working:
**Problem**: Commands not executed
**Solutions**:
- Check internet connection
- Update app to latest version
- Restart voice service in settings
- Clear app cache
- Re-grant microphone permission

### 📱 App Not Speaking Back:
**Problem**: No voice feedback
**Solutions**:
- Check device volume level
- Enable text-to-speech in settings
- Test with other TTS apps
- Check language settings
- Restart app

### Performance Optimization:
- Use in quiet environments
- Keep app updated
- Clear app cache regularly
- Close other voice apps
- Ensure stable internet connection
          ''',
        ),
      ],
    ),
    
    'fraud_detection': ManualSection(
      title: '🔒 Fraud Detection',
      icon: '🔒',
      subsections: [
        ManualSubsection(
          title: 'How Fraud Detection Works',
          content: '''
## 🛡️ Advanced Security Features:

### AI-Powered Protection:
FareGuard uses advanced algorithms to detect and prevent fraudulent activities:

### 📍 Location Verification:
- **GPS Monitoring**: Verifies you're near boarding location
- **Distance Warnings**: Alerts if too far from bus stop
- **Route Validation**: Ensures realistic travel patterns
- **Time-based Checks**: Prevents impossible travel times

### 🎫 Ticket Authenticity:
- **Unique QR Codes**: Each ticket has encrypted QR
- **Real-time Validation**: Instant verification during scanning
- **Duplicate Prevention**: Blocks reuse of same ticket
- **Tampering Detection**: Identifies modified tickets

### 📊 Behavioral Analysis:
- **Usage Patterns**: Monitors normal vs abnormal behavior
- **Multiple Booking Detection**: Prevents bulk fake bookings
- **Payment Validation**: Verifies payment authenticity
- **Account Activity**: Tracks suspicious account behavior

### 🚨 Real-time Alerts:
- **Fraud Attempts**: Immediate notification of suspicious activity
- **Location Mismatches**: Warns about location inconsistencies
- **Payment Issues**: Alerts for failed/suspicious payments
- **Account Security**: Notifies about login anomalies
          ''',
        ),
        ManualSubsection(
          title: 'Security Best Practices',
          content: '''
## 🔐 Keep Your Account Secure:

### Account Security:
- **🔑 Strong Passwords**: Use unique, complex passwords
- **📱 Two-Factor Authentication**: Enable SMS/email verification
- **🔄 Regular Updates**: Keep app updated to latest version
- **🚫 Avoid Sharing**: Don't share login credentials

### Safe Booking Practices:
- **📍 Location Services**: Keep GPS enabled for accurate detection
- **🎫 Genuine Tickets**: Only book through official FareGuard app
- **💳 Secure Payments**: Use trusted payment methods only
- **📱 Official App**: Download only from official app stores

### Reporting Suspicious Activity:
- **🚨 Report Fraud**: Use in-app reporting for suspicious activity
- **📞 Contact Support**: Immediate help for security concerns
- **🔍 Monitor Transactions**: Regular check of booking history
- **⚡ Quick Response**: Report issues immediately

### What We Monitor:
- Unusual booking patterns
- Location inconsistencies
- Multiple rapid bookings
- Payment irregularities
- Account access anomalies
- Ticket sharing attempts
          ''',
        ),
      ],
    ),
    
    'troubleshooting': ManualSection(
      title: '🛠️ Troubleshooting',
      icon: '🛠️',
      subsections: [
        ManualSubsection(
          title: 'Common Issues',
          content: '''
## ⚡ Quick Problem Solvers:

### 📱 App Issues:

#### App Won't Start:
- Force close and restart app
- Restart your device
- Check available storage space
- Update to latest version
- Clear app cache in device settings

#### App Crashes Frequently:
- Update app from store
- Restart device
- Free up device storage (need 1GB+ free)
- Close other running apps
- Reinstall if problems persist

#### Slow Performance:
- Close unnecessary background apps
- Check internet connection speed
- Clear app cache
- Restart device
- Use WiFi instead of mobile data

### 🌐 Connection Issues:

#### No Internet Connection:
- Check WiFi/mobile data status
- Try switching between WiFi and mobile data
- Restart your router/modem
- Move to area with better signal
- Contact your service provider

#### Poor GPS Signal:
- Enable high-accuracy location mode
- Move to open area (away from buildings)
- Restart location services
- Check GPS in other apps
- Allow location permission for app

### 🎫 Booking Problems:

#### Booking Fails:
- Check internet connection
- Verify payment method
- Try different payment option
- Clear app cache
- Contact support with error details

#### Payment Declined:
- Check card/account balance
- Verify card details
- Try alternative payment method
- Contact your bank
- Check if card is blocked

#### Ticket Not Received:
- Check My Tickets section
- Verify email/SMS notifications
- Check payment status
- Wait 2-3 minutes and refresh
- Contact support with booking ID
          ''',
        ),
        ManualSubsection(
          title: 'Error Messages Guide',
          content: '''
## 📋 Understanding Error Messages:

### Payment Errors:
```
❌ "Payment Failed"
→ Check bank balance, card validity
→ Try different payment method
→ Contact bank if card is blocked

❌ "Transaction Timeout"
→ Poor internet connection
→ Retry after few minutes
→ Use stable WiFi connection

❌ "Card Not Supported"  
→ Use different card
→ Try UPI instead
→ Check with card issuer
```

### Location Errors:
```
❌ "Location Not Found"
→ Enable GPS/Location services
→ Grant location permission
→ Move to open area
→ Restart location services

❌ "Too Far from Station"
→ Move closer to bus stop
→ Use manual station selection
→ Check GPS accuracy
→ Override warning if intentional
```

### Booking Errors:
```
❌ "Invalid Route"
→ Check station names
→ Verify route availability
→ Try alternative stations
→ Contact support

❌ "Service Not Available"
→ Check time restrictions
→ Try different route
→ Service may be temporarily down
→ Try again later
```

### Voice Errors:
```
❌ "Voice Recognition Failed"
→ Speak more clearly
→ Reduce background noise
→ Check microphone permission
→ Try manual input

❌ "Language Not Supported"
→ Switch to supported language
→ Update app to latest version
→ Check language settings
→ Use English as fallback
```
          ''',
        ),
      ],
    ),
    
    'faq': ManualSection(
      title: '❓ FAQ',
      icon: '❓',
      subsections: [
        ManualSubsection(
          title: 'Frequently Asked Questions',
          content: '''
## 🤔 Most Common Questions:

### General Questions:

**Q: Is FareGuard free to use?**
A: Yes! FareGuard is completely free. You only pay for your bus tickets.

**Q: Which cities/routes are supported?**
A: Currently supports Chennai MTC buses. More cities coming soon!

**Q: Can I use FareGuard offline?**
A: Limited offline features available. Internet required for booking and payments.

**Q: Is my payment information secure?**
A: Yes! All payments use bank-level encryption and PCI-compliant security.

### Booking Questions:

**Q: How early can I book a ticket?**
A: Book up to 7 days in advance or just before boarding.

**Q: Can I cancel or modify a booked ticket?**
A: Yes, cancellation allowed up to 30 minutes before departure for full refund.

**Q: What if I miss my bus?**
A: Tickets are valid for next available bus on same route within 24 hours.

**Q: Can I book multiple tickets at once?**
A: Yes, book up to 6 tickets per transaction for group travel.

### Voice Questions:

**Q: Does voice work in noisy environments?**
A: Best results in quiet environments. Use manual input in very noisy places.

**Q: Can I mix languages while speaking?**
A: App supports one language at a time. Switch languages in settings.

**Q: What if voice doesn't recognize my pronunciation?**
A: Try speaking slower, use common station names, or use manual input.

### Payment Questions:

**Q: Why was my payment deducted but no ticket received?**
A: Usually resolves within 2-3 minutes. Auto-refund if not resolved in 24 hours.

**Q: Can I get a refund for unused tickets?**
A: Yes, full refund if cancelled 30+ minutes before departure.

**Q: Are there any booking charges?**
A: No extra charges! Pay only the official MTC bus fare.
          ''',
        ),
      ],
    ),
  };
}

class ManualSection {
  final String title;
  final String icon;
  final List<ManualSubsection> subsections;

  ManualSection({
    required this.title,
    required this.icon,
    required this.subsections,
  });
}

class ManualSubsection {
  final String title;
  final String content;

  ManualSubsection({
    required this.title,
    required this.content,
  });
}