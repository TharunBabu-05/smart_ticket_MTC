import 'dart:math' as math;

class BusStop {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequence; // Add sequence property for route ordering

  BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.sequence = 0, // Default sequence
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lng']?.toString() ?? '0') ?? 0.0,
      sequence: json['sequence'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': latitude,
      'lng': longitude,
      'sequence': sequence,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
    };
  }

  factory BusStop.fromDbMap(Map<String, dynamic> map) {
    return BusStop(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      sequence: map['sequence'] ?? 0,
    );
  }

  // Calculate distance to another point in meters
  double distanceTo(double lat, double lng) {
    const double earthRadius = 6371000; // Earth's radius in meters
    double dLat = _toRadians(lat - latitude);
    double dLng = _toRadians(lng - longitude);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) * math.cos(_toRadians(lat)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
