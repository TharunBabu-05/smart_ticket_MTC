import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TicketStatus { active, expired, completed, flagged }
enum TicketType { singleJourney, dayPass, monthlyPass }

class EnhancedTicket {
  final String ticketId;
  final String userId;
  final String sessionId; // For cross-platform communication
  final TicketType ticketType;
  final TicketStatus status;
  final DateTime issueTime;
  final DateTime validUntil;
  final String sourceName;
  final String destinationName;
  final LatLng sourceLocation;
  final LatLng destinationLocation;
  final double fare;
  final String qrCode;
  final bool locationTrackingEnabled;
  final Map<String, dynamic> metadata;

  EnhancedTicket({
    required this.ticketId,
    required this.userId,
    required this.sessionId,
    this.ticketType = TicketType.singleJourney,
    this.status = TicketStatus.active,
    required this.issueTime,
    required this.validUntil,
    required this.sourceName,
    required this.destinationName,
    required this.sourceLocation,
    required this.destinationLocation,
    required this.fare,
    required this.qrCode,
    this.locationTrackingEnabled = true,
    this.metadata = const {},
  });

  /// Check if ticket is currently valid
  bool get isValid {
    DateTime now = DateTime.now();
    return status == TicketStatus.active && 
           now.isBefore(validUntil) && 
           now.isAfter(issueTime);
  }

  /// Get remaining validity time
  Duration get remainingTime {
    DateTime now = DateTime.now();
    if (now.isAfter(validUntil)) {
      return Duration.zero;
    }
    return validUntil.difference(now);
  }

  /// Get formatted remaining time
  String get formattedRemainingTime {
    Duration remaining = remainingTime;
    if (remaining.isNegative || remaining == Duration.zero) {
      return 'Expired';
    }
    
    int hours = remaining.inHours;
    int minutes = remaining.inMinutes.remainder(60);
    int seconds = remaining.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get ticket validity percentage (for progress indicators)
  double get validityPercentage {
    Duration total = validUntil.difference(issueTime);
    Duration elapsed = DateTime.now().difference(issueTime);
    
    if (elapsed.isNegative) return 1.0;
    if (elapsed >= total) return 0.0;
    
    return 1.0 - (elapsed.inSeconds / total.inSeconds);
  }

  /// Create a copy with updated fields
  EnhancedTicket copyWith({
    String? ticketId,
    String? userId,
    String? sessionId,
    TicketType? ticketType,
    TicketStatus? status,
    DateTime? issueTime,
    DateTime? validUntil,
    String? sourceName,
    String? destinationName,
    LatLng? sourceLocation,
    LatLng? destinationLocation,
    double? fare,
    String? qrCode,
    bool? locationTrackingEnabled,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedTicket(
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      ticketType: ticketType ?? this.ticketType,
      status: status ?? this.status,
      issueTime: issueTime ?? this.issueTime,
      validUntil: validUntil ?? this.validUntil,
      sourceName: sourceName ?? this.sourceName,
      destinationName: destinationName ?? this.destinationName,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      fare: fare ?? this.fare,
      qrCode: qrCode ?? this.qrCode,
      locationTrackingEnabled: locationTrackingEnabled ?? this.locationTrackingEnabled,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'sessionId': sessionId,
      'ticketType': ticketType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'issueTime': issueTime.millisecondsSinceEpoch,
      'validUntil': validUntil.millisecondsSinceEpoch,
      'sourceName': sourceName,
      'destinationName': destinationName,
      'sourceLocation': {
        'latitude': sourceLocation.latitude,
        'longitude': sourceLocation.longitude,
      },
      'destinationLocation': {
        'latitude': destinationLocation.latitude,
        'longitude': destinationLocation.longitude,
      },
      'fare': fare,
      'qrCode': qrCode,
      'locationTrackingEnabled': locationTrackingEnabled,
      'metadata': metadata,
    };
  }

  /// Create from map (Firebase data)
  factory EnhancedTicket.fromMap(Map<String, dynamic> map) {
    return EnhancedTicket(
      ticketId: map['ticketId'] ?? '',
      userId: map['userId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      ticketType: TicketType.values.firstWhere(
        (type) => type.toString().split('.').last == map['ticketType'],
        orElse: () => TicketType.singleJourney,
      ),
      status: TicketStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => TicketStatus.active,
      ),
      issueTime: DateTime.fromMillisecondsSinceEpoch(map['issueTime'] ?? 0),
      validUntil: DateTime.fromMillisecondsSinceEpoch(map['validUntil'] ?? 0),
      sourceName: map['sourceName'] ?? '',
      destinationName: map['destinationName'] ?? '',
      sourceLocation: LatLng(
        map['sourceLocation']?['latitude'] ?? 0.0,
        map['sourceLocation']?['longitude'] ?? 0.0,
      ),
      destinationLocation: LatLng(
        map['destinationLocation']?['latitude'] ?? 0.0,
        map['destinationLocation']?['longitude'] ?? 0.0,
      ),
      fare: map['fare']?.toDouble() ?? 0.0,
      qrCode: map['qrCode'] ?? '',
      locationTrackingEnabled: map['locationTrackingEnabled'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'EnhancedTicket(ticketId: $ticketId, status: $status, valid: $isValid)';
  }
}

/// Penalty information for fraud detection
class PenaltyInfo {
  final String ticketId;
  final String sessionId;
  final String userId;
  final String reason;
  final double amount;
  final int extraStops;
  final String plannedExit;
  final String actualExit;
  final DateTime detectedAt;
  final bool isPaid;

  PenaltyInfo({
    required this.ticketId,
    required this.sessionId,
    required this.userId,
    required this.reason,
    required this.amount,
    required this.extraStops,
    required this.plannedExit,
    required this.actualExit,
    required this.detectedAt,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'sessionId': sessionId,
      'userId': userId,
      'reason': reason,
      'amount': amount,
      'extraStops': extraStops,
      'plannedExit': plannedExit,
      'actualExit': actualExit,
      'detectedAt': detectedAt.millisecondsSinceEpoch,
      'isPaid': isPaid,
    };
  }

  factory PenaltyInfo.fromMap(Map<String, dynamic> map) {
    return PenaltyInfo(
      ticketId: map['ticketId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      reason: map['reason'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      extraStops: map['extraStops'] ?? 0,
      plannedExit: map['plannedExit'] ?? '',
      actualExit: map['actualExit'] ?? '',
      detectedAt: DateTime.fromMillisecondsSinceEpoch(map['detectedAt'] ?? 0),
      isPaid: map['isPaid'] ?? false,
    );
  }
}
