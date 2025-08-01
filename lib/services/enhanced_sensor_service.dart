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
      print('📱 Starting sensor monitoring...');
      
      // Monitor location
      Location location = Location();
      _locationSubscription = location.onLocationChanged.listen((LocationData locationData) {
        _currentSensorData['location'] = {
          'latitude': locationData.latitude ?? 0.0,
          'longitude': locationData.longitude ?? 0.0,
          'accuracy': locationData.accuracy ?? 0.0,
          'altitude': locationData.altitude ?? 0.0,
        };
        _currentSensorData['speed'] = locationData.speed ?? 0.0;
      });
      
      // Monitor accelerometer
      _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        _currentSensorData['accelerometer'] = {
          'x': double.parse(event.x.toStringAsFixed(2)),
          'y': double.parse(event.y.toStringAsFixed(2)),
          'z': double.parse(event.z.toStringAsFixed(2)),
        };
      });
      
      // Monitor gyroscope  
      _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        _currentSensorData['gyroscope'] = {
          'x': double.parse(event.x.toStringAsFixed(2)),
          'y': double.parse(event.y.toStringAsFixed(2)),
          'z': double.parse(event.z.toStringAsFixed(2)),
        };
      });
      
      print('✅ All sensors monitoring started');
      
    } catch (e) {
      print('❌ Error starting sensor monitoring: $e');
      _isStreaming = false;
    }
  }
  
  /// Start streaming timer (sends data every 2 seconds like Gyro Comparator)
  static void _startStreamingTimer() {
    _streamingTimer?.cancel();
    
    _streamingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (_activeConnectionCode != null && _isStreaming) {
        await _sendSensorDataToFirebase();
      }
    });
    
    print('⏰ Streaming timer started (every 2 seconds)');
  }
  
  /// Send current sensor data to Firebase (encrypted)
  static Future<void> _sendSensorDataToFirebase() async {
    try {
      if (_activeConnectionCode == null) return;
      
      // Update timestamp
      _currentSensorData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      _currentSensorData['deviceId'] = _generateDeviceId();
      _currentSensorData['ticketId'] = _activeTicketId;
      _currentSensorData['userId'] = _activeUserId;
      
      // Create encryption key from connection code
      String encryptionKey = EncryptionHelper.createEncryptionKey(_activeConnectionCode!);
      
      // Encrypt sensor data
      String encryptedData = EncryptionHelper.encryptSensorData(_currentSensorData, encryptionKey);
      
      // Store in Firebase under connection code (like Gyro Comparator)
      await _database.ref('sensor_sessions/$_activeConnectionCode/passenger_device').set({
        'encrypted_data': encryptedData,
        'connection_code': _activeConnectionCode,
        'device_type': 'passenger',
        'last_update': DateTime.now().millisecondsSinceEpoch,
        'status': 'streaming',
      });
      
      // Also store unencrypted data for internal use
      await _database.ref('ticket_sensors/$_activeTicketId').set({
        ..._currentSensorData,
        'connection_code': _activeConnectionCode,
        'status': 'active',
      });
      
      print('📡 Sensor data sent (encrypted with key: ${encryptionKey.substring(0, 8)}...)');
      
    } catch (e) {
      print('❌ Error sending sensor data: $e');
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
