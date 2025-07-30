import 'dart:async';
import 'dart:isolate';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/material.dart';
import '../models/trip_data_model.dart';
import '../models/fraud_analysis_model.dart';
import 'location_service.dart';
import 'sensor_service.dart';
import 'fraud_detection_service_new.dart';

class BackgroundTripService {
  static const String _serviceName = 'smart_ticketing_service';
  static const String _notificationChannelId = 'smart_ticketing';
  static const String _notificationChannelName = 'Smart Ticketing';

  /// Initialize the background service
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Start manually when trip begins
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Smart Ticketing Active',
        initialNotificationContent: 'Monitoring your bus journey',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start monitoring for a specific trip
  static Future<void> startTripMonitoring(TripData tripData) async {
    final service = FlutterBackgroundService();
    
    // Pass trip data to the background service
    service.invoke('startTrip', {
      'tripData': tripData.toMap(),
    });
    
    if (!(await service.isRunning())) {
      service.startService();
    }
  }

  /// Stop trip monitoring
  static Future<void> stopTripMonitoring() async {
    final service = FlutterBackgroundService();
    
    service.invoke('stopTrip');
    // Note: In v5.x, service stops automatically when no longer needed
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('Background service started');
    
    // Initialize services
    final locationService = LocationService();
    final sensorService = SensorService();
    
    TripData? currentTrip;
    List<LocationPoint> gpsTrail = [];
    List<SensorReading> sensorData = [];
    
    Timer? monitoringTimer;
    StreamSubscription<LocationPoint>? locationSubscription;
    StreamSubscription<SensorReading>? sensorSubscription;

    // Listen for service commands
    service.on('startTrip').listen((event) async {
      print('Starting trip monitoring');
      
      if (event != null && event['tripData'] != null) {
        currentTrip = TripData.fromMap(event['tripData']);
        gpsTrail.clear();
        sensorData.clear();
        
        // Start location and sensor monitoring
        await _startMonitoring(
          locationService, 
          sensorService, 
          (location) => gpsTrail.add(location),
          (sensor) => sensorData.add(sensor),
        );
        
        // Start periodic analysis
        monitoringTimer = Timer.periodic(
          const Duration(minutes: 2), 
          (timer) async {
            await _performPeriodicAnalysis(
              currentTrip!, 
              gpsTrail, 
              sensorData, 
              service,
            );
          },
        );
        
        // Update notification
        service.invoke('update', {
          'title': 'Trip Active',
          'content': 'Monitoring journey from ${currentTrip!.sourceName} to ${currentTrip!.destinationName}',
        });
      }
    });

    service.on('stopTrip').listen((event) async {
      print('Stopping trip monitoring');
      
      // Stop monitoring
      monitoringTimer?.cancel();
      locationService.stopTracking();
      sensorService.stopMonitoring();
      
      // Perform final analysis
      if (currentTrip != null) {
        await _performFinalAnalysis(
          currentTrip!, 
          gpsTrail, 
          sensorData, 
        );
      }
      
      currentTrip = null;
      gpsTrail.clear();
      sensorData.clear();
      
      service.stopSelf();
    });

    // Handle service stop
    service.on('stopService').listen((event) {
      monitoringTimer?.cancel();
      locationService.dispose();
      sensorService.dispose();
      service.stopSelf();
    });
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    print('iOS background mode');
    return true;
  }

  /// Start location and sensor monitoring
  static Future<void> _startMonitoring(
    LocationService locationService,
    SensorService sensorService,
    Function(LocationPoint) onLocationUpdate,
    Function(SensorReading) onSensorUpdate,
  ) async {
    // Start location tracking
    bool locationStarted = await locationService.startTracking();
    if (locationStarted) {
      locationService.locationStream.listen(onLocationUpdate);
    }

    // Start sensor monitoring
    await sensorService.startMonitoring();
    sensorService.sensorStream.listen(onSensorUpdate);
  }

  /// Perform periodic fraud analysis
  static Future<void> _performPeriodicAnalysis(
    TripData tripData,
    List<LocationPoint> gpsTrail,
    List<SensorReading> sensorData,
    ServiceInstance service,
  ) async {
    try {
      // Create updated trip data
      TripData updatedTrip = tripData.copyWith(
        gpsTrail: List.from(gpsTrail),
        sensorData: List.from(sensorData),
      );

      // Quick fraud check
      bool suspiciousActivity = await FraudDetectionService.quickFraudCheck(updatedTrip);
      
      if (suspiciousActivity) {
        // Send alert notification
        service.invoke('update', {
          'title': 'Suspicious Activity Detected',
          'content': 'Please ensure you are traveling on the correct bus',
        });
        
        // Save alert to Firebase
        String alertId = FraudDetectionService.generateAlertId();
        FraudAlert alert = FraudAlert(
          alertId: alertId,
          tripId: tripData.ticketId,
          userId: tripData.userId,
          fraudConfidence: 0.7, // High confidence for real-time alert
          detectedIssues: ['Real-time suspicious activity detected'],
        );
        
        await FraudDetectionService.createFraudAlert(alert.toMap());
      }

      // Save periodic trip update
      await FraudDetectionService.saveTripData(updatedTrip);
      
    } catch (e) {
      print('Error in periodic analysis: $e');
    }
  }

  /// Perform final analysis when trip ends
  static Future<void> _performFinalAnalysis(
    TripData tripData,
    List<LocationPoint> gpsTrail,
    List<SensorReading> sensorData,
  ) async {
    try {
      // Create final trip data
      TripData finalTrip = tripData.copyWith(
        endTime: DateTime.now(),
        gpsTrail: List.from(gpsTrail),
        sensorData: List.from(sensorData),
        status: TripStatus.completed,
      );

      // Perform comprehensive fraud analysis
      FraudAnalysis analysis = await FraudDetectionService.analyzeTripData(finalTrip);
      
      // Update trip with fraud confidence
      finalTrip = finalTrip.copyWith(
        fraudConfidence: analysis.fraudConfidence,
        status: analysis.fraudConfidence > 0.6 
            ? TripStatus.flagged 
            : TripStatus.completed,
      );

      // Save final results
      await FraudDetectionService.saveTripData(finalTrip, analysis.toMap());
      await FraudDetectionService.saveUserTripHistory(tripData.userId, finalTrip);

      // Create fraud alert if necessary
      if (analysis.recommendation != FraudRecommendation.noAction) {
        String alertId = FraudDetectionService.generateAlertId();
        FraudAlert alert = FraudAlert(
          alertId: alertId,
          tripId: tripData.ticketId,
          userId: tripData.userId,
          fraudConfidence: analysis.fraudConfidence,
          detectedIssues: analysis.detectedIssues,
        );
        
        await FraudDetectionService.createFraudAlert(alert.toMap());
      }

      print('Final trip analysis completed');
      
    } catch (e) {
      print('Error in final analysis: $e');
    }
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Send data to running service
  static Future<void> sendDataToService(String method, Map<String, dynamic> data) async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke(method, data);
    }
  }
}
