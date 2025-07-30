## 🚀 **Enhanced Fraud Detection System - Demo Instructions**

Your Smart Ticket MTC app now includes an advanced fraud detection system that prevents fare evasion using gyroscope and accelerometer data comparison.

### 🎯 **How It Works**

1. **Ticket Booking with Fraud Detection**
   - Book a ticket from any stop to another (e.g., Stop 1 to Stop 6)
   - System generates a unique session ID
   - Session data is sent to Gyro-Comparator Firebase: `https://gyre-compare-default-rtdb.firebaseio.com`

2. **Real-Time Monitoring**
   - Your phone's gyroscope and accelerometer are monitored
   - GPS location is tracked every 10 seconds
   - Data is compared with bus sensor patterns
   - Cross-platform sync ensures passenger is actually in the bus

3. **Fraud Detection Demo**
   - Demo simulates a passenger booking ticket to Stop 6
   - But actually traveling to Stop 12 (6 extra stops)
   - System detects the violation automatically
   - Penalty calculated: 6 × ₹5 = ₹30

### 🛠️ **Demo Features**

- ✅ **Real-time sensor data display**
- ✅ **Cross-platform Firebase synchronization**
- ✅ **Journey progress tracking**
- ✅ **Automatic fraud detection**
- ✅ **Penalty calculation**
- ✅ **Bus vs walking detection**

### 📱 **Using the Demo**

1. Go to **Book Bus Ticket**
2. Select **From** and **To** stops
3. Accept **Fraud Detection Consent**
4. Watch the **Fraud Demo Screen** show:
   - Real-time sensor data
   - Journey progress
   - Cross-platform sync status
   - Fraud detection results

### 🔗 **Cross-Platform Integration**

- **Your App**: Smart Ticket MTC (passenger device)
- **Bus App**: Gyro-Comparator (bus device)  
- **Shared Database**: Firebase Realtime Database
- **Communication**: Unique session IDs and minimal data sharing

### ⚠️ **Fraud Detection Logic**

```
IF (actual_exit_stop > planned_exit_stop) {
    extra_stops = actual_exit_stop - planned_exit_stop
    penalty = extra_stops × ₹5
    fraud_detected = true
}
```

### 🎬 **Demo Scenarios**

1. **Legitimate Journey**: Stop 1 → Stop 6 (No penalty)
2. **Fraud Scenario**: Stop 1 → Stop 6 ticket, but travel to Stop 12 (₹30 penalty)
3. **Real-time Detection**: System shows progression through each stop

This demonstrates how modern public transport can prevent fare evasion using smartphone sensors and cross-platform communication.
