import 'dart:math';
import '../models/trip_data_model.dart';
import '../models/fraud_analysis_model.dart';
import '../data/bus_stops_data.dart';
import 'location_service.dart';
import 'sensor_service.dart';

class FraudDetectionService {
  static final LocationService _locationService = LocationService();
  static final SensorService _sensorService = SensorService();
  
  /// Main fraud analysis function
  Future<FraudAnalysis> analyzeTripData(TripData tripData) async {
    List<String> detectedIssues = [];
    
    // 1. Speed Pattern Analysis
    double avgSpeed = _locationService.calculateAverageSpeed(tripData.gpsTrail);
    bool speedMatchesBus = _locationService.isSpeedConsistentWithBus(avgSpeed, tripData.gpsTrail);
    
    if (!speedMatchesBus) {
      detectedIssues.add('Speed pattern inconsistent with bus movement');
    }
    
    // 2. Stop Pattern Analysis
    List<BusStop> detectedStops = _locationService.detectBusStops(tripData.gpsTrail, BusStopsData.allStops);
    bool stopsMatchBusRoute = _validateStopPattern(detectedStops, tripData);
    
    if (!stopsMatchBusRoute) {
      detectedIssues.add('Stop pattern does not match expected bus route');
    }
    
    // 3. Sensor Pattern Analysis
    TransportMode detectedMode = _classifyTransportMode(tripData.sensorData);
    bool sensorIndicatesBus = detectedMode == TransportMode.bus;
    
    if (!sensorIndicatesBus && detectedMode != TransportMode.unknown) {
      detectedIssues.add('Sensor data indicates ${detectedMode.toString().split('.').last} movement, not bus');
    }
    
    // 4. Route Deviation Analysis
    double routeDeviation = _locationService.calculateRouteDeviation(
      tripData.gpsTrail, 
      tripData.sourceLocation, 
      tripData.destinationLocation,
    );
    
    if (routeDeviation > 200) { // 200m deviation threshold
      detectedIssues.add('Significant route deviation detected (${routeDeviation.toInt()}m)');
    }
    
    // 5. Distance Analysis
    bool distanceExceeded = _checkDistanceViolation(tripData);
    if (distanceExceeded) {
      detectedIssues.add('Traveled beyond paid destination');
    }
    
    // 6. Calculate fraud confidence
    double fraudConfidence = _calculateFraudConfidence(
      speedMatchesBus: speedMatchesBus,
      stopsMatchBusRoute: stopsMatchBusRoute,
      sensorIndicatesBus: sensorIndicatesBus,
      routeDeviation: routeDeviation,
      distanceExceeded: distanceExceeded,
      tripData: tripData,
    );
    
    // 7. Get recommendation
    FraudRecommendation recommendation = _getFraudRecommendation(fraudConfidence, detectedIssues);
    
    return FraudAnalysis(
      fraudConfidence: fraudConfidence,
      detectedTransportMode: detectedMode,
      speedAnalysis: speedMatchesBus,
      stopAnalysis: stopsMatchBusRoute,
      routeDeviation: routeDeviation,
      recommendation: recommendation,
      detectedIssues: detectedIssues,
    );
  }
  
  /// Calculate fraud confidence score (0.0 = legitimate, 1.0 = definitely fraud)
  double _calculateFraudConfidence({
    required bool speedMatchesBus,
    required bool stopsMatchBusRoute,
    required bool sensorIndicatesBus,
    required double routeDeviation,
    required bool distanceExceeded,
    required TripData tripData,
  }) {
    double confidence = 0.0;
    
    // If user didn't exceed paid distance, very low fraud risk
    if (!distanceExceeded) {
      return 0.1; // Minimal risk for legitimate distance
    }
    
    // Base fraud score for distance violation
    confidence += 0.4;
    
    // Reduce confidence if indicators suggest legitimate bus travel
    if (speedMatchesBus) {
      confidence -= 0.2;
    } else {
      confidence += 0.1;
    }
    
    if (stopsMatchBusRoute) {
      confidence -= 0.2;
    } else {
      confidence += 0.1;
    }
    
    if (sensorIndicatesBus) {
      confidence -= 0.3; // Strong indicator of bus travel
    } else {
      confidence += 0.2;
    }
    
    // Route deviation penalty
    if (routeDeviation > 200) {
      confidence += min(routeDeviation / 1000, 0.3); // Max 0.3 penalty
    }
    
    // Time-based analysis
    if (tripData.gpsTrail.isNotEmpty) {
      Duration tripDuration = tripData.gpsTrail.last.timestamp
          .difference(tripData.gpsTrail.first.timestamp);
      
      double expectedDuration = _calculateExpectedTripDuration(tripData);
      double durationRatio = tripDuration.inMinutes / expectedDuration;
      
      // If trip took much longer than expected, might indicate fraud
      if (durationRatio > 2.0) {
        confidence += 0.1;
      }
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Check if user traveled beyond their paid destination
  bool _checkDistanceViolation(TripData tripData) {
    if (tripData.gpsTrail.isEmpty) return false;
    
    double actualDistance = _locationService.calculateTotalDistance(tripData.gpsTrail);
    double paidDistance = _locationService.calculateDistance(
      tripData.sourceLocation, 
      tripData.destinationLocation,
    );
    
    // Allow 15% tolerance for GPS inaccuracy and route variations
    return actualDistance > (paidDistance * 1.15);
  }
  
  /// Classify transport mode based on sensor data
  TransportMode _classifyTransportMode(List<SensorReading> sensorData) {
    if (sensorData.length < 10) return TransportMode.unknown;
    
    // Calculate sensor characteristics
    double avgAccelVariance = _sensorService.calculateAccelerationVariance(sensorData);
    double avgSpeed = sensorData
        .map((s) => s.calculatedSpeed)
        .reduce((a, b) => a + b) / sensorData.length;
    
    // Calculate gyroscope activity
    double avgGyroActivity = sensorData.map((reading) {
      return sqrt(
        reading.gyroscopeX * reading.gyroscopeX +
        reading.gyroscopeY * reading.gyroscopeY +
        reading.gyroscopeZ * reading.gyroscopeZ
      );
    }).reduce((a, b) => a + b) / sensorData.length;
    
    // Bus characteristics: moderate speed with consistent engine vibration
    if (avgSpeed > 15 && avgSpeed < 50 && 
        avgAccelVariance > 0.5 && avgAccelVariance < 2.0 &&
        avgGyroActivity < 1.0) {
      return TransportMode.bus;
    }
    
    // Bike characteristics: higher speed with jerky movements
    if (avgSpeed > 25 && avgAccelVariance > 1.5 && avgGyroActivity > 1.0) {
      return TransportMode.bike;
    }
    
    // Car characteristics: smooth movement at various speeds
    if (avgSpeed > 20 && avgAccelVariance < 1.0 && avgGyroActivity < 0.8) {
      return TransportMode.car;
    }
    
    // Walking characteristics: low speed with rhythmic pattern
    if (avgSpeed < 10 && avgAccelVariance < 0.8) {
      return TransportMode.walking;
    }
    
    return TransportMode.unknown;
  }
  
  /// Validate if detected stops match expected bus route
  bool _validateStopPattern(List<BusStop> detectedStops, TripData tripData) {
    if (detectedStops.length < 2) return false;
    
    // Find source and destination stops
    BusStop? sourceStop = _findNearestStop(tripData.sourceLocation);
    BusStop? destStop = _findNearestStop(tripData.destinationLocation);
    
    if (sourceStop == null || destStop == null) return false;
    
    // Check if detected stops are in correct sequence
    List<int> expectedSequence = _getExpectedStopSequence(sourceStop, destStop);
    List<int> detectedSequence = detectedStops.map((stop) => stop.sequence).toList();
    
    // Allow some missing stops but sequence should be generally correct
    int matchingStops = 0;
    for (int expectedSeq in expectedSequence) {
      if (detectedSequence.contains(expectedSeq)) {
        matchingStops++;
      }
    }
    
    // At least 60% of expected stops should be detected
    return matchingStops >= (expectedSequence.length * 0.6);
  }
  
  /// Find nearest bus stop to a location
  BusStop? _findNearestStop(LatLng location) {
    BusStop? nearestStop;
    double minDistance = double.infinity;
    
    for (var stop in BusStopsData.allStops) {
      double distance = _locationService.calculateDistance(location, stop.location);
      if (distance < minDistance && distance <= 500) { // Within 500m
        minDistance = distance;
        nearestStop = stop;
      }
    }
    
    return nearestStop;
  }
  
  /// Get expected stop sequence between source and destination
  List<int> _getExpectedStopSequence(BusStop source, BusStop destination) {
    List<int> sequence = [];
    
    int startSeq = min(source.sequence, destination.sequence);
    int endSeq = max(source.sequence, destination.sequence);
    
    for (int i = startSeq; i <= endSeq; i++) {
      sequence.add(i);
    }
    
    return sequence;
  }
  
  /// Calculate expected trip duration based on distance and bus speed
  double _calculateExpectedTripDuration(TripData tripData) {
    double distance = _locationService.calculateDistance(
      tripData.sourceLocation, 
      tripData.destinationLocation,
    );
    
    // Assume average bus speed of 25 km/h including stops
    double avgBusSpeed = 25.0; // km/h
    double expectedHours = (distance / 1000) / avgBusSpeed;
    
    return expectedHours * 60; // Return in minutes
  }
  
  /// Get fraud recommendation based on confidence score
  FraudRecommendation _getFraudRecommendation(double confidence, List<String> issues) {
    if (confidence < 0.2) {
      return FraudRecommendation.noAction;
    } else if (confidence < 0.4) {
      return FraudRecommendation.warning;
    } else if (confidence < 0.6) {
      return FraudRecommendation.minorPenalty;
    } else if (confidence < 0.8) {
      return FraudRecommendation.majorPenalty;
    } else {
      return FraudRecommendation.investigate;
    }
  }
  
  /// Quick analysis for real-time monitoring
  Future<bool> quickFraudCheck(TripData tripData) async {
    // Simplified check for real-time alerts
    if (tripData.gpsTrail.isEmpty) return false;
    
    // Check if user has exceeded paid distance significantly
    bool distanceViolation = _checkDistanceViolation(tripData);
    if (!distanceViolation) return false;
    
    // Quick sensor check
    if (tripData.sensorData.isNotEmpty) {
      TransportMode mode = _classifyTransportMode(tripData.sensorData);
      if (mode == TransportMode.bike || mode == TransportMode.car) {
        return true; // Likely fraud
      }
    }
    
    return false;
  }
}
