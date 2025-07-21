enum TransportMode { bus, bike, car, walking, unknown }

enum FraudRecommendation { 
  noAction, 
  warning, 
  minorPenalty, 
  majorPenalty, 
  investigate 
}

class FraudAnalysis {
  final double fraudConfidence;
  final TransportMode detectedTransportMode;
  final bool speedAnalysis;
  final bool stopAnalysis;
  final double routeDeviation;
  final FraudRecommendation recommendation;
  final List<String> detectedIssues;
  final DateTime analysisTime;
  
  FraudAnalysis({
    required this.fraudConfidence,
    required this.detectedTransportMode,
    required this.speedAnalysis,
    required this.stopAnalysis,
    required this.routeDeviation,
    required this.recommendation,
    this.detectedIssues = const [],
    DateTime? analysisTime,
  }) : analysisTime = analysisTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'fraudConfidence': fraudConfidence,
      'detectedTransportMode': detectedTransportMode.toString().split('.').last,
      'speedAnalysis': speedAnalysis,
      'stopAnalysis': stopAnalysis,
      'routeDeviation': routeDeviation,
      'recommendation': recommendation.toString().split('.').last,
      'detectedIssues': detectedIssues,
      'analysisTime': analysisTime.millisecondsSinceEpoch,
    };
  }

  factory FraudAnalysis.fromMap(Map<String, dynamic> map) {
    return FraudAnalysis(
      fraudConfidence: map['fraudConfidence']?.toDouble() ?? 0.0,
      detectedTransportMode: TransportMode.values.firstWhere(
        (mode) => mode.toString().split('.').last == map['detectedTransportMode'],
        orElse: () => TransportMode.unknown,
      ),
      speedAnalysis: map['speedAnalysis'] ?? false,
      stopAnalysis: map['stopAnalysis'] ?? false,
      routeDeviation: map['routeDeviation']?.toDouble() ?? 0.0,
      recommendation: FraudRecommendation.values.firstWhere(
        (rec) => rec.toString().split('.').last == map['recommendation'],
        orElse: () => FraudRecommendation.noAction,
      ),
      detectedIssues: List<String>.from(map['detectedIssues'] ?? []),
      analysisTime: DateTime.fromMillisecondsSinceEpoch(
        map['analysisTime'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  String get fraudRiskLevel {
    if (fraudConfidence < 0.3) return 'Low';
    if (fraudConfidence < 0.6) return 'Medium';
    if (fraudConfidence < 0.8) return 'High';
    return 'Critical';
  }

  String get recommendationDescription {
    switch (recommendation) {
      case FraudRecommendation.noAction:
        return 'No action required - legitimate journey';
      case FraudRecommendation.warning:
        return 'Send warning to user about proper ticket usage';
      case FraudRecommendation.minorPenalty:
        return 'Apply minor penalty (₹10-20)';
      case FraudRecommendation.majorPenalty:
        return 'Apply major penalty (₹50-100)';
      case FraudRecommendation.investigate:
        return 'Flag for manual investigation by conductor';
    }
  }
}

class FraudAlert {
  final String alertId;
  final String tripId;
  final String userId;
  final double fraudConfidence;
  final List<String> detectedIssues;
  final FraudAlertStatus status;
  final DateTime createdAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolution;

  FraudAlert({
    required this.alertId,
    required this.tripId,
    required this.userId,
    required this.fraudConfidence,
    required this.detectedIssues,
    this.status = FraudAlertStatus.pending,
    DateTime? createdAt,
    this.resolvedBy,
    this.resolvedAt,
    this.resolution,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'tripId': tripId,
      'userId': userId,
      'fraudConfidence': fraudConfidence,
      'detectedIssues': detectedIssues,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'resolution': resolution,
    };
  }

  factory FraudAlert.fromMap(Map<String, dynamic> map) {
    return FraudAlert(
      alertId: map['alertId'] ?? '',
      tripId: map['tripId'] ?? '',
      userId: map['userId'] ?? '',
      fraudConfidence: map['fraudConfidence']?.toDouble() ?? 0.0,
      detectedIssues: List<String>.from(map['detectedIssues'] ?? []),
      status: FraudAlertStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => FraudAlertStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      resolvedBy: map['resolvedBy'],
      resolvedAt: map['resolvedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['resolvedAt'])
          : null,
      resolution: map['resolution'],
    );
  }
}

enum FraudAlertStatus { pending, resolved, falsePositive, escalated }
