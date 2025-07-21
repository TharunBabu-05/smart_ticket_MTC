import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/trip_data_model.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  final StreamController<SensorReading> _sensorController = 
      StreamController<SensorReading>.broadcast();
  
  Stream<SensorReading> get sensorStream => _sensorController.stream;
  
  AccelerometerEvent? _lastAccelEvent;
  GyroscopeEvent? _lastGyroEvent;
  
  bool _isMonitoring = false;
  
  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Monitor accelerometer with reduced frequency to save battery
    _accelSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _lastAccelEvent = event;
        _processSensorData();
      },
      onError: (error) => print('Accelerometer error: $error'),
    );
    
    // Monitor gyroscope
    _gyroSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        _lastGyroEvent = event;
        _processSensorData();
      },
      onError: (error) => print('Gyroscope error: $error'),
    );
  }
  
  void _processSensorData() {
    // Only process when we have both accelerometer and gyroscope data
    if (_lastAccelEvent != null && _lastGyroEvent != null) {
      final sensorReading = SensorReading(
        timestamp: DateTime.now(),
        accelerometerX: _lastAccelEvent!.x,
        accelerometerY: _lastAccelEvent!.y,
        accelerometerZ: _lastAccelEvent!.z,
        gyroscopeX: _lastGyroEvent!.x,
        gyroscopeY: _lastGyroEvent!.y,
        gyroscopeZ: _lastGyroEvent!.z,
        calculatedSpeed: _calculateSpeedFromSensors(_lastAccelEvent!, _lastGyroEvent!),
      );
      
      _sensorController.add(sensorReading);
    }
  }
  
  double _calculateSpeedFromSensors(
    AccelerometerEvent accel, 
    GyroscopeEvent gyro,
  ) {
    // Calculate total acceleration magnitude
    double totalAccel = sqrt(
      accel.x * accel.x + 
      accel.y * accel.y + 
      accel.z * accel.z
    );
    
    // Calculate total gyroscope magnitude
    double totalGyro = sqrt(
      gyro.x * gyro.x + 
      gyro.y * gyro.y + 
      gyro.z * gyro.z
    );
    
    // Simplified speed estimation using sensor fusion
    // This is a basic implementation - in production, you'd use more sophisticated algorithms
    double estimatedSpeed = (totalAccel * 3.6).clamp(0.0, 100.0);
    
    // Adjust based on gyroscope data (higher gyro values indicate more movement)
    if (totalGyro > 0.5) {
      estimatedSpeed *= 1.2; // Increase speed estimate for active movement
    }
    
    return estimatedSpeed;
  }
  
  /// Calculate acceleration variance to help classify transport mode
  double calculateAccelerationVariance(List<SensorReading> readings) {
    if (readings.isEmpty) return 0.0;
    
    List<double> accelerations = readings.map((reading) {
      return sqrt(
        reading.accelerometerX * reading.accelerometerX +
        reading.accelerometerY * reading.accelerometerY +
        reading.accelerometerZ * reading.accelerometerZ
      );
    }).toList();
    
    double mean = accelerations.reduce((a, b) => a + b) / accelerations.length;
    double variance = accelerations
        .map((accel) => pow(accel - mean, 2))
        .reduce((a, b) => a + b) / accelerations.length;
    
    return variance;
  }
  
  /// Detect if the movement pattern matches bus characteristics
  bool detectBusPattern(List<SensorReading> readings) {
    if (readings.length < 10) return false;
    
    double variance = calculateAccelerationVariance(readings);
    double avgSpeed = readings
        .map((r) => r.calculatedSpeed)
        .reduce((a, b) => a + b) / readings.length;
    
    // Bus characteristics:
    // - Moderate speed (15-50 km/h)
    // - Consistent vibration pattern (variance > 0.5)
    // - Regular stops and starts
    return avgSpeed >= 15 && avgSpeed <= 50 && variance > 0.5;
  }
  
  /// Detect if the movement pattern matches bike characteristics
  bool detectBikePattern(List<SensorReading> readings) {
    if (readings.length < 10) return false;
    
    double variance = calculateAccelerationVariance(readings);
    double avgSpeed = readings
        .map((r) => r.calculatedSpeed)
        .reduce((a, b) => a + b) / readings.length;
    
    // Bike characteristics:
    // - Higher speed (30+ km/h)
    // - Jerky movements (high variance)
    // - Less consistent than bus
    return avgSpeed >= 30 && variance > 1.0;
  }
  
  /// Detect if the movement pattern matches walking characteristics
  bool detectWalkingPattern(List<SensorReading> readings) {
    if (readings.length < 10) return false;
    
    double variance = calculateAccelerationVariance(readings);
    double avgSpeed = readings
        .map((r) => r.calculatedSpeed)
        .reduce((a, b) => a + b) / readings.length;
    
    // Walking characteristics:
    // - Low speed (< 10 km/h)
    // - Rhythmic pattern (low to moderate variance)
    return avgSpeed < 10 && variance < 0.8;
  }
  
  void stopMonitoring() {
    _isMonitoring = false;
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
  }
  
  void dispose() {
    stopMonitoring();
    _sensorController.close();
  }
}
