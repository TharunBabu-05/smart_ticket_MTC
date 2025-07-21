import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ticket_mtc/models/trip_data_model.dart';
import 'package:smart_ticket_mtc/models/fraud_analysis_model.dart';
import 'package:smart_ticket_mtc/services/fraud_detection_service.dart';
import 'package:smart_ticket_mtc/services/location_service.dart';
import 'package:smart_ticket_mtc/services/sensor_service.dart';

void main() {
  group('Fraud Detection Tests', () {
    late FraudDetectionService fraudService;
    late LocationService locationService;
    late SensorService sensorService;

    setUp(() {
      fraudService = FraudDetectionService();
      locationService = LocationService();
      sensorService = SensorService();
    });

    group('Legitimate Journey Tests', () {
      test('Should not flag legitimate bus journey', () async {
        final legitTrip = _createLegitimateTrip();
        final analysis = await fraudService.analyzeTripData(legitTrip);
        
        expect(analysis.fraudConfidence, lessThan(0.3));
        expect(analysis.recommendation, equals(FraudRecommendation.noAction));
        expect(analysis.detectedTransportMode, equals(TransportMode.bus));
      });

      test('Should handle bike-alongside-bus scenario correctly', () async {
        final bikeTrip = _createBikeAlongsideTrip();
        final analysis = await fraudService.analyzeTripData(bikeTrip);
        
        // Should not flag as fraud because sensor data indicates bike movement
        expect(analysis.fraudConfidence, lessThan(0.4));
        expect(analysis.detectedTransportMode, equals(TransportMode.bike));
        expect(analysis.detectedIssues, contains('Sensor data indicates bike movement, not bus'));
      });

      test('Should not flag when user exits at destination', () async {
        final normalTrip = _createNormalExitTrip();
        final analysis = await fraudService.analyzeTripData(normalTrip);
        
        expect(analysis.fraudConfidence, lessThan(0.2));
        expect(analysis.recommendation, equals(FraudRecommendation.noAction));
      });
    });

    group('Fraud Detection Tests', () {
      test('Should flag obvious fare evasion', () async {
        final fraudTrip = _createFraudulentTrip();
        final analysis = await fraudService.analyzeTripData(fraudTrip);
        
        expect(analysis.fraudConfidence, greaterThan(0.7));
        expect(analysis.recommendation, 
               anyOf([FraudRecommendation.majorPenalty, FraudRecommendation.investigate]));
        expect(analysis.detectedIssues, isNotEmpty);
      });

      test('Should detect distance violation', () async {
        final distanceViolationTrip = _createDistanceViolationTrip();
        final analysis = await fraudService.analyzeTripData(distanceViolationTrip);
        
        expect(analysis.fraudConfidence, greaterThan(0.4));
        expect(analysis.detectedIssues, contains('Traveled beyond paid destination'));
      });

      test('Should detect route deviation', () async {
        final deviatedTrip = _createRouteDeviationTrip();
        final analysis = await fraudService.analyzeTripData(deviatedTrip);
        
        expect(analysis.routeDeviation, greaterThan(200));
        expect(analysis.detectedIssues, 
               anyOf([contains('route deviation'), contains('deviation')]));
      });
    });

    group('Transport Mode Classification Tests', () {
      test('Should correctly identify bus movement pattern', () async {
        final busTrip = _createBusMovementTrip();
        final analysis = await fraudService.analyzeTripData(busTrip);
        
        expect(analysis.detectedTransportMode, equals(TransportMode.bus));
        expect(analysis.speedAnalysis, isTrue);
      });

      test('Should correctly identify bike movement pattern', () async {
        final bikeTrip = _createBikeMovementTrip();
        final analysis = await fraudService.analyzeTripData(bikeTrip);
        
        expect(analysis.detectedTransportMode, equals(TransportMode.bike));
      });

      test('Should correctly identify walking pattern', () async {
        final walkingTrip = _createWalkingTrip();
        final analysis = await fraudService.analyzeTripData(walkingTrip);
        
        expect(analysis.detectedTransportMode, equals(TransportMode.walking));
      });
    });

    group('Sensor Analysis Tests', () {
      test('Should calculate acceleration variance correctly', () {
        final sensorReadings = _createBusSensorData();
        final variance = sensorService.calculateAccelerationVariance(sensorReadings);
        
        expect(variance, greaterThan(0.0));
        expect(variance, lessThan(5.0)); // Reasonable range
      });

      test('Should detect bus pattern from sensor data', () {
        final sensorReadings = _createBusSensorData();
        final isBusPattern = sensorService.detectBusPattern(sensorReadings);
        
        expect(isBusPattern, isTrue);
      });

      test('Should detect bike pattern from sensor data', () {
        final sensorReadings = _createBikeSensorData();
        final isBikePattern = sensorService.detectBikePattern(sensorReadings);
        
        expect(isBikePattern, isTrue);
      });
    });

    group('Location Analysis Tests', () {
      test('Should calculate distance correctly', () {
        final point1 = LatLng(13.0827, 80.2707); // Central Station
        final point2 = LatLng(13.0478, 80.2785); // Marina Beach
        
        final distance = locationService.calculateDistance(point1, point2);
        
        expect(distance, greaterThan(0));
        expect(distance, lessThan(10000)); // Should be less than 10km
      });

      test('Should detect bus stops correctly', () {
        final gpsTrail = _createGpsTrailWithStops();
        final knownStops = _createKnownBusStops();
        
        final detectedStops = locationService.detectBusStops(gpsTrail, knownStops);
        
        expect(detectedStops, isNotEmpty);
        expect(detectedStops.length, greaterThan(1));
      });

      test('Should validate speed consistency with bus', () {
        final gpsTrail = _createBusSpeedGpsTrail();
        final avgSpeed = locationService.calculateAverageSpeed(gpsTrail);
        
        final isConsistent = locationService.isSpeedConsistentWithBus(avgSpeed, gpsTrail);
        
        expect(isConsistent, isTrue);
      });
    });

    group('Edge Cases Tests', () {
      test('Should handle empty GPS trail gracefully', () async {
        final emptyTrip = _createEmptyGpsTrip();
        final analysis = await fraudService.analyzeTripData(emptyTrip);
        
        expect(analysis.fraudConfidence, equals(0.0));
        expect(analysis.detectedTransportMode, equals(TransportMode.unknown));
      });

      test('Should handle insufficient sensor data', () async {
        final minimalTrip = _createMinimalSensorTrip();
        final analysis = await fraudService.analyzeTripData(minimalTrip);
        
        expect(analysis.detectedTransportMode, equals(TransportMode.unknown));
      });

      test('Should handle GPS accuracy issues', () async {
        final inaccurateTrip = _createInaccurateGpsTrip();
        final analysis = await fraudService.analyzeTripData(inaccurateTrip);
        
        // Should be more lenient with inaccurate GPS
        expect(analysis.fraudConfidence, lessThan(0.8));
      });
    });
  });
}

// Helper functions to create test data

TripData _createLegitimateTrip() {
  return TripData(
    ticketId: 'test_legit_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 30)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707), // Central Station
    destinationLocation: LatLng(13.0478, 80.2785), // Marina Beach
    gpsTrail: _createLegitimateGpsTrail(),
    sensorData: _createBusSensorData(),
    status: TripStatus.completed,
    sourceName: 'Central Station',
    destinationName: 'Marina Beach',
  );
}

TripData _createBikeAlongsideTrip() {
  return TripData(
    ticketId: 'test_bike_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 20)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createBikeAlongsideGpsTrail(),
    sensorData: _createBikeSensorData(),
    status: TripStatus.completed,
    sourceName: 'Central Station',
    destinationName: 'Marina Beach',
  );
}

TripData _createFraudulentTrip() {
  return TripData(
    ticketId: 'test_fraud_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 60)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createFraudulentGpsTrail(), // Goes way beyond destination
    sensorData: _createBusSensorData(), // Indicates bus travel
    status: TripStatus.completed,
    sourceName: 'Central Station',
    destinationName: 'Marina Beach',
  );
}

TripData _createNormalExitTrip() {
  return TripData(
    ticketId: 'test_normal_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 25)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createNormalExitGpsTrail(),
    sensorData: _createBusSensorData(),
    status: TripStatus.completed,
    sourceName: 'Central Station',
    destinationName: 'Marina Beach',
  );
}

List<LocationPoint> _createLegitimateGpsTrail() {
  List<LocationPoint> trail = [];
  DateTime startTime = DateTime.now().subtract(Duration(minutes: 30));
  
  // Simulate bus route from Central Station to Marina Beach
  List<LatLng> routePoints = [
    LatLng(13.0827, 80.2707), // Central Station
    LatLng(13.0800, 80.2720), // Moving towards Marina
    LatLng(13.0750, 80.2740), // Bus stop
    LatLng(13.0700, 80.2760), // Moving
    LatLng(13.0650, 80.2770), // Bus stop
    LatLng(13.0600, 80.2775), // Moving
    LatLng(13.0550, 80.2780), // Bus stop
    LatLng(13.0500, 80.2783), // Moving
    LatLng(13.0478, 80.2785), // Marina Beach (destination)
  ];
  
  for (int i = 0; i < routePoints.length; i++) {
    trail.add(LocationPoint(
      position: routePoints[i],
      timestamp: startTime.add(Duration(minutes: i * 3)),
      speed: i % 2 == 0 ? 2.0 : 25.0, // Stop and go pattern
      accuracy: 5.0,
    ));
  }
  
  return trail;
}

List<LocationPoint> _createBikeAlongsideGpsTrail() {
  List<LocationPoint> trail = [];
  DateTime startTime = DateTime.now().subtract(Duration(minutes: 20));
  
  // Simulate bike traveling alongside bus route but faster
  List<LatLng> routePoints = [
    LatLng(13.0827, 80.2707), // Start at Central Station
    LatLng(13.0800, 80.2720), // Fast movement
    LatLng(13.0750, 80.2740), // No stops
    LatLng(13.0700, 80.2760), // Continuous movement
    LatLng(13.0650, 80.2770), // Higher speed
    LatLng(13.0600, 80.2775), // No bus stop pattern
    LatLng(13.0550, 80.2780), // Fast
    LatLng(13.0500, 80.2783), // Moving
    LatLng(13.0478, 80.2785), // Marina Beach
  ];
  
  for (int i = 0; i < routePoints.length; i++) {
    trail.add(LocationPoint(
      position: routePoints[i],
      timestamp: startTime.add(Duration(minutes: i * 2)), // Faster than bus
      speed: 35.0 + (i % 3) * 5, // Higher, more variable speed
      accuracy: 8.0,
    ));
  }
  
  return trail;
}

List<SensorReading> _createBusSensorData() {
  List<SensorReading> readings = [];
  DateTime startTime = DateTime.now().subtract(Duration(minutes: 30));
  
  for (int i = 0; i < 50; i++) {
    readings.add(SensorReading(
      timestamp: startTime.add(Duration(seconds: i * 10)),
      accelerometerX: 0.5 + (i % 5) * 0.1, // Consistent vibration
      accelerometerY: 0.3 + (i % 3) * 0.1,
      accelerometerZ: 9.8 + (i % 4) * 0.05,
      gyroscopeX: 0.1 + (i % 2) * 0.05, // Low gyro activity
      gyroscopeY: 0.1 + (i % 3) * 0.03,
      gyroscopeZ: 0.05 + (i % 2) * 0.02,
      calculatedSpeed: 20.0 + (i % 10) * 2, // Bus-like speed
    ));
  }
  
  return readings;
}

List<SensorReading> _createBikeSensorData() {
  List<SensorReading> readings = [];
  DateTime startTime = DateTime.now().subtract(Duration(minutes: 20));
  
  for (int i = 0; i < 30; i++) {
    readings.add(SensorReading(
      timestamp: startTime.add(Duration(seconds: i * 15)),
      accelerometerX: 1.0 + (i % 7) * 0.3, // More jerky movement
      accelerometerY: 0.8 + (i % 5) * 0.4,
      accelerometerZ: 9.5 + (i % 6) * 0.2,
      gyroscopeX: 0.5 + (i % 4) * 0.3, // Higher gyro activity
      gyroscopeY: 0.4 + (i % 3) * 0.4,
      gyroscopeZ: 0.3 + (i % 5) * 0.2,
      calculatedSpeed: 35.0 + (i % 8) * 5, // Higher, more variable speed
    ));
  }
  
  return readings;
}

// Additional helper functions for other test scenarios...
List<LocationPoint> _createFraudulentGpsTrail() {
  final normalTrail = _createLegitimateGpsTrail();
  
  // Add extra points beyond destination (fraud scenario)
  final lastPoint = normalTrail.last;
  normalTrail.addAll([
    LocationPoint(
      position: LatLng(13.0400, 80.2800), // Beyond Marina Beach
      timestamp: lastPoint.timestamp.add(Duration(minutes: 5)),
      speed: 25.0,
      accuracy: 5.0,
    ),
    LocationPoint(
      position: LatLng(13.0300, 80.2850), // Even further
      timestamp: lastPoint.timestamp.add(Duration(minutes: 10)),
      speed: 30.0,
      accuracy: 5.0,
    ),
  ]);
  
  return normalTrail;
}

TripData _createDistanceViolationTrip() {
  return TripData(
    ticketId: 'test_distance_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 45)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createFraudulentGpsTrail(),
    sensorData: _createBusSensorData(),
    status: TripStatus.completed,
  );
}

TripData _createRouteDeviationTrip() {
  return TripData(
    ticketId: 'test_deviation_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 35)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createDeviatedGpsTrail(),
    sensorData: _createBusSensorData(),
    status: TripStatus.completed,
  );
}

List<LocationPoint> _createDeviatedGpsTrail() {
  List<LocationPoint> trail = [];
  DateTime startTime = DateTime.now().subtract(Duration(minutes: 35));
  
  // Route that deviates significantly from direct path
  List<LatLng> routePoints = [
    LatLng(13.0827, 80.2707), // Start
    LatLng(13.0900, 80.2600), // Major deviation
    LatLng(13.0950, 80.2500), // Further deviation
    LatLng(13.0800, 80.2400), // Way off route
    LatLng(13.0600, 80.2600), // Coming back
    LatLng(13.0478, 80.2785), // End
  ];
  
  for (int i = 0; i < routePoints.length; i++) {
    trail.add(LocationPoint(
      position: routePoints[i],
      timestamp: startTime.add(Duration(minutes: i * 6)),
      speed: 25.0,
      accuracy: 5.0,
    ));
  }
  
  return trail;
}

// Additional helper functions for remaining test scenarios
TripData _createBusMovementTrip() => _createLegitimateTrip();
TripData _createBikeMovementTrip() => _createBikeAlongsideTrip();

TripData _createWalkingTrip() {
  return TripData(
    ticketId: 'test_walking_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 60)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createWalkingGpsTrail(),
    sensorData: _createWalkingSensorData(),
    status: TripStatus.completed,
  );
}

List<LocationPoint> _createWalkingGpsTrail() {
  List<LocationPoint> trail = [];
  DateTime startTime = DateTime.now().subtract(Duration(minutes: 60));
  
  for (int i = 0; i < 20; i++) {
    trail.add(LocationPoint(
      position: LatLng(
        13.0827 - (i * 0.002), 
        80.2707 + (i * 0.001),
      ),
      timestamp: startTime.add(Duration(minutes: i * 3)),
      speed: 4.0 + (i % 3), // Walking speed
      accuracy: 10.0,
    ));
  }
  
  return trail;
}

List<SensorReading> _createWalkingSensorData() {
  List<SensorReading> readings = [];
  DateTime startTime = DateTime.now().subtract(Duration(minutes: 60));
  
  for (int i = 0; i < 40; i++) {
    readings.add(SensorReading(
      timestamp: startTime.add(Duration(seconds: i * 20)),
      accelerometerX: 0.2 + (i % 4) * 0.1, // Rhythmic pattern
      accelerometerY: 0.3 + (i % 3) * 0.1,
      accelerometerZ: 9.7 + (i % 2) * 0.1,
      gyroscopeX: 0.05 + (i % 2) * 0.02, // Low gyro
      gyroscopeY: 0.03 + (i % 3) * 0.01,
      gyroscopeZ: 0.02 + (i % 2) * 0.01,
      calculatedSpeed: 5.0 + (i % 3), // Walking speed
    ));
  }
  
  return readings;
}

TripData _createEmptyGpsTrip() {
  return TripData(
    ticketId: 'test_empty_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 10)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: [], // Empty GPS trail
    sensorData: [],
    status: TripStatus.completed,
  );
}

TripData _createMinimalSensorTrip() {
  return TripData(
    ticketId: 'test_minimal_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 15)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createLegitimateGpsTrail(),
    sensorData: _createWalkingSensorData().take(5).toList(), // Minimal sensor data
    status: TripStatus.completed,
  );
}

TripData _createInaccurateGpsTrip() {
  return TripData(
    ticketId: 'test_inaccurate_001',
    userId: 'user_test',
    startTime: DateTime.now().subtract(Duration(minutes: 30)),
    endTime: DateTime.now(),
    sourceLocation: LatLng(13.0827, 80.2707),
    destinationLocation: LatLng(13.0478, 80.2785),
    gpsTrail: _createInaccurateGpsTrail(),
    sensorData: _createBusSensorData(),
    status: TripStatus.completed,
  );
}

List<LocationPoint> _createInaccurateGpsTrail() {
  final normalTrail = _createLegitimateGpsTrail();
  
  // Add GPS inaccuracy
  return normalTrail.map((point) => LocationPoint(
    position: point.position,
    timestamp: point.timestamp,
    speed: point.speed,
    accuracy: 50.0, // Poor accuracy
  )).toList();
}

List<LocationPoint> _createNormalExitGpsTrail() => _createLegitimateGpsTrail();

List<LocationPoint> _createGpsTrailWithStops() => _createLegitimateGpsTrail();

List<BusStop> _createKnownBusStops() {
  return [
    BusStop(id: '1', name: 'Central Station', location: LatLng(13.0827, 80.2707), sequence: 1),
    BusStop(id: '2', name: 'Stop 2', location: LatLng(13.0750, 80.2740), sequence: 2),
    BusStop(id: '3', name: 'Stop 3', location: LatLng(13.0650, 80.2770), sequence: 3),
    BusStop(id: '4', name: 'Marina Beach', location: LatLng(13.0478, 80.2785), sequence: 4),
  ];
}

List<LocationPoint> _createBusSpeedGpsTrail() => _createLegitimateGpsTrail();
