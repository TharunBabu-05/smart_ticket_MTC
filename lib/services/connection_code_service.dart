import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:location/location.dart';
import 'permission_manager.dart';

/// Connection Code Service for Smart Ticket MTC
/// 
/// This service generates unique connection codes when tickets are booked
/// and shares sensor data that can be fetched by the gyro-comparator app
class ConnectionCodeService {
  static const String _sessionsPath = 'sessions';
  static const String _connectionCodesPath = 'connection_codes';
  
  static FirebaseDatabase? _database;
  static String? _currentConnectionCode;
  static String? _currentTicketId;
  static String _deviceId = 'device1'; // Smart ticket app is always device1
  
  static StreamSubscription<AccelerometerEvent>? _accelSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  static Timer? _gpsTimer;
  
  static List<double> _currentAccel = [0, 0, 0];
  static List<double> _currentGyro = [0, 0, 0];
  static double _currentSpeed = 0.0;
  static double _currentLatitude = 0.0;
  static double _currentLongitude = 0.0;
  
  static bool _isStreaming = false;

  /// Initialize the connection code service
  static Future<void> initialize() async {
    try {
      print('🔗 Initializing Connection Code Service...');
      
      // Use the same Firebase project as the gyro-comparator app
      _database = FirebaseDatabase.instance;
      
      print('✅ Connection Code Service initialized');
    } catch (e) {
      print('❌ Error initializing Connection Code Service: $e');
      throw e;
    }
  }

  /// Generate a unique 6-character connection code
  static String _generateConnectionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars like I, O, 0, 1
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Create a new connection code and start sensor sharing
  static Future<String> createConnectionForTicket(String ticketId, String userId, 
      String fromStop, String toStop) async {
    try {
      if (_database == null) {
        await initialize();
      }

      // Generate unique connection code
      String connectionCode = _generateConnectionCode();
      
      // Ensure the code is unique by checking if it exists
      int attempts = 0;
      while (attempts < 5) {
        final existingSession = await _database!.ref('$_sessionsPath/$connectionCode').get();
        if (!existingSession.exists) {
          break; // Code is unique
        }
        connectionCode = _generateConnectionCode();
        attempts++;
      }
      
      _currentConnectionCode = connectionCode;
      _currentTicketId = ticketId;
      
      print('🎫 Creating connection for ticket: $ticketId');
      print('🔑 Generated connection code: $connectionCode');
      
      // Store connection code info in database
      await _database!.ref('$_connectionCodesPath/$connectionCode').set({
        'ticketId': ticketId,
        'userId': userId,
        'fromStop': fromStop,
        'toStop': toStop,
        'createdAt': ServerValue.timestamp,
        'status': 'active',
        'deviceId': _deviceId,
      });
      
      // Start sensor data streaming
      await _startSensorStreaming(connectionCode);
      
      print('✅ Connection code created: $connectionCode');
      return connectionCode;
      
    } catch (e) {
      print('❌ Error creating connection code: $e');
      throw e;
    }
  }

  /// Start streaming sensor data for the connection
  static Future<void> _startSensorStreaming(String connectionCode) async {
    if (_isStreaming) {
      print('⚠️ Already streaming sensor data');
      return;
    }

    try {
      print('📡 Starting sensor data streaming for connection: $connectionCode');
      
      // Request all necessary permissions first
      print('🔒 Requesting permissions for sensor data collection...');
      bool permissionsGranted = await PermissionManager.requestAllPermissions();
      
      if (!permissionsGranted) {
        print('❌ Required permissions not granted');
        await PermissionManager.showPermissionDialog();
        return;
      }
      
      print('✅ Permissions granted, starting sensor streams...');
      _isStreaming = true;

      // Start accelerometer streaming
      _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        _currentAccel = [event.x, event.y, event.z];
        _sendSensorDataToFirebase(connectionCode);
      });

      // Start gyroscope streaming
      _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        _currentGyro = [event.x, event.y, event.z];
        _sendSensorDataToFirebase(connectionCode);
      });

      // Start GPS updates (every 2 seconds like the gyro-comparator app)
      _gpsTimer = Timer.periodic(Duration(seconds: 2), (_) async {
        await _updateGPSLocation(connectionCode);
      });

      print('✅ Sensor streaming started');
    } catch (e) {
      print('❌ Error starting sensor streaming: $e');
      throw e;
    }
  }

  /// Update GPS location
  static Future<void> _updateGPSLocation(String connectionCode) async {
    try {
      Location location = Location();
      
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      // Use improved permission handling
      bool hasPermission = await PermissionManager.hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await PermissionManager.requestLocationPermission();
        if (!hasPermission) {
          print('❌ Location permission denied - cannot update GPS');
          return;
        }
      }

      LocationData locationData = await location.getLocation();
      
      _currentSpeed = locationData.speed ?? 0.0; // speed in m/s
      _currentLatitude = locationData.latitude ?? 0.0;
      _currentLongitude = locationData.longitude ?? 0.0;
      
      _sendSensorDataToFirebase(connectionCode);
    } catch (e) {
      print('❌ Error updating GPS location: $e');
    }
  }

  /// Send sensor data to Firebase (same format as gyro-comparator app)
  static void _sendSensorDataToFirebase(String connectionCode) {
    if (_database == null || connectionCode.isEmpty) return;
    
    try {
      _database!.ref('$_sessionsPath/$connectionCode/$_deviceId').set({
        'accel': {'x': _currentAccel[0], 'y': _currentAccel[1], 'z': _currentAccel[2]},
        'gyro': {'x': _currentGyro[0], 'y': _currentGyro[1], 'z': _currentGyro[2]},
        'speed': _currentSpeed,
        'location': {
          'latitude': _currentLatitude,
          'longitude': _currentLongitude,
        },
        'lastUpdate': ServerValue.timestamp,
      });
    } catch (e) {
      print('❌ Error sending sensor data: $e');
    }
  }

  /// Stop sensor streaming and clean up connection
  static Future<void> stopConnectionForTicket(String ticketId) async {
    try {
      if (_currentTicketId != ticketId) {
        print('⚠️ No active connection for ticket: $ticketId');
        return;
      }

      print('🛑 Stopping connection for ticket: $ticketId');

      // Stop sensor subscriptions
      await _accelSubscription?.cancel();
      await _gyroSubscription?.cancel();
      _gpsTimer?.cancel();

      _accelSubscription = null;
      _gyroSubscription = null;
      _gpsTimer = null;
      _isStreaming = false;

      // Update connection status
      if (_currentConnectionCode != null && _database != null) {
        await _database!.ref('$_connectionCodesPath/$_currentConnectionCode').update({
          'status': 'completed',
          'completedAt': ServerValue.timestamp,
        });

        // Remove session data
        await _database!.ref('$_sessionsPath/$_currentConnectionCode').remove();
      }

      _currentConnectionCode = null;
      _currentTicketId = null;

      print('✅ Connection stopped and cleaned up');
    } catch (e) {
      print('❌ Error stopping connection: $e');
    }
  }

  /// Get current connection code
  static String? getCurrentConnectionCode() => _currentConnectionCode;

  /// Check if currently streaming
  static bool isStreaming() => _isStreaming;

  /// Get available connection codes (for admin/debugging)
  static Future<List<Map<String, dynamic>>> getActiveConnections() async {
    try {
      if (_database == null) await initialize();

      final snapshot = await _database!.ref(_connectionCodesPath)
          .orderByChild('status')
          .equalTo('active')
          .get();

      List<Map<String, dynamic>> connections = [];
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          connections.add({
            'connectionCode': key,
            ...Map<String, dynamic>.from(value),
          });
        });
      }

      return connections;
    } catch (e) {
      print('❌ Error getting active connections: $e');
      return [];
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _accelSubscription?.cancel();
    await _gyroSubscription?.cancel();
    _gpsTimer?.cancel();
    
    _accelSubscription = null;
    _gyroSubscription = null;
    _gpsTimer = null;
    _isStreaming = false;
    _currentConnectionCode = null;
    _currentTicketId = null;
  }
}
