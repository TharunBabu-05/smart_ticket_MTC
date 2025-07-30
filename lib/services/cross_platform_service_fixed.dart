import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For main database
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';
import '../models/trip_data_model.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';

class CrossPlatformService {
  // Use primary Firebase with dedicated paths for different data types
  static FirebaseDatabase? _realtimeDatabase;
  static final FirebaseFirestore _mainFirestore = FirebaseFirestore.instance;
  
  // Updated to use primary Firebase project with dedicated paths
  static const String _gyroSessionsPath = 'gyro_sessions'; // Minimal session data for cross-platform
  static const String _ticketDataCollection = 'enhanced_tickets'; // Full ticket data
  static const String _fraudDataPath = 'fraud_detection'; // Fraud analysis data
  
  static StreamSubscription<LocationData>? _locationSubscription;
  static StreamSubscription<AccelerometerEvent>? _accelSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  static String? _currentSessionId;
  static bool _isStreaming = false;

  /// Initialize the cross-platform service with primary Firebase
  static Future<void> initialize() async {
    try {
      print('🔧 Initializing cross-platform service...');
      print('📡 Using primary Firebase project for all data');
      
      // Use primary Firebase app for both main data and gyro sessions
      _realtimeDatabase = FirebaseDatabase.instanceFor(
        app: Firebase.app(), // Primary Firebase app
      );
      
      // Test connection with timeout
      print('🔍 Testing connection to Realtime Database...');
      await _realtimeDatabase!.ref('.info/connected').get().timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Firebase connection timeout', Duration(seconds: 10)),
      );
      
      print('✅ Cross-platform service initialized successfully');
      print('🗄️ Using primary Firebase for all data storage');
      print('📱 Gyro sessions path: $_gyroSessionsPath');
      print('🎫 Ticket data collection: $_ticketDataCollection');
    } catch (e) {
      print('❌ Error initializing cross-platform service: $e');
      throw e;
    }
  }

  /// Create session ID in primary Firebase (minimal data for gyro comparison)
  static Future<String> createTripSession(TripData tripData) async {
    try {
      print('🎫 =========================');
      print('🎫 CREATING TRIP SESSION');
      print('🎫 =========================');
      
      if (_realtimeDatabase == null) {
        print('❌ Realtime database is null - initializing...');
        await initialize();
      }

      String sessionId = _generateSessionId();
      _currentSessionId = sessionId;
      
      print('🆔 Generated Session ID: $sessionId');
      print('🎫 Ticket ID: ${tripData.ticketId}');
      print('👤 User ID: ${tripData.userId}');
      
      // Store MINIMAL data for gyro comparison (only unique ID and essential info)
      Map<String, dynamic> gyroSessionData = {
        'sessionId': sessionId,
        'ticketId': tripData.ticketId,
        'userId': tripData.userId,
        'startTime': tripData.startTime.millisecondsSinceEpoch,
        'status': 'active',
        'userInBus': false,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        'plannedExit': tripData.destinationName,
        'createdForGyroComparison': true,
      };

      // Store minimal data in Realtime Database for gyro comparison
      print('💾 Storing minimal session data for gyro comparison...');
      print('📍 Full Path: $_gyroSessionsPath/$sessionId');
      print('📊 Data to store: ${gyroSessionData.toString()}');
      
      try {
        // Test if we can write to the database
        print('🔍 Testing database write permissions...');
        await _realtimeDatabase!.ref('_test').set({'timestamp': DateTime.now().millisecondsSinceEpoch});
        print('✅ Database write test successful');
        
        // Now try to write the actual session data
        print('💾 Writing session data to: $_gyroSessionsPath/$sessionId');
        await _realtimeDatabase!
            .ref(_gyroSessionsPath)
            .child(sessionId)
            .set(gyroSessionData)
            .timeout(
              Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Realtime database write timeout', Duration(seconds: 15)),
            );
        
        print('✅ Session data written to Realtime Database');
        print('🔗 Verify at: https://console.firebase.google.com/project/smart-ticket-mtc/database/smart-ticket-mtc-default-rtdb/data/gyro_sessions/$sessionId');
        
        // Verify the write was successful by reading back
        print('🔍 Verifying write by reading back...');
        DatabaseReference sessionRef = _realtimeDatabase!.ref(_gyroSessionsPath).child(sessionId);
        DataSnapshot snapshot = await sessionRef.get();
        
        if (snapshot.exists) {
          print('✅ Verification successful - data exists in database');
          print('📄 Stored data: ${snapshot.value}');
        } else {
          print('❌ Verification failed - data not found in database');
          throw Exception('Session data was not stored successfully');
        }
        
      } catch (dbError) {
        print('❌ Database write error: $dbError');
        print('🔧 Database reference: ${_realtimeDatabase.toString()}');
        print('📍 Path attempted: $_gyroSessionsPath/$sessionId');
        throw Exception('Failed to store session in Realtime Database: $dbError');
      }

      // Store FULL ticket data in Firestore
      print('💾 Storing full ticket data in Firestore...');
      try {
        await _mainFirestore
            .collection(_ticketDataCollection)
            .doc(tripData.ticketId)
            .set({
          'sessionId': sessionId,
          'tripData': tripData.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'fraudStatus': 'monitoring',
          'gyroSessionPath': '$_gyroSessionsPath/$sessionId',
        }).timeout(
          Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Firestore write timeout', Duration(seconds: 10)),
        );
        
        print('✅ Full ticket data stored in Firestore');
      } catch (firestoreError) {
        print('❌ Firestore write error: $firestoreError');
        // Don't throw here - Realtime DB write was successful
      }

      print('✅ SESSION CREATION COMPLETED');
      print('🆔 Session ID: $sessionId');
      print('📱 Minimal data in Realtime DB: $_gyroSessionsPath/$sessionId');
      print('🗄️ Full data in Firestore: $_ticketDataCollection/${tripData.ticketId}');
      print('🎫 =========================');

      return sessionId;
    } catch (e) {
      print('❌ =========================');
      print('❌ SESSION CREATION FAILED');
      print('❌ Error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      print('❌ =========================');
      throw e;
    }
  }

  /// Start streaming minimal updates to realtime database
  static Future<void> startDataStreaming(String sessionId) async {
    try {
      if (_realtimeDatabase == null) {
        throw Exception('Cross-platform service not initialized');
      }

      _currentSessionId = sessionId;
      _isStreaming = true;

      // Start minimal location updates to realtime DB
      await _startLocationStreaming(sessionId);
      
      // Start basic sensor monitoring
      await _startSensorStreaming(sessionId);

      print('Minimal data streaming started for session: $sessionId');
    } catch (e) {
      print('Error starting data streaming: $e');
      throw e;
    }
  }

  /// Start location streaming (minimal updates to realtime DB)
  static Future<void> _startLocationStreaming(String sessionId) async {
    try {
      LocationService locationService = LocationService();
      Location location = Location();

      _locationSubscription = location.onLocationChanged.listen((LocationData locationData) async {
        if (_realtimeDatabase != null && _isStreaming) {
          // Update only essential location data
          await _realtimeDatabase!
              .ref(_gyroSessionsPath)
              .child(sessionId)
              .child('currentLocation')
              .set({
            'latitude': locationData.latitude,
            'longitude': locationData.longitude,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });

      print('Location streaming started for session: $sessionId');
    } catch (e) {
      print('Error starting location streaming: $e');
    }
  }

  /// Start sensor streaming (minimal updates to realtime DB)
  static Future<void> _startSensorStreaming(String sessionId) async {
    try {
      // Listen to accelerometer
      _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) async {
        if (_realtimeDatabase != null && _isStreaming) {
          // Update only recent sensor data (last 5 readings)
          await _realtimeDatabase!
              .ref(_gyroSessionsPath)
              .child(sessionId)
              .child('recentSensors')
              .child('accelerometer')
              .set({
            'x': event.x,
            'y': event.y,
            'z': event.z,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });

      // Listen to gyroscope
      _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) async {
        if (_realtimeDatabase != null && _isStreaming) {
          await _realtimeDatabase!
              .ref(_gyroSessionsPath)
              .child(sessionId)
              .child('recentSensors')
              .child('gyroscope')
              .set({
            'x': event.x,
            'y': event.y,
            'z': event.z,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });

      print('Sensor streaming started for session: $sessionId');
    } catch (e) {
      print('Error starting sensor streaming: $e');
    }
  }

  /// Get current session data
  static Future<Map<String, dynamic>?> getCurrentSessionData() async {
    if (_realtimeDatabase == null || _currentSessionId == null) {
      return null;
    }

    try {
      DatabaseReference sessionRef = _realtimeDatabase!
          .ref(_gyroSessionsPath)
          .child(_currentSessionId!);
      
      DataSnapshot snapshot = await sessionRef.get();
      
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      
      return null;
    } catch (e) {
      print('Error getting current session data: $e');
      return null;
    }
  }

  /// Update session status
  static Future<void> updateSessionStatus(String status, {Map<String, dynamic>? additionalData}) async {
    if (_realtimeDatabase == null || _currentSessionId == null) {
      print('Cannot update session status: service not initialized or no active session');
      return;
    }

    try {
      Map<String, dynamic> updates = {
        'status': status,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      };

      if (additionalData != null) {
        updates.addAll(additionalData);
      }

      await _realtimeDatabase!
          .ref(_gyroSessionsPath)
          .child(_currentSessionId!)
          .update(updates);

      print('Session status updated: $status');
    } catch (e) {
      print('Error updating session status: $e');
    }
  }

  /// Stop all streaming and cleanup
  static Future<void> stopDataStreaming() async {
    try {
      _isStreaming = false;

      // Cancel all subscriptions
      await _locationSubscription?.cancel();
      await _accelSubscription?.cancel();
      await _gyroSubscription?.cancel();

      // Update session status
      if (_realtimeDatabase != null && _currentSessionId != null) {
        await _realtimeDatabase!
            .ref(_gyroSessionsPath)
            .child(_currentSessionId!)
            .update({
          'status': 'completed',
          'endTime': DateTime.now().millisecondsSinceEpoch,
          'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        });
      }

      print('Data streaming stopped and session completed');
    } catch (e) {
      print('Error stopping data streaming: $e');
    }
  }

  /// Generate unique session ID
  static String _generateSessionId() {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String randomComponent = (Random().nextInt(9999) + 1000).toString();
    return 'sess_${timestamp}_$randomComponent';
  }

  /// Get session ID
  static String? getCurrentSessionId() {
    return _currentSessionId;
  }

  /// Check if streaming is active
  static bool isStreaming() {
    return _isStreaming;
  }

  /// Get user in bus status stream
  static Stream<bool> getUserInBusStatus(String sessionId) {
    if (_realtimeDatabase == null) {
      return Stream.value(false);
    }

    return _realtimeDatabase!
        .ref(_gyroSessionsPath)
        .child(sessionId)
        .child('userInBus')
        .onValue
        .map((DatabaseEvent event) {
      if (event.snapshot.exists) {
        return event.snapshot.value as bool? ?? false;
      }
      return false;
    });
  }

  /// Analyze fraud at exit
  static Future<Map<String, dynamic>> analyzeFraudAtExit(
    String sessionId,
    String actualExitStop,
    String plannedExitStop,
  ) async {
    try {
      print('🔍 Analyzing fraud for session: $sessionId');
      print('📍 Planned exit: $plannedExitStop');
      print('📍 Actual exit: $actualExitStop');

      // Get session data
      Map<String, dynamic>? sessionData = await getCurrentSessionData();
      if (sessionData == null) {
        return {
          'fraudDetected': false,
          'reason': 'No session data available',
          'penalty': 0.0,
          'confidence': 0.0,
        };
      }

      // Simple fraud detection: compare planned vs actual exit
      bool fraudDetected = actualExitStop != plannedExitStop;
      double penalty = 0.0;
      double confidence = 0.0;

      if (fraudDetected) {
        // Calculate penalty based on extra stops (simplified)
        penalty = 5.0; // Base penalty
        confidence = 0.8; // High confidence for stop mismatch
        
        print('⚠️ Fraud detected: Stop mismatch');
        print('💰 Penalty: ₹$penalty');
      } else {
        print('✅ No fraud detected');
      }

      // Store fraud analysis result
      Map<String, dynamic> fraudResult = {
        'sessionId': sessionId,
        'plannedExit': plannedExitStop,
        'actualExit': actualExitStop,
        'fraudDetected': fraudDetected,
        'reason': fraudDetected ? 'Exit stop mismatch' : 'Normal journey',
        'penalty': penalty,
        'confidence': confidence,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Store in fraud detection path
      if (_realtimeDatabase != null) {
        await _realtimeDatabase!
            .ref(_fraudDataPath)
            .child(sessionId)
            .set(fraudResult);
      }

      return fraudResult;
    } catch (e) {
      print('❌ Error analyzing fraud: $e');
      return {
        'fraudDetected': false,
        'reason': 'Analysis error: $e',
        'penalty': 0.0,
        'confidence': 0.0,
      };
    }
  }
}
