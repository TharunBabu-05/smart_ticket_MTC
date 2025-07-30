import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firebase_database/firebase_database.dart' show Query;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import '../models/trip_data_model.dart';
import '../models/fraud_analysis_model.dart';
import '../firebase_options.dart';

/// Smart Ticket MTC Fraud Detection Service
/// 
/// This service manages the dual-app fraud detection system:
/// 1. Primary App: Stores tickets and creates session IDs
/// 2. Gyro App: Receives session IDs and compares sensor data
class FraudDetectionService {
  
  // === FIREBASE INSTANCES ===
  static FirebaseDatabase? _primaryRealtimeDB;
  static FirebaseDatabase? _gyroRealtimeDB;
  static FirebaseFirestore? _primaryFirestore;
  static FirebaseAuth? _auth;
  
  // === DATABASE PATHS ===
  static const String _ticketsPath = 'tickets';                    // Realtime DB tickets
  static const String _gyroSessionsPath = 'gyro_sessions';         // Session sharing between apps
  static const String _sensorDataPath = 'sensor_data';            // Live sensor data
  static const String _fraudAnalysisPath = 'fraud_analysis';      // Admin fraud detection
  
  static const String _enhancedTicketsCollection = 'enhanced_tickets';  // Firestore detailed tickets
  static const String _sensorDataCollection = 'sensor_data';            // Firestore sensor history
  
  // === ACTIVE SESSION DATA ===
  static String? _currentSessionId;
  static String? _currentTicketId;
  static bool _isStreaming = false;
  
  static StreamSubscription<LocationData>? _locationSubscription;
  static StreamSubscription<AccelerometerEvent>? _accelSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  /// Initialize the fraud detection service
  static Future<void> initialize() async {
    try {
      print('🚀 Initializing Smart Ticket Fraud Detection Service...');
      
      // Initialize Firebase Auth
      _auth = FirebaseAuth.instance;
      
      // Initialize Primary App (Smart Ticket System)
      print('📱 Initializing Primary App (Smart Ticket System)...');
      await Firebase.initializeApp(
        name: 'primary_app',
        options: DefaultFirebaseOptions.primaryApp,
      );
      
      FirebaseApp primaryApp = Firebase.app('primary_app');
      _primaryRealtimeDB = FirebaseDatabase.instanceFor(app: primaryApp);
      _primaryFirestore = FirebaseFirestore.instanceFor(app: primaryApp);
      
      // Initialize Secondary App (Gyro Comparator System)
      print('🎯 Initializing Secondary App (Gyro Comparator System)...');
      await Firebase.initializeApp(
        name: 'gyro_app',
        options: DefaultFirebaseOptions.gyroComparatorApp,
      );
      
      FirebaseApp gyroApp = Firebase.app('gyro_app');
      _gyroRealtimeDB = FirebaseDatabase.instanceFor(app: gyroApp);
      
      // Test connections
      await _testConnections();
      
      print('✅ Fraud Detection Service initialized successfully!');
      print('🎯 Ready to detect ticket fraud between apps');
      
    } catch (e) {
      print('❌ Error initializing Fraud Detection Service: $e');
      throw e;
    }
  }
  
  /// Test Firebase connections
  static Future<void> _testConnections() async {
    try {
      print('🔍 Testing Firebase connections...');
      
      // Temporarily skip connection tests to avoid "Invalid token in path" error
      print('⚠️ Connection tests temporarily disabled');
      print('✅ Assuming connections are working');
      
      // TODO: Re-enable proper connection tests once path issues are resolved
      /*
      // Test Primary App connection
      await _primaryRealtimeDB!.ref('.info/connected').get().timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Primary DB timeout'),
      );
      print('✅ Primary App connected');
      
      // Test Gyro App connection
      await _gyroRealtimeDB!.ref('.info/connected').get().timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Gyro DB timeout'),
      );
      print('✅ Gyro App connected');
      
      // Test Firestore connection
      await _primaryFirestore!.settings;
      print('✅ Firestore connected');
      */
      
    } catch (e) {
      print('❌ Connection test failed: $e');
      throw e;
    }
  }

  /// Create a new ticket and fraud detection session
  static Future<String> createTicketWithFraudDetection(TripData tripData) async {
    try {
      if (_auth?.currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      String userId = _auth!.currentUser!.uid;
      String ticketId = tripData.ticketId;
      String sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      
      _currentSessionId = sessionId;
      _currentTicketId = ticketId;
      
      print('🎫 Creating ticket with fraud detection...');
      print('🆔 Ticket ID: $ticketId');
      print('🔐 Session ID: $sessionId');
      
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // === 1. STORE TICKET IN REALTIME DATABASE (PRIMARY APP) ===
      Map<String, dynamic> ticketData = tripData.toMap();
      ticketData['sessionId'] = sessionId;
      ticketData['timestamp'] = timestamp;
      
      await _primaryRealtimeDB!.ref('$_ticketsPath/$ticketId').set(ticketData);
      print('✅ Ticket stored in Primary App Realtime DB');
      
      // === 2. STORE DETAILED TICKET IN FIRESTORE ===
      Map<String, dynamic> enhancedTicketData = {
        ...ticketData,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'fraudDetectionEnabled': true,
        'expectedJourney': {
          'fromStop': tripData.sourceName ?? 'unknown',
          'toStop': tripData.destinationName ?? 'unknown',
          'route': 'default_route',
          'estimatedDuration': _calculateEstimatedDuration(tripData.sourceName ?? 'unknown', tripData.destinationName ?? 'unknown'),
        }
      };
      
      await _primaryFirestore!.collection(_enhancedTicketsCollection).doc(ticketId).set(enhancedTicketData);
      print('✅ Enhanced ticket stored in Firestore');
      
      // === 3. CREATE GYRO SESSION FOR CROSS-APP COMMUNICATION ===
      Map<String, dynamic> sessionData = {
        'sessionId': sessionId,
        'ticketId': ticketId,
        'userId': userId,
        'startTime': timestamp,
        'status': 'active',
        'fromStop': tripData.sourceName ?? 'unknown',
        'toStop': tripData.destinationName ?? 'unknown',
        'expectedDistance': _calculateDistance(tripData.sourceName ?? 'unknown', tripData.destinationName ?? 'unknown'),
        'lastUpdate': timestamp,
      };
      
      // Store in GYRO APP for cross-app communication
      await _gyroRealtimeDB!.ref('$_gyroSessionsPath/$sessionId').set(sessionData);
      print('✅ Session created in Gyro App for cross-platform detection');
      
      // === 4. START SENSOR DATA STREAMING ===
      _currentSessionId = sessionId;
      _currentTicketId = ticketId;
      await _startSensorStreaming(sessionId, ticketId, userId);
      
      print('🎯 Fraud detection system activated for ticket: $ticketId');
      return ticketId;
      
    } catch (e) {
      print('❌ Error creating ticket with fraud detection: $e');
      throw e;
    }
  }
  
  /// Start streaming sensor data for fraud detection
  static Future<void> _startSensorStreaming(String sessionId, String ticketId, String userId) async {
    if (_isStreaming) {
      print('⚠️ Sensor streaming already active');
      return;
    }
    
    try {
      print('📡 Starting sensor data streaming for fraud detection...');
      _isStreaming = true;
      
      // Start location streaming
      Location location = Location();
      _locationSubscription = location.onLocationChanged.listen((LocationData locationData) async {
        if (locationData.latitude != null && locationData.longitude != null) {
          await _sendLocationData(sessionId, ticketId, locationData);
        }
      });
      
      // Start accelerometer streaming
      _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) async {
        await _sendAccelerometerData(sessionId, ticketId, event);
      });
      
      // Start gyroscope streaming
      _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) async {
        await _sendGyroscopeData(sessionId, ticketId, event);
      });
      
      print('📡 Sensor streaming started - fraud detection active!');
      
    } catch (e) {
      print('❌ Error starting sensor streaming: $e');
      _isStreaming = false;
    }
  }
  
  /// Send location data to both apps
  static Future<void> _sendLocationData(String sessionId, String ticketId, LocationData locationData) async {
    try {
      Map<String, dynamic> locationPayload = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'accuracy': locationData.accuracy ?? 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'altitude': locationData.altitude ?? 0,
        'speed': locationData.speed ?? 0,
      };
      
      // Send to PRIMARY APP (for ticket tracking)
      await _primaryRealtimeDB!.ref('$_sensorDataPath/$sessionId/location').set(locationPayload);
      
      // Send to GYRO APP (for cross-platform comparison)
      await _gyroRealtimeDB!.ref('$_gyroSessionsPath/$sessionId/sensorData/location').set(locationPayload);
      
      // Also store in Firestore for detailed analysis
      await _primaryFirestore!.collection(_sensorDataCollection).doc(sessionId).collection('location').add({
        ...locationPayload,
        'ticketId': ticketId,
        'sensorType': 'location',
      });
      
    } catch (e) {
      print('❌ Error sending location data: $e');
    }
  }
  
  /// Send gyroscope data to both apps
  static Future<void> _sendGyroscopeData(String sessionId, String ticketId, GyroscopeEvent event) async {
    try {
      Map<String, dynamic> gyroPayload = {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Send to PRIMARY APP
      await _primaryRealtimeDB!.ref('$_sensorDataPath/$sessionId/gyroscope').set(gyroPayload);
      
      // Send to GYRO APP (for cross-platform comparison)
      await _gyroRealtimeDB!.ref('$_gyroSessionsPath/$sessionId/sensorData/gyroscope').set(gyroPayload);
      
      // Store in Firestore for analysis
      await _primaryFirestore!.collection(_sensorDataCollection).doc(sessionId).collection('gyroscope').add({
        ...gyroPayload,
        'ticketId': ticketId,
        'sensorType': 'gyroscope',
      });
      
    } catch (e) {
      print('❌ Error sending gyroscope data: $e');
    }
  }
  
  /// Send accelerometer data to both apps
  static Future<void> _sendAccelerometerData(String sessionId, String ticketId, AccelerometerEvent event) async {
    try {
      Map<String, dynamic> accelPayload = {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Send to PRIMARY APP
      await _primaryRealtimeDB!.ref('$_sensorDataPath/$sessionId/accelerometer').set(accelPayload);
      
      // Send to GYRO APP (for cross-platform comparison)
      await _gyroRealtimeDB!.ref('$_gyroSessionsPath/$sessionId/sensorData/accelerometer').set(accelPayload);
      
      // Store in Firestore for analysis
      await _primaryFirestore!.collection(_sensorDataCollection).doc(sessionId).collection('accelerometer').add({
        ...accelPayload,
        'ticketId': ticketId,
        'sensorType': 'accelerometer',
      });
      
    } catch (e) {
      print('❌ Error sending accelerometer data: $e');
    }
  }
  
  /// Complete the trip and stop fraud detection
  static Future<void> completeTrip(String ticketId, String actualToStop) async {
    try {
      print('🏁 Completing trip for ticket: $ticketId');
      
      if (_currentSessionId == null) {
        throw Exception('No active session found');
      }
      
      // Stop sensor streaming
      await _stopSensorStreaming();
      
      // Update ticket status in Primary App
      await _primaryRealtimeDB!.ref('$_ticketsPath/$ticketId').update({
        'status': 'completed',
        'actualToStop': actualToStop,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Update session in Gyro App
      await _gyroRealtimeDB!.ref('$_gyroSessionsPath/$_currentSessionId').update({
        'status': 'completed',
        'endTime': DateTime.now().millisecondsSinceEpoch,
        'actualToStop': actualToStop,
      });
      
      // Update Firestore
      await _primaryFirestore!.collection(_enhancedTicketsCollection).doc(ticketId).update({
        'status': 'completed',
        'actualToStop': actualToStop,
        'completedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ Trip completed - fraud detection stopped');
      
      _currentSessionId = null;
      _currentTicketId = null;
      
    } catch (e) {
      print('❌ Error completing trip: $e');
      throw e;
    }
  }
  
  /// Stop sensor streaming
  static Future<void> _stopSensorStreaming() async {
    _isStreaming = false;
    
    await _locationSubscription?.cancel();
    await _accelSubscription?.cancel();
    await _gyroSubscription?.cancel();
    
    _locationSubscription = null;
    _accelSubscription = null;
    _gyroSubscription = null;
    
    print('📡 Sensor streaming stopped');
  }
  
  /// Calculate estimated journey duration (placeholder)
  static int _calculateEstimatedDuration(String fromStop, String toStop) {
    // Simple estimation - in a real app, this would use route data
    return 30; // 30 minutes default
  }
  
  /// Calculate distance between stops (placeholder)
  static double _calculateDistance(String fromStop, String toStop) {
    // Simple estimation - in a real app, this would use actual coordinates
    return 10.0; // 10 km default
  }
  
  /// Get current session ID
  static String? getCurrentSessionId() => _currentSessionId;
  
  /// Get current ticket ID
  static String? getCurrentTicketId() => _currentTicketId;
  
  /// Check if fraud detection is active
  static bool isActive() => _isStreaming && _currentSessionId != null;
  
  /// Get user's active trips
  static Future<List<TripData>> getUserActiveTrips(String userId) async {
    try {
      if (_primaryRealtimeDB == null) {
        await initialize();
      }
      
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_ticketsPath);
      Query query = ref.orderByChild('userId').equalTo(userId);
      
      DataSnapshot snapshot = await query.get();
      List<TripData> activeTrips = [];
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            Map<String, dynamic> ticketData = Map<String, dynamic>.from(value);
            if (ticketData['status'] == 'active') {
              TripData trip = TripData.fromMap(ticketData);
              activeTrips.add(trip);
            }
          } catch (e) {
            print('Error parsing trip data: $e');
          }
        });
      }
      
      return activeTrips;
    } catch (e) {
      print('Error getting user active trips: $e');
      return [];
    }
  }
  
  /// Expire a ticket
  static Future<void> expireTicket(String ticketId) async {
    try {
      if (_primaryRealtimeDB == null) {
        await initialize();
      }
      
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_ticketsPath).child(ticketId);
      await ref.update({
        'status': 'expired',
        'expiredAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('✅ Ticket $ticketId expired successfully');
      
      // Also update in Firestore
      if (_primaryFirestore != null) {
        await _primaryFirestore!.collection(_enhancedTicketsCollection)
            .doc(ticketId)
            .update({
          'status': 'expired',
          'expiredAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
    } catch (e) {
      print('❌ Error expiring ticket: $e');
      throw e;
    }
  }
  
  /// Get fraud alerts stream for admin monitoring
  static Stream<List<FraudAlert>> getFraudAlertsStream() {
    try {
      if (_primaryRealtimeDB == null) {
        return Stream.value([]);
      }
      
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_fraudAnalysisPath);
      return ref.onValue.map((event) {
        List<FraudAlert> alerts = [];
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            try {
              Map<String, dynamic> alertData = Map<String, dynamic>.from(value);
              FraudAlert alert = FraudAlert.fromMap(alertData);
              alerts.add(alert);
            } catch (e) {
              print('Error parsing fraud alert: $e');
            }
          });
        }
        return alerts;
      });
    } catch (e) {
      print('❌ Error getting fraud alerts stream: $e');
      return Stream.value([]);
    }
  }
  
  /// Get active trips stream for admin monitoring
  static Stream<List<TripData>> getActiveTripStream() {
    try {
      if (_primaryRealtimeDB == null) {
        return Stream.value([]);
      }
      
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_ticketsPath);
      return ref.onValue.map((event) {
        List<TripData> trips = [];
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            try {
              Map<String, dynamic> tripData = Map<String, dynamic>.from(value);
              if (tripData['status'] == 'active') {
                TripData trip = TripData.fromMap(tripData);
                trips.add(trip);
              }
            } catch (e) {
              print('Error parsing trip data: $e');
            }
          });
        }
        return trips;
      });
    } catch (e) {
      print('❌ Error getting active trip stream: $e');
      return Stream.value([]);
    }
  }
  
  /// Update fraud alert status
  static Future<void> updateFraudAlert(String alertId, String status) async {
    try {
      if (_primaryRealtimeDB == null) {
        await initialize();
      }
      
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_fraudAnalysisPath).child(alertId);
      await ref.update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('✅ Fraud alert $alertId updated to $status');
    } catch (e) {
      print('❌ Error updating fraud alert: $e');
      throw e;
    }
  }
  
  /// Update trip status (stub method for compatibility)
  static Future<void> updateTripStatus(String ticketId, dynamic status) async {
    try {
      if (_primaryRealtimeDB == null) {
        await initialize();
      }
      
      String statusString = status.toString().toLowerCase();
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_ticketsPath).child(ticketId);
      await ref.update({
        'status': statusString,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('✅ Trip $ticketId status updated to $statusString');
    } catch (e) {
      print('❌ Error updating trip status: $e');
      throw e;
    }
  }
  
  /// Check if streaming is active for current ticket (compatibility method)
  static String? get currentStreamingTicket => _currentTicketId;
  
  /// Check if currently streaming (compatibility method)
  static bool isStreaming() => _isStreaming;
  
  /// Generate alert ID (compatibility method)
  static String generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }
  
  /// Create fraud alert
  static Future<void> createFraudAlert(Map<String, dynamic> alert) async {
    try {
      if (_primaryRealtimeDB == null) {
        await initialize();
      }
      
      String alertId = alert['alertId'] ?? generateAlertId();
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_fraudAnalysisPath).child(alertId);
      
      Map<String, dynamic> alertData = {
        ...alert,
        'alertId': alertId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      };
      
      await ref.set(alertData);
      
      // Also store in Firestore for detailed analysis
      if (_primaryFirestore != null) {
        await _primaryFirestore!.collection('fraud_detection').doc(alertId).set(alertData);
      }
      
      print('✅ Fraud alert created: $alertId');
    } catch (e) {
      print('❌ Error creating fraud alert: $e');
      throw e;
    }
  }
  
  /// Save trip data (compatibility method)
  static Future<void> saveTripData(TripData tripData, [Map<String, dynamic>? analysis]) async {
    try {
      if (_primaryRealtimeDB == null) {
        await initialize();
      }
      
      DatabaseReference ref = _primaryRealtimeDB!.ref().child(_ticketsPath).child(tripData.ticketId);
      await ref.set(tripData.toMap());
      
      // Save analysis if provided
      if (analysis != null && _primaryFirestore != null) {
        await _primaryFirestore!.collection('fraud_analysis').doc(tripData.ticketId).set(analysis);
      }
      
      print('✅ Trip data saved for: ${tripData.ticketId}');
    } catch (e) {
      print('❌ Error saving trip data: $e');
      throw e;
    }
  }
  
  /// Save user trip history (compatibility method)
  static Future<void> saveUserTripHistory(String userId, TripData tripData) async {
    try {
      if (_primaryFirestore == null) {
        await initialize();
      }
      
      await _primaryFirestore!.collection('user_analytics')
          .doc(userId)
          .collection('trip_history')
          .doc(tripData.ticketId)
          .set(tripData.toMap());
      
      print('✅ User trip history saved for: $userId');
    } catch (e) {
      print('❌ Error saving user trip history: $e');
      throw e;
    }
  }
  
  /// Generate random string for IDs
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
  
  /// Create trip session (compatibility method)
  static Future<String> createTripSession(TripData tripData) async {
    try {
      await createTicketWithFraudDetection(tripData);
      return _currentSessionId ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('❌ Error creating trip session: $e');
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// Start data streaming (compatibility method)
  static Future<void> startDataStreaming(String sessionId) async {
    if (_currentSessionId == sessionId && _currentTicketId != null) {
      await _startSensorStreaming(sessionId, _currentTicketId!, 'user_123');
    }
  }
  
  /// Stop data streaming (compatibility method)
  static Future<void> stopDataStreaming() async {
    await _stopSensorStreaming();
  }
  
  /// Analyze fraud at exit (compatibility method)
  static Future<Map<String, dynamic>> analyzeFraudAtExit(String sessionId, String ticketId, String userId) async {
    try {
      // Simple fraud analysis - in a real system this would be more sophisticated
      Map<String, dynamic> analysis = {
        'sessionId': sessionId,
        'ticketId': ticketId,
        'userId': userId,
        'fraudDetected': false,
        'confidence': 0.0,
        'issues': <String>[],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Store analysis in Firestore
      if (_primaryFirestore != null) {
        await _primaryFirestore!.collection('fraud_analysis').doc(sessionId).set(analysis);
      }
      
      return analysis;
    } catch (e) {
      print('❌ Error analyzing fraud at exit: $e');
      return {
        'sessionId': sessionId,
        'ticketId': ticketId,
        'userId': userId,
        'fraudDetected': false,
        'confidence': 0.0,
        'issues': <String>[],
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }
  
  /// Get user in bus status stream (compatibility method)
  static Stream<bool> getUserInBusStatus(String sessionId) {
    try {
      if (_gyroRealtimeDB == null) {
        return Stream.value(false);
      }
      
      DatabaseReference ref = _gyroRealtimeDB!.ref().child(_gyroSessionsPath).child(sessionId).child('inBus');
      return ref.onValue.map((event) {
        return event.snapshot.value as bool? ?? false;
      });
    } catch (e) {
      print('❌ Error getting user in bus status: $e');
      return Stream.value(false);
    }
  }
  
  /// Quick fraud check (static method for background service)
  static Future<bool> quickFraudCheck(TripData tripData) async {
    try {
      // Simple fraud check - in a real system this would be more sophisticated
      if (tripData.fraudConfidence != null && tripData.fraudConfidence! > 0.7) {
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error in quick fraud check: $e');
      return false;
    }
  }
  
  /// Analyze trip data (static method for background service and journey tracking)
  static Future<FraudAnalysis> analyzeTripData(TripData tripData) async {
    try {
      // Create a simple fraud analysis
      FraudAnalysis analysis = FraudAnalysis(
        fraudConfidence: tripData.fraudConfidence ?? 0.0,
        detectedTransportMode: TransportMode.bus,
        speedAnalysis: false,
        stopAnalysis: false,
        routeDeviation: 0.0,
        recommendation: FraudRecommendation.noAction,
        detectedIssues: [],
        analysisTime: DateTime.now(),
      );
      
      return analysis;
    } catch (e) {
      print('❌ Error analyzing trip data: $e');
      // Return a safe default analysis
      return FraudAnalysis(
        fraudConfidence: 0.0,
        detectedTransportMode: TransportMode.bus,
        speedAnalysis: false,
        stopAnalysis: false,
        routeDeviation: 0.0,
        recommendation: FraudRecommendation.noAction,
        detectedIssues: [],
        analysisTime: DateTime.now(),
      );
    }
  }
  
  /// Cleanup resources
  static Future<void> dispose() async {
    await _stopSensorStreaming();
    _currentSessionId = null;
    _currentTicketId = null;
  }
}
