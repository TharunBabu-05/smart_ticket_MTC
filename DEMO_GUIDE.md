# Enhanced Smart Ticket MTC - Demo Guide

## 🚀 Project Overview

Smart Ticket MTC is a comprehensive Flutter application with advanced fraud detection capabilities and cross-platform communication system. The app demonstrates real-time fraud detection between a passenger app and a bus monitoring system.

## 🎯 Key Features

### ✅ Enhanced Ticket System
- **2-Hour Validation**: Tickets are valid for exactly 2 hours from purchase
- **Location Tracking**: Mandatory GPS tracking during ticket validity
- **QR Code Generation**: Unique QR codes for each ticket
- **Real-time Countdown**: Live ticket status with time remaining

### ✅ Cross-Platform Fraud Detection
- **Firebase Realtime Database**: Live communication between apps
- **Session Management**: Unique session IDs for each journey
- **Gyro/Sensor Data**: Motion detection for fraud analysis
- **Penalty System**: ₹5 per extra stop penalty calculation

### ✅ Advanced Authentication
- **Biometric Authentication**: Fingerprint/Face ID support
- **Multi-factor Authentication**: Enhanced security
- **Secure Storage**: Encrypted ticket and user data

## 🔧 Technical Architecture

### Backend Services
1. **CrossPlatformService** (`lib/services/cross_platform_service.dart`)
   - Manages Firebase Realtime Database connection
   - Handles session creation and data streaming
   - Performs fraud analysis at trip completion

2. **EnhancedTicketService** (`lib/services/enhanced_ticket_service.dart`)
   - Issues and validates tickets
   - Manages 2-hour lifecycle
   - Integrates with location services

3. **EnhancedAuthService** (`lib/services/enhanced_auth_service.dart`)
   - Biometric authentication
   - Secure session management
   - Multi-factor authentication

### Frontend Components
1. **EnhancedTicketScreen** (`lib/screens/enhanced_ticket_screen.dart`)
   - Real-time ticket display
   - QR code rendering
   - Live countdown timer
   - Bus status monitoring

2. **DemoTestScreen** (`lib/screens/demo_test_screen.dart`)
   - Cross-platform communication testing
   - Fraud detection simulation
   - Real-time status monitoring

## 🎮 Demo Instructions

### Step 1: Setup
1. Open the Smart Ticket MTC app
2. Ensure location permissions are granted
3. Navigate to "Demo Test" from the home screen

### Step 2: Start Demo Session
1. Click "Start Demo Session"
2. This creates a unique session ID
3. Session data is stored in Firebase Realtime Database
4. Location tracking begins automatically

### Step 3: Simulate Cross-Platform Communication
- **Database URL**: `https://gyre-compare-default-rtdb.firebaseio.com/`
- **Session Format**: `passenger_sessions/{sessionId}`
- **Data Includes**: Location, accelerometer, gyroscope, timestamp

### Step 4: Test Fraud Detection
1. Click "Simulate Fraud Detection"
2. System analyzes:
   - Planned exit: Stop 6
   - Actual exit: Stop 12
   - Extra stops: 6
   - Penalty: ₹30 (6 × ₹5)

### Step 5: Monitor Real-time Status
- **Data Streaming**: Shows active/inactive status
- **Bus Status**: In Bus / Walking detection
- **Test Results**: Fraud analysis output

## 🌐 Firebase Architecture

### Main Firebase Database (Your Project)
- **Purpose**: Stores ALL ticket data, user information, detailed trip data
- **Configuration**: Uses your `google-services.json`
- **Collections**: 
  - `enhanced_tickets/` - Complete ticket information
  - `passenger_sessions/{sessionId}-location` - Detailed GPS tracking
  - `passenger_sessions/{sessionId}-sensors` - Full sensor data
  - `passenger_sessions/{sessionId}-fraud` - Fraud analysis results

### Gyro Firebase Database (`https://gyre-compare-default-rtdb.firebaseio.com/`)
- **Purpose**: Cross-platform communication ONLY
- **Data Stored**: Minimal session information for real-time sync
- **Structure**:
```json
{
  "passenger_sessions": {
    "{sessionId}": {
      "sessionId": "string",
      "ticketId": "string", 
      "userId": "string",
      "startTime": "timestamp",
      "status": "active",
      "userInBus": boolean,
      "lastUpdate": "timestamp",
      "plannedExit": "string",
      "fraudAnalysis": {
        "actualExit": "string",
        "extraStops": number,
        "penaltyAmount": number,
        "isFraud": boolean
      }
    }
  }
}
```

### Data Flow
1. **Ticket Creation**: Full data → Main Firebase, Session ID → Gyro Firebase
2. **Real-time Updates**: Minimal status → Gyro Firebase, Detailed data → Main Firebase  
3. **Cross-platform Sync**: Gyro app monitors session IDs and bus status
4. **Fraud Detection**: Analysis results → Both databases (detailed in main, summary in gyro)

## 🚌 Cross-Platform Integration

### Gyro Comparator App (Bus Side)
The demo assumes a companion "Gyro Comparator" app that:
1. Acts as the bus monitoring system
2. Connects to the same Firebase Realtime Database
3. Monitors passenger sensor data
4. Updates bus status and location

### Data Synchronization
- **Real-time Updates**: Both apps receive live data updates
- **Session Sharing**: Common session IDs for data correlation
- **Fraud Detection**: Coordinated analysis between apps

## 📱 User Journey

### Enhanced Ticket Booking
1. **Book Ticket**: Select source/destination, pay fare
2. **Location Consent**: Grant location permissions
3. **Ticket Display**: See QR code, countdown timer, ticket details
4. **Location Monitoring**: GPS tracking for 2 hours
5. **Trip Completion**: Automatic fraud analysis

### Settings & Features
- **Enhanced Features**: View fraud detection status
- **Cross-Platform Sync**: Monitor connection status
- **Penalty Information**: Understand penalty system
- **Location Settings**: Manage GPS permissions

## 🛡️ Security Features

### Data Protection
- **Encrypted Storage**: Local data encryption
- **Secure Communication**: HTTPS/WSS protocols
- **Session Management**: Secure session handling
- **Privacy Controls**: User consent for location tracking

### Fraud Prevention
- **Motion Analysis**: Detect bus vs. walking patterns
- **Location Verification**: GPS-based stop detection
- **Time Validation**: 2-hour ticket lifecycle
- **Cross-validation**: Multi-device verification

## 🔄 Development Status

### ✅ Completed Features
- Enhanced ticket system with 2-hour validation
- Cross-platform service infrastructure
- Firebase Realtime Database integration
- Fraud detection algorithms
- Demo testing interface
- QR code generation
- Location tracking integration

### 🚧 Next Steps
- Real gyro comparator app development
- Advanced fraud detection algorithms
- Machine learning integration
- Performance optimizations
- Additional security features

## 📞 Support

For technical issues or questions about the demo:
1. Check the "Support" section in the app
2. Review console logs for error messages
3. Verify Firebase connectivity
4. Ensure location permissions are granted

---

**Note**: This is a demonstration system. In production, additional security measures and optimizations would be implemented for real-world deployment.
