import 'dart:async';
import 'dart:math';
import 'package:location/location.dart';
import '../models/trip_data_model.dart';

class LocationService {
  StreamSubscription<LocationData>? _positionSubscription;
  final StreamController<LocationPoint> _locationController = 
      StreamController<LocationPoint>.broadcast();
  final Location _location = Location();
  
  Stream<LocationPoint> get locationStream => _locationController.stream;
  
  bool _isTracking = false;
  LocationPoint? _lastKnownLocation;
  
  bool get isTracking => _isTracking;
  LocationPoint? get lastKnownLocation => _lastKnownLocation;

  /// Request location permissions
  Future<bool> requestPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }
    }
    
    // Request location permission
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print('Location permission denied');
        return false;
      }
    }
    
    return true;
  }

  /// Start tracking user location
  Future<bool> startTracking() async {
    if (_isTracking) return true;
    
    // Request permissions first
    bool hasPermission = await requestPermissions();
    if (!hasPermission) return false;
    
    try {
      // Configure location settings for optimal battery and accuracy balance
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // Update every 10 seconds
        distanceFilter: 10, // Update every 10 meters
      );
      
      // Start position stream
      _positionSubscription = _location.onLocationChanged.listen(
        (LocationData locationData) {
          final locationPoint = LocationPoint(
            position: LatLng(locationData.latitude!, locationData.longitude!),
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              locationData.time?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
            ),
            speed: (locationData.speed ?? 0) * 3.6, // Convert m/s to km/h
            accuracy: locationData.accuracy ?? 0,
          );
          
          _lastKnownLocation = locationPoint;
          _locationController.add(locationPoint);
        },
        onError: (error) {
          print('Location error: $error');
          _isTracking = false;
        },
      );
      
      _isTracking = true;
      return true;
    } catch (e) {
      print('Failed to start location tracking: $e');
      return false;
    }
  }
  
  /// Get current location once
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestPermissions();
      if (!hasPermission) return null;
      
      LocationData locationData = await _location.getLocation();
      
      return LocationPoint(
        position: LatLng(locationData.latitude!, locationData.longitude!),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          locationData.time?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        ),
        speed: (locationData.speed ?? 0) * 3.6,
        accuracy: locationData.accuracy ?? 0,
      );
    } catch (e) {
      print('Failed to get current location: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points in meters using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    double lat1Rad = point1.latitude * (pi / 180);
    double lat2Rad = point2.latitude * (pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Calculate total distance traveled from GPS trail
  double calculateTotalDistance(List<LocationPoint> gpsTrail) {
    if (gpsTrail.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < gpsTrail.length; i++) {
      totalDistance += calculateDistance(
        gpsTrail[i - 1].position,
        gpsTrail[i].position,
      );
    }
    
    return totalDistance;
  }
  
  /// Calculate average speed from GPS trail
  double calculateAverageSpeed(List<LocationPoint> gpsTrail) {
    if (gpsTrail.isEmpty) return 0.0;
    
    double totalSpeed = gpsTrail
        .map((point) => point.speed)
        .reduce((a, b) => a + b);
    
    return totalSpeed / gpsTrail.length;
  }
  
  /// Check if speed pattern is consistent with bus movement
  bool isSpeedConsistentWithBus(double avgSpeed, List<LocationPoint> gpsTrail) {
    // Bus characteristics:
    // - Average speed between 15-45 km/h
    // - Frequent stops (speed drops to 0-5 km/h)
    // - Regular acceleration/deceleration patterns
    
    if (avgSpeed < 15 || avgSpeed > 45) return false;
    
    if (gpsTrail.length < 10) return true; // Not enough data
    
    // Count stops (speed < 5 km/h for at least 2 consecutive readings)
    int stopCount = 0;
    bool inStop = false;
    
    for (var point in gpsTrail) {
      if (point.speed < 5) {
        if (!inStop) {
          stopCount++;
          inStop = true;
        }
      } else {
        inStop = false;
      }
    }
    
    // Expect at least 1 stop per 10 minutes for bus routes
    double journeyTimeMinutes = gpsTrail.last.timestamp
        .difference(gpsTrail.first.timestamp)
        .inMinutes
        .toDouble();
    
    double expectedStops = journeyTimeMinutes / 10;
    
    return stopCount >= (expectedStops * 0.5); // Allow some tolerance
  }
  
  /// Detect bus stops from GPS trail
  List<BusStop> detectBusStops(List<LocationPoint> gpsTrail, List<BusStop> knownStops) {
    List<BusStop> detectedStops = [];
    
    if (gpsTrail.length < 5) return detectedStops;
    
    // Find locations where the user stopped (speed < 5 km/h for 30+ seconds)
    List<LocationPoint> stopPoints = [];
    
    for (int i = 0; i < gpsTrail.length - 2; i++) {
      if (gpsTrail[i].speed < 5 && 
          gpsTrail[i + 1].speed < 5 && 
          gpsTrail[i + 2].speed < 5) {
        
        // Check if this stop lasted at least 30 seconds
        if (gpsTrail[i + 2].timestamp
            .difference(gpsTrail[i].timestamp)
            .inSeconds >= 30) {
          stopPoints.add(gpsTrail[i]);
        }
      }
    }
    
    // Match detected stops with known bus stops
    for (var stopPoint in stopPoints) {
      for (var knownStop in knownStops) {
        double distance = calculateDistance(stopPoint.position, knownStop.location);
        
        // If within 100 meters of a known bus stop, consider it a match
        if (distance <= 100) {
          detectedStops.add(knownStop);
          break;
        }
      }
    }
    
    return detectedStops;
  }
  
  /// Check if user is near destination
  bool isNearDestination(LatLng currentLocation, LatLng destination, {double radiusMeters = 100}) {
    double distance = calculateDistance(currentLocation, destination);
    return distance <= radiusMeters;
  }
  
  /// Calculate route deviation from expected path
  double calculateRouteDeviation(
    List<LocationPoint> gpsTrail, 
    LatLng source, 
    LatLng destination
  ) {
    if (gpsTrail.isEmpty) return 0.0;
    
    double maxDeviation = 0.0;
    
    // Simple linear route assumption - in production, use actual bus route data
    for (var point in gpsTrail) {
      // Calculate perpendicular distance from point to line between source and destination
      double deviation = _calculatePerpendicularDistance(
        point.position, 
        source, 
        destination
      );
      
      if (deviation > maxDeviation) {
        maxDeviation = deviation;
      }
    }
    
    return maxDeviation;
  }
  
  /// Calculate perpendicular distance from point to line
  double _calculatePerpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    // Simplified calculation - in production, use proper geometric formulas
    double distanceToStart = calculateDistance(point, lineStart);
    double distanceToEnd = calculateDistance(point, lineEnd);
    double lineLength = calculateDistance(lineStart, lineEnd);
    
    // Use triangle area formula to find perpendicular distance
    double s = (distanceToStart + distanceToEnd + lineLength) / 2;
    double area = s * (s - distanceToStart) * (s - distanceToEnd) * (s - lineLength);
    
    if (area <= 0) return 0.0;
    
    return (2 * area) / lineLength;
  }
  
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
  
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
