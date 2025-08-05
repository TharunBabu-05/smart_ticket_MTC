import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'dart:async';

/// Service for sharing and tracking live locations (Bus Demo)
class LiveLocationService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static Location _location = Location();
  
  // Current sharing state
  static bool _isSharingLocation = false;
  static StreamSubscription<LocationData>? _locationSubscription;
  static String? _currentSessionId;
  static String? _currentRole; // 'bus' or 'passenger'
  
  /// Start sharing location as a bus (for demo)
  static Future<String> startSharingAsBus({
    required String busRoute,
    required String busNumber,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Check location permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) throw Exception('Location service disabled');
      }
      
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission denied');
        }
      }
      
      // Generate session ID
      _currentSessionId = 'bus_${DateTime.now().millisecondsSinceEpoch}';
      _currentRole = 'bus';
      
      // Create bus session in Firebase
      await _database.ref('live_buses/$_currentSessionId').set({
        'busNumber': busNumber,
        'route': busRoute,
        'driverId': user.uid,
        'status': 'active',
        'passengerCount': 0,
        'maxCapacity': 50,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Start location streaming
      await _startLocationStreaming();
      
      print('🚌 Started sharing location as Bus $busNumber on route $busRoute');
      return _currentSessionId!;
      
    } catch (e) {
      print('❌ Error starting bus location sharing: $e');
      throw e;
    }
  }
  
  /// Start sharing location as a passenger
  static Future<String> startSharingAsPassenger() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Check location permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) throw Exception('Location service disabled');
      }
      
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission denied');
        }
      }
      
      // Generate session ID
      _currentSessionId = 'passenger_${DateTime.now().millisecondsSinceEpoch}';
      _currentRole = 'passenger';
      
      // Create passenger session
      await _database.ref('live_passengers/$_currentSessionId').set({
        'userId': user.uid,
        'status': 'active',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Start location streaming
      await _startLocationStreaming();
      
      print('👤 Started sharing location as passenger');
      return _currentSessionId!;
      
    } catch (e) {
      print('❌ Error starting passenger location sharing: $e');
      throw e;
    }
  }
  
  /// Start location streaming
  static Future<void> _startLocationStreaming() async {
    if (_isSharingLocation) return;
    
    _isSharingLocation = true;
    
    // Configure location settings
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 2000, // Update every 2 seconds
      distanceFilter: 5, // Update when moved 5 meters
    );
    
    // Start listening to location changes
    _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
      _updateLocationInFirebase(locationData);
    });
    
    print('📍 Location streaming started');
  }
  
  /// Update location in Firebase
  static Future<void> _updateLocationInFirebase(LocationData locationData) async {
    if (_currentSessionId == null || !_isSharingLocation) return;
    
    try {
      Map<String, dynamic> locationUpdate = {
        'latitude': locationData.latitude ?? 0.0,
        'longitude': locationData.longitude ?? 0.0,
        'accuracy': locationData.accuracy ?? 0.0,
        'speed': locationData.speed ?? 0.0,
        'heading': locationData.heading ?? 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      };
      
      String path = _currentRole == 'bus' 
          ? 'live_buses/$_currentSessionId/location'
          : 'live_passengers/$_currentSessionId/location';
          
      await _database.ref(path).set(locationUpdate);
      
      // Also update the main record's lastUpdate
      String mainPath = _currentRole == 'bus' 
          ? 'live_buses/$_currentSessionId'
          : 'live_passengers/$_currentSessionId';
          
      await _database.ref(mainPath).update({
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      });
      
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }
  
  /// Update passenger count for bus
  static Future<void> updatePassengerCount(int count) async {
    if (_currentSessionId == null || _currentRole != 'bus') return;
    
    try {
      await _database.ref('live_buses/$_currentSessionId').update({
        'passengerCount': count,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('👥 Updated passenger count to $count');
    } catch (e) {
      print('❌ Error updating passenger count: $e');
    }
  }
  
  /// Stop location sharing
  static Future<void> stopLocationSharing() async {
    try {
      _isSharingLocation = false;
      
      // Cancel location subscription
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      
      // Update status in Firebase
      if (_currentSessionId != null && _currentRole != null) {
        String path = _currentRole == 'bus' 
            ? 'live_buses/$_currentSessionId'
            : 'live_passengers/$_currentSessionId';
            
        await _database.ref(path).update({
          'status': 'stopped',
          'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      // Clear session data
      _currentSessionId = null;
      _currentRole = null;
      
      print('🛑 Location sharing stopped');
      
    } catch (e) {
      print('❌ Error stopping location sharing: $e');
    }
  }
  
  /// Get all active buses
  static Stream<Map<String, dynamic>> getActiveBuses() {
    return _database
        .ref('live_buses')
        .orderByChild('status')
        .equalTo('active')
        .onValue
        .map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return <String, dynamic>{};
    });
  }
  
  /// Get all active passengers
  static Stream<Map<String, dynamic>> getActivePassengers() {
    return _database
        .ref('live_passengers')
        .orderByChild('status')
        .equalTo('active')
        .onValue
        .map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return <String, dynamic>{};
    });
  }
  
  /// Check if currently sharing location
  static bool get isSharingLocation => _isSharingLocation;
  
  /// Get current session info
  static Map<String, String?> getCurrentSession() {
    return {
      'sessionId': _currentSessionId,
      'role': _currentRole,
    };
  }
}
