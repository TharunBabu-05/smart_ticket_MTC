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
  // Gyro Firebase (minimal data only)
  static FirebaseDatabase? _gyroDatabase;
  static const String _gyroComparatorUrl = 'https://gyre-compare-default-rtdb.firebaseio.com/';
  
  // Main Firebase (all ticket/user data)
  static final FirebaseFirestore _mainFirestore = FirebaseFirestore.instance;
  
  static const String _sessionStatusCollection = 'passenger_sessions'; // Gyro DB
  static const String _ticketDataCollection = 'enhanced_tickets'; // Main DB
  
  static StreamSubscription<LocationData>? _locationSubscription;
  static StreamSubscription<AccelerometerEvent>? _accelSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  static String? _currentSessionId;
  static bool _isStreaming = false;

  /// Initialize the cross-platform service with gyro comparator database
  static Future<void> initialize() async {
    try {
      // Initialize connection to gyro Firebase (minimal data only)
      _gyroDatabase = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _gyroComparatorUrl,
      );
      print('Cross-platform service initialized successfully');
      print('Gyro DB URL: $_gyroComparatorUrl');
    } catch (e) {
      print('Error initializing cross-platform service: $e');
      throw e;
    }
  }

  /// Create session ID in gyro database (minimal data only)
  static Future<String> createTripSession(TripData tripData) async {
    try {
      if (_gyroDatabase == null) {
        throw Exception('Cross-platform service not initialized');
      }

      String sessionId = _generateSessionId();
      _currentSessionId = sessionId;
      
      // Store MINIMAL data in gyro database (for cross-platform communication)
      Map<String, dynamic> gyroSessionData = {
        'sessionId': sessionId,
        'ticketId': tripData.ticketId,
        'userId': tripData.userId,
        'startTime': tripData.startTime.millisecondsSinceEpoch,
        'status': 'active',
        'userInBus': false,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        'plannedExit': tripData.destinationName,
      };

      // Store in gyro Firebase (minimal data)
      await _gyroDatabase!
          .ref(_sessionStatusCollection)
          .child(sessionId)
          .set(gyroSessionData);

      // Store FULL ticket data in main Firebase
      await _mainFirestore
          .collection(_ticketDataCollection)
          .doc(tripData.ticketId)
          .set({
        'sessionId': sessionId,
        'tripData': tripData.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'fraudStatus': 'monitoring',
      });

      print('Session created - ID: $sessionId');
      print('Minimal data stored in gyro DB');
      print('Full data stored in main DB');

      return sessionId;
    } catch (e) {
      print('Error creating trip session: $e');
      throw e;
    }
  }

  /// Start streaming minimal updates to gyro database
  static Future<void> startDataStreaming(String sessionId) async {
    try {
      if (_gyroDatabase == null) {
        throw Exception('Cross-platform service not initialized');
      }

      _currentSessionId = sessionId;
      _isStreaming = true;

      // Start minimal location updates to gyro DB
      await _startLocationStreaming(sessionId);
      
      // Start basic sensor monitoring
      await _startSensorStreaming(sessionId);

      print('Minimal data streaming started for session: $sessionId');
    } catch (e) {
      print('Error starting data streaming: $e');
      throw e;
    }
  }

  /// Start location streaming (minimal updates to gyro DB)
  static Future<void> _startLocationStreaming(String sessionId) async {
    Location location = Location();
    
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Location permission denied');
      }
    }

    _locationSubscription = location.onLocationChanged.listen((LocationData locationData) {
      if (_isStreaming && _currentSessionId == sessionId) {
        _streamLocationData(sessionId, locationData);
      }
    });
  }

  /// Start sensor streaming (minimal data to gyro DB)
  static Future<void> _startSensorStreaming(String sessionId) async {
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (_isStreaming && _currentSessionId == sessionId) {
        _updateUserBusStatus(sessionId, event);
      }
    });

    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (_isStreaming && _currentSessionId == sessionId) {
        // Use gyro data to detect bus movement patterns
        _analyzeBusMovement(sessionId, event);
      }
    });
  }

  /// Stream minimal location data to gyro database
  static void _streamLocationData(String sessionId, LocationData locationData) async {
    try {
      // Only send essential location info to gyro DB
      Map<String, dynamic> minimalLocationUpdate = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'speed': locationData.speed ?? 0,
        'isMoving': (locationData.speed ?? 0) > 5, // Moving faster than 5 km/h
      };

      await _gyroDatabase!
          .ref(_sessionStatusCollection)
          .child(sessionId)
          .update(minimalLocationUpdate);

      // Store detailed location in main Firebase
      await _mainFirestore
          .collection(_ticketDataCollection)
          .doc('$sessionId-location')
          .set({
        'sessionId': sessionId,
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'accuracy': locationData.accuracy,
        'speed': locationData.speed,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      print('Error streaming location data: $e');
    }
  }

  /// Update user bus status based on sensor patterns
  static void _updateUserBusStatus(String sessionId, AccelerometerEvent event) async {
    try {
      // Simple bus detection based on accelerometer patterns
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      bool inBus = magnitude > 8 && magnitude < 12; // Typical bus vibration range

      await _gyroDatabase!
          .ref(_sessionStatusCollection)
          .child(sessionId)
          .update({
        'userInBus': inBus,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating bus status: $e');
    }
  }

  /// Analyze bus movement patterns
  static void _analyzeBusMovement(String sessionId, GyroscopeEvent event) async {
    try {
      // Store gyro data pattern for fraud analysis (in main DB)
      await _mainFirestore
          .collection(_ticketDataCollection)
          .doc('$sessionId-sensors')
          .set({
        'sessionId': sessionId,
        'gyroData': {
          'x': event.x,
          'y': event.y,
          'z': event.z,
          'timestamp': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error analyzing bus movement: $e');
    }
  }

  /// Get real-time bus status for UI updates
  static Stream<bool> getUserInBusStatus(String sessionId) {
    if (_gyroDatabase == null) {
      throw Exception('Cross-platform service not initialized');
    }

    return _gyroDatabase!
        .ref(_sessionStatusCollection)
        .child(sessionId)
        .child('userInBus')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false);
  }

  /// Analyze fraud when trip ends
  static Future<Map<String, dynamic>> analyzeFraudAtExit(
    String sessionId,
    String actualExit,
    String plannedExit,
  ) async {
    try {
      // Calculate fraud analysis
      Map<String, dynamic> fraudResult = {
        'sessionId': sessionId,
        'plannedExit': plannedExit,
        'actualExit': actualExit,
        'isFraud': false,
        'extraStops': 0,
        'penaltyAmount': 0.0,
        'analysisTime': DateTime.now().millisecondsSinceEpoch,
      };

      // Simple fraud detection logic
      List<String> stops = ['Stop 1', 'Stop 2', 'Stop 3', 'Stop 4', 'Stop 5', 'Stop 6', 'Stop 7', 'Stop 8', 'Stop 9', 'Stop 10', 'Stop 11', 'Stop 12'];
      int plannedIndex = stops.indexOf(plannedExit);
      int actualIndex = stops.indexOf(actualExit);

      if (actualIndex > plannedIndex) {
        int extraStops = actualIndex - plannedIndex;
        double penalty = extraStops * 5.0; // ₹5 per extra stop

        fraudResult['isFraud'] = true;
        fraudResult['extraStops'] = extraStops;
        fraudResult['penaltyAmount'] = penalty;
      }

      // Update gyro database with fraud result
      await _gyroDatabase!
          .ref(_sessionStatusCollection)
          .child(sessionId)
          .update({
        'fraudAnalysis': fraudResult,
        'status': 'completed',
      });

      // Store detailed analysis in main database
      await _mainFirestore
          .collection(_ticketDataCollection)
          .doc('$sessionId-fraud')
          .set({
        'fraudAnalysis': fraudResult,
        'detailedAnalysis': {
          'completedAt': FieldValue.serverTimestamp(),
          'sessionDuration': 'calculated_duration',
          'fraudConfidence': fraudResult['isFraud'] ? 0.95 : 0.05,
        }
      });

      return fraudResult;
    } catch (e) {
      print('Error analyzing fraud: $e');
      return {
        'error': e.toString(),
        'isFraud': false,
        'extraStops': 0,
        'penaltyAmount': 0.0,
      };
    }
  }

  /// Stop data streaming and cleanup
  static Future<void> stopDataStreaming() async {
    try {
      _isStreaming = false;
      
      await _locationSubscription?.cancel();
      await _accelSubscription?.cancel();
      await _gyroSubscription?.cancel();
      
      _currentSessionId = null;
      
      print('Data streaming stopped');
    } catch (e) {
      print('Error stopping data streaming: $e');
    }
  }

  /// Generate unique session ID
  static String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Get user device ID (simplified)
  static Future<String> _getUserDeviceId() async {
    // In production, use device_info_plus package
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if trip is still valid (within 2 hours)
  static bool isTicketValid(DateTime startTime) {
    Duration elapsed = DateTime.now().difference(startTime);
    return elapsed.inHours < 2;
  }

  /// Get remaining ticket time
  static Duration getRemainingTicketTime(DateTime startTime) {
    Duration elapsed = DateTime.now().difference(startTime);
    Duration twoHours = Duration(hours: 2);
    Duration remaining = twoHours - elapsed;
    
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  /// Extract stop number from stop name
  static int _extractStopNumber(String stopName) {
    // Extract number from stop name like "Stop 6" or "6th Stop"
    RegExp regex = RegExp(r'\d+');
    Match? match = regex.firstMatch(stopName);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 0;
  }

  /// Get current streaming status
  static bool get isStreaming => _isStreaming;
  
  /// Get current session ID
  static String? getCurrentSessionId() => _currentSessionId;
}
