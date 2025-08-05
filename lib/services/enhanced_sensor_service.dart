import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'encryption_helper.dart';

/// Enhanced Sensor Streaming Service for Smart Ticket MTC
/// This service streams sensor data exactly like the Gyro Comparator app
class EnhancedSensorService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Active streaming data
  static String? _activeConnectionCode;
  static String? _activeTicketId;
  static String? _activeUserId;
  static bool _isStreaming = false;
  static Timer? _streamingTimer;
  
  // Sensor subscriptions
  static StreamSubscription<LocationData>? _locationSubscription;
  static StreamSubscription<AccelerometerEvent>? _accelSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  // Current sensor data (like in Gyro Comparator)
  static Map<String, dynamic> _currentSensorData = {
    'accelerometer': {'x': 0.0, 'y': 0.0, 'z': 0.0},
    'gyroscope': {'x': 0.0, 'y': 0.0, 'z': 0.0},
    'speed': 0.0,
    'location': {'latitude': 0.0, 'longitude': 0.0},
    'timestamp': 0,
  };
  
  /// Start sensor streaming for a ticket (called when ticket is created)
  static Future<String> startSensorStreamingForTicket(String ticketId, String userId) async {
    try {
      // Generate connection code (like ABC123)
      String connectionCode = EncryptionHelper.generateConnectionCode();
      print('🔗 Generated connection code: $connectionCode');
      
      _activeConnectionCode = connectionCode;
      _activeTicketId = ticketId;
      _activeUserId = userId;
      
      // Start sensor monitoring
      await _startSensorMonitoring();
      
      // Start streaming timer (sends data every 2 seconds like Gyro Comparator)
      _startStreamingTimer();
      
      // Store connection info in Firebase
      await _storeConnectionInfo(connectionCode, ticketId, userId);
      
      print('✅ Sensor streaming started with connection code: $connectionCode');
      return connectionCode;
      
    } catch (e) {
      print('❌ Error starting sensor streaming: $e');
      throw e;
    }
  }
  
  /// Start monitoring all sensors
  static Future<void> _startSensorMonitoring() async {
    if (_isStreaming) return;
    
    try {
      _isStreaming = true;
      print('📱 Starting ultra-fast sensor monitoring...');
      
      // Monitor location with high accuracy
      Location location = Location();
      await location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 100, // Update every 100ms
        distanceFilter: 0, // Update on any movement
      );
      
      _locationSubscription = location.onLocationChanged.listen((LocationData locationData) {
        _currentSensorData['location'] = {
          'latitude': locationData.latitude ?? 0.0,
          'longitude': locationData.longitude ?? 0.0,
          'accuracy': locationData.accuracy ?? 0.0,
          'altitude': locationData.altitude ?? 0.0,
        };
        _currentSensorData['speed'] = locationData.speed ?? 0.0;
      });
      
      // Monitor accelerometer with high precision (like Gyro Comparator: -8.67, 2.3, 4.02)
      _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        _currentSensorData['accelerometer'] = {
          'x': double.parse(event.x.toStringAsFixed(2)), // High precision like -8.67
          'y': double.parse(event.y.toStringAsFixed(2)), // High precision like 2.3
          'z': double.parse(event.z.toStringAsFixed(2)), // High precision like 4.02
        };
      });
      
      // Monitor gyroscope with ultra-high precision (like Gyro Comparator: 0.01, 0.19, 0.02)
      _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        _currentSensorData['gyroscope'] = {
          'x': double.parse(event.x.toStringAsFixed(2)), // Ultra precision like 0.01
          'y': double.parse(event.y.toStringAsFixed(2)), // Ultra precision like 0.19
          'z': double.parse(event.z.toStringAsFixed(2)), // Ultra precision like 0.02
        };
      });
      
      print('✅ All sensors monitoring started with ultra-fast updates');
      
    } catch (e) {
      print('❌ Error starting sensor monitoring: $e');
      _isStreaming = false;
    }
  }
  
  /// Start streaming timer (sends data every 100ms for ultra-fast updates like Gyro Comparator)
  static void _startStreamingTimer() {
    _streamingTimer?.cancel();
    
    // Ultra-fast streaming - every 100ms (10 times per second) like Gyro Comparator
    _streamingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
      if (_activeConnectionCode != null && _isStreaming) {
        await _sendSensorDataToFirebase();
      }
    });
    
    print('⚡ Ultra-fast streaming timer started (every 100ms)');
  }
  
  /// Send current sensor data to Firebase (ultra-fast like Gyro Comparator)
  static Future<void> _sendSensorDataToFirebase() async {
    try {
      if (_activeConnectionCode == null) return;
      
      // Create high-precision timestamp (microseconds for ultra accuracy)
      int microTimestamp = DateTime.now().microsecondsSinceEpoch;
      
      // Prepare ultra-fast sensor data structure (matching Gyro Comparator format)
      Map<String, dynamic> ultraFastData = {
        'accelerometer': _currentSensorData['accelerometer'] ?? {'x': 0.0, 'y': 0.0, 'z': 0.0},
        'gyroscope': _currentSensorData['gyroscope'] ?? {'x': 0.0, 'y': 0.0, 'z': 0.0},
        'speed': _currentSensorData['speed'] ?? 0.0,
        'timestamp': microTimestamp,
        'deviceId': _generateDeviceId(),
        'ticketId': _activeTicketId,
        'userId': _activeUserId,
        'connection_code': _activeConnectionCode,
        'device_type': 'admin', // Match Gyro Comparator format
      };
      
      // Create encryption key from connection code
      String encryptionKey = EncryptionHelper.createEncryptionKey(_activeConnectionCode!);
      
      // Encrypt sensor data
      String encryptedData = EncryptionHelper.encryptSensorData(ultraFastData, encryptionKey);
      
      // Store in Firebase under connection code (ultra-fast path like Gyro Comparator)
      String fastDataPath = '$_activeConnectionCode/admin_device';
      
      await _database.ref('sensor_sessions/$fastDataPath').set({
        'accelerometer': ultraFastData['accelerometer'],
        'gyroscope': ultraFastData['gyroscope'],
        'speed': ultraFastData['speed'],
        'timestamp': microTimestamp,
        'connection_code': _activeConnectionCode,
        'device_type': 'admin',
        'deviceId': ultraFastData['deviceId'],
        'last_update': DateTime.now().millisecondsSinceEpoch,
        'encrypted_data': encryptedData,
        'status': 'streaming',
      });
      
      // Also store raw unencrypted data for ultra-fast access (like Gyro Comparator)
      await _database.ref('ultra_fast_sensors/${_activeTicketId}').set({
        'accel': ultraFastData['accelerometer'],
        'gyro': ultraFastData['gyroscope'],
        'speed': ultraFastData['speed'],
        'timestamp': microTimestamp,
        'connection_code': _activeConnectionCode,
        'device_type': 'admin',
      });
      
      // Store in ticket sensors for internal tracking
      await _database.ref('ticket_sensors/$_activeTicketId').set({
        ...ultraFastData,
        'status': 'active',
      });
      
      // Debug: Uncomment to see ultra-fast streaming
      // print('⚡ Ultra-fast sensor data sent: ${DateTime.now().millisecond}ms');
      
    } catch (e) {
      print('❌ Error sending ultra-fast sensor data: $e');
    }
  }
  
  /// Store connection information
  static Future<void> _storeConnectionInfo(String connectionCode, String ticketId, String userId) async {
    try {
      await _database.ref('connection_codes/$connectionCode').set({
        'ticket_id': ticketId,
        'user_id': userId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'active',
        'device_type': 'passenger',
        'app_name': 'Smart Ticket MTC',
      });
      
      print('🔗 Connection info stored for code: $connectionCode');
      
    } catch (e) {
      print('❌ Error storing connection info: $e');
    }
  }
  
  /// Stop sensor streaming
  static Future<void> stopSensorStreaming() async {
    try {
      print('🛑 Stopping sensor streaming...');
      
      _isStreaming = false;
      _streamingTimer?.cancel();
      
      // Cancel sensor subscriptions
      await _locationSubscription?.cancel();
      await _accelSubscription?.cancel();
      await _gyroSubscription?.cancel();
      
      // Update status in Firebase
      if (_activeConnectionCode != null) {
        await _database.ref('sensor_sessions/$_activeConnectionCode/passenger_device/status').set('stopped');
        await _database.ref('connection_codes/$_activeConnectionCode/status').set('completed');
      }
      
      // Clear active data
      _activeConnectionCode = null;
      _activeTicketId = null;
      _activeUserId = null;
      
      print('✅ Sensor streaming stopped');
      
    } catch (e) {
      print('❌ Error stopping sensor streaming: $e');
    }
  }
  
  /// Generate device ID (like in Gyro Comparator)
  static String _generateDeviceId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Get current connection code
  static String? getCurrentConnectionCode() => _activeConnectionCode;
  
  /// Check if streaming is active
  static bool isStreaming() => _isStreaming;
  
  /// Get current sensor data (for display)
  static Map<String, dynamic> getCurrentSensorData() => Map.from(_currentSensorData);
}
