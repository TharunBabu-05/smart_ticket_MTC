import 'package:cloud_firestore/cloud_firestore.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LatLng.fromMap(Map<String, dynamic> map) {
    return LatLng(
      map['latitude']?.toDouble() ?? 0.0,
      map['longitude']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

class LocationPoint {
  final LatLng position;
  final DateTime timestamp;
  final double speed;
  final double accuracy;
  
  LocationPoint({
    required this.position,
    required this.timestamp,
    required this.speed,
    required this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'position': position.toMap(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'speed': speed,
      'accuracy': accuracy,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      position: LatLng.fromMap(map['position']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      speed: map['speed']?.toDouble() ?? 0.0,
      accuracy: map['accuracy']?.toDouble() ?? 0.0,
    );
  }
}

class SensorReading {
  final DateTime timestamp;
  final double accelerometerX, accelerometerY, accelerometerZ;
  final double gyroscopeX, gyroscopeY, gyroscopeZ;
  final double calculatedSpeed;
  
  SensorReading({
    required this.timestamp,
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    required this.calculatedSpeed,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accelerometerX': accelerometerX,
      'accelerometerY': accelerometerY,
      'accelerometerZ': accelerometerZ,
      'gyroscopeX': gyroscopeX,
      'gyroscopeY': gyroscopeY,
      'gyroscopeZ': gyroscopeZ,
      'calculatedSpeed': calculatedSpeed,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      accelerometerX: map['accelerometerX']?.toDouble() ?? 0.0,
      accelerometerY: map['accelerometerY']?.toDouble() ?? 0.0,
      accelerometerZ: map['accelerometerZ']?.toDouble() ?? 0.0,
      gyroscopeX: map['gyroscopeX']?.toDouble() ?? 0.0,
      gyroscopeY: map['gyroscopeY']?.toDouble() ?? 0.0,
      gyroscopeZ: map['gyroscopeZ']?.toDouble() ?? 0.0,
      calculatedSpeed: map['calculatedSpeed']?.toDouble() ?? 0.0,
    );
  }
}

enum TripStatus { active, completed, flagged, verified }

class TripData {
  final String ticketId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final LatLng sourceLocation;
  final LatLng destinationLocation;
  final List<LocationPoint> gpsTrail;
  final List<SensorReading> sensorData;
  final TripStatus status;
  final double? fraudConfidence;
  final String? sourceName;
  final String? destinationName;

  TripData({
    required this.ticketId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.sourceLocation,
    required this.destinationLocation,
    this.gpsTrail = const [],
    this.sensorData = const [],
    this.status = TripStatus.active,
    this.fraudConfidence,
    this.sourceName,
    this.destinationName,
  });

  TripData copyWith({
    String? ticketId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    LatLng? sourceLocation,
    LatLng? destinationLocation,
    List<LocationPoint>? gpsTrail,
    List<SensorReading>? sensorData,
    TripStatus? status,
    double? fraudConfidence,
    String? sourceName,
    String? destinationName,
  }) {
    return TripData(
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      gpsTrail: gpsTrail ?? this.gpsTrail,
      sensorData: sensorData ?? this.sensorData,
      status: status ?? this.status,
      fraudConfidence: fraudConfidence ?? this.fraudConfidence,
      sourceName: sourceName ?? this.sourceName,
      destinationName: destinationName ?? this.destinationName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'sourceLocation': sourceLocation.toMap(),
      'destinationLocation': destinationLocation.toMap(),
      'gpsTrail': gpsTrail.map((point) => point.toMap()).toList(),
      'sensorData': sensorData.map((reading) => reading.toMap()).toList(),
      'status': status.toString().split('.').last,
      'fraudConfidence': fraudConfidence,
      'sourceName': sourceName,
      'destinationName': destinationName,
    };
  }

  factory TripData.fromMap(Map<String, dynamic> map) {
    return TripData(
      ticketId: map['ticketId'] ?? '',
      userId: map['userId'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      sourceLocation: LatLng.fromMap(map['sourceLocation']),
      destinationLocation: LatLng.fromMap(map['destinationLocation']),
      gpsTrail: (map['gpsTrail'] as List<dynamic>?)
          ?.map((point) => LocationPoint.fromMap(point))
          .toList() ?? [],
      sensorData: (map['sensorData'] as List<dynamic>?)
          ?.map((reading) => SensorReading.fromMap(reading))
          .toList() ?? [],
      status: TripStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => TripStatus.active,
      ),
      fraudConfidence: map['fraudConfidence']?.toDouble(),
      sourceName: map['sourceName'],
      destinationName: map['destinationName'],
    );
  }
}
