import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceAspect {
  punctuality('Punctuality'),
  cleanliness('Cleanliness'),
  driverBehavior('Driver Behavior'),
  comfort('Comfort'),
  safety('Safety'),
  overall('Overall Experience');

  const ServiceAspect(this.displayName);
  final String displayName;
}

enum ReviewType {
  busService('Bus Service'),
  route('Route'),
  driver('Driver'),
  station('Station');

  const ReviewType(this.displayName);
  final String displayName;
}

enum SortOrder {
  newest('Newest First'),
  oldest('Oldest First'),
  highestRated('Highest Rated'),
  lowestRated('Lowest Rated'),
  mostHelpful('Most Helpful');

  const SortOrder(this.displayName);
  final String displayName;
}

class BusServiceRating {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String busNumber;
  final String routeId;
  final String routeName;
  final String driverId;
  final ReviewType reviewType;
  
  // Required properties for widgets
  final String serviceId; // Bus number, route ID, etc.
  final String comment; // Review text (alias for reviewText)
  final bool isVerified; // Alias for isVerifiedJourney
  final DateTime createdAt; // Alias for reviewDate
  final bool hasResponse; // Whether review has admin/authority response
  
  // Ratings (1-5 stars)
  final Map<ServiceAspect, double> aspectRatings; // Changed to double for consistency
  final double overallRating; // Changed to double for consistency
  
  // Review content
  final String reviewTitle;
  final String reviewText;
  final List<String> tags;
  final List<String> photos;
  
  // Metadata
  final DateTime journeyDate;
  final DateTime reviewDate;
  final String journeyTime;
  final String boardingPoint;
  final String alightingPoint;
  final bool isAnonymous;
  final bool isVerifiedJourney;
  
  // Engagement
  final int helpfulVotes;
  final int totalVotes;
  final List<String> reportedBy;
  final bool isModerated;
  final String? moderationNote;

  const BusServiceRating({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    this.driverId = '',
    required this.reviewType,
    required this.serviceId,
    required this.comment,
    this.isVerified = false,
    required this.createdAt,
    this.hasResponse = false,
    required this.aspectRatings,
    required this.overallRating,
    required this.reviewTitle,
    required this.reviewText,
    required this.tags,
    required this.photos,
    required this.journeyDate,
    required this.reviewDate,
    required this.journeyTime,
    required this.boardingPoint,
    required this.alightingPoint,
    this.isAnonymous = false,
    this.isVerifiedJourney = false,
    this.helpfulVotes = 0,
    this.totalVotes = 0,
    this.reportedBy = const [],
    this.isModerated = false,
    this.moderationNote,
  });

  factory BusServiceRating.fromMap(Map<String, dynamic> map) {
    return BusServiceRating(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      busNumber: map['busNumber'] ?? '',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      driverId: map['driverId'] ?? '',
      reviewType: ReviewType.values[map['reviewType'] ?? 0],
      serviceId: map['serviceId'] ?? map['busNumber'] ?? '',
      comment: map['comment'] ?? map['reviewText'] ?? '',
      isVerified: map['isVerified'] ?? map['isVerifiedJourney'] ?? false,
      createdAt: (map['createdAt'] ?? map['reviewDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasResponse: map['hasResponse'] ?? false,
      aspectRatings: Map<ServiceAspect, double>.from(
        (map['aspectRatings'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            ServiceAspect.values[int.parse(key)],
            (value as num).toDouble(),
          ),
        ),
      ),
      overallRating: (map['overallRating'] ?? 0).toDouble(),
      reviewTitle: map['reviewTitle'] ?? '',
      reviewText: map['reviewText'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      photos: List<String>.from(map['photos'] ?? []),
      journeyDate: (map['journeyDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewDate: (map['reviewDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      journeyTime: map['journeyTime'] ?? '',
      boardingPoint: map['boardingPoint'] ?? '',
      alightingPoint: map['alightingPoint'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      isVerifiedJourney: map['isVerifiedJourney'] ?? false,
      helpfulVotes: map['helpfulVotes'] ?? 0,
      totalVotes: map['totalVotes'] ?? 0,
      reportedBy: List<String>.from(map['reportedBy'] ?? []),
      isModerated: map['isModerated'] ?? false,
      moderationNote: map['moderationNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'busNumber': busNumber,
      'routeId': routeId,
      'routeName': routeName,
      'driverId': driverId,
      'reviewType': reviewType.index,
      'serviceId': serviceId,
      'comment': comment,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'hasResponse': hasResponse,
      'aspectRatings': aspectRatings.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
      'overallRating': overallRating,
      'reviewTitle': reviewTitle,
      'reviewText': reviewText,
      'tags': tags,
      'photos': photos,
      'journeyDate': Timestamp.fromDate(journeyDate),
      'reviewDate': Timestamp.fromDate(reviewDate),
      'journeyTime': journeyTime,
      'boardingPoint': boardingPoint,
      'alightingPoint': alightingPoint,
      'isAnonymous': isAnonymous,
      'isVerifiedJourney': isVerifiedJourney,
      'helpfulVotes': helpfulVotes,
      'totalVotes': totalVotes,
      'reportedBy': reportedBy,
      'isModerated': isModerated,
      'moderationNote': moderationNote,
    };
  }

  BusServiceRating copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? busNumber,
    String? routeId,
    String? routeName,
    String? driverId,
    ReviewType? reviewType,
    String? serviceId,
    String? comment,
    bool? isVerified,
    DateTime? createdAt,
    bool? hasResponse,
    Map<ServiceAspect, double>? aspectRatings,
    double? overallRating,
    String? reviewTitle,
    String? reviewText,
    List<String>? tags,
    List<String>? photos,
    DateTime? journeyDate,
    DateTime? reviewDate,
    String? journeyTime,
    String? boardingPoint,
    String? alightingPoint,
    bool? isAnonymous,
    bool? isVerifiedJourney,
    int? helpfulVotes,
    int? totalVotes,
    List<String>? reportedBy,
    bool? isModerated,
    String? moderationNote,
  }) {
    return BusServiceRating(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      busNumber: busNumber ?? this.busNumber,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      driverId: driverId ?? this.driverId,
      reviewType: reviewType ?? this.reviewType,
      serviceId: serviceId ?? this.serviceId,
      comment: comment ?? this.comment,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      hasResponse: hasResponse ?? this.hasResponse,
      aspectRatings: aspectRatings ?? this.aspectRatings,
      overallRating: overallRating ?? this.overallRating,
      reviewTitle: reviewTitle ?? this.reviewTitle,
      reviewText: reviewText ?? this.reviewText,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      journeyDate: journeyDate ?? this.journeyDate,
      reviewDate: reviewDate ?? this.reviewDate,
      journeyTime: journeyTime ?? this.journeyTime,
      boardingPoint: boardingPoint ?? this.boardingPoint,
      alightingPoint: alightingPoint ?? this.alightingPoint,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVerifiedJourney: isVerifiedJourney ?? this.isVerifiedJourney,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      totalVotes: totalVotes ?? this.totalVotes,
      reportedBy: reportedBy ?? this.reportedBy,
      isModerated: isModerated ?? this.isModerated,
      moderationNote: moderationNote ?? this.moderationNote,
    );
  }

  double get helpfulnessRatio => totalVotes > 0 ? helpfulVotes / totalVotes : 0.0;
  
  bool get isHighlyRated => overallRating >= 4.0;
  
  bool get isDetailed => comment.length > 50;
  
  List<ServiceAspect> get lowRatedAspects => 
      aspectRatings.entries.where((entry) => entry.value <= 2.0).map((e) => e.key).toList();
      
  List<ServiceAspect> get highRatedAspects => 
      aspectRatings.entries.where((entry) => entry.value >= 4.0).map((e) => e.key).toList();
}

class ServiceMetrics {
  final String serviceId;
  final String serviceName;
  final ReviewType serviceType;
  
  // Overall statistics
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star -> count
  final Map<ServiceAspect, double> aspectAverages;
  
  // Recent trends
  final double recentTrend; // -1 to 1, positive means improving
  final int reviewsThisMonth;
  final double thisMonthAverage;
  final double lastMonthAverage;
  
  // Quality indicators
  final int verifiedReviewsCount;
  final double verifiedAverage;
  final List<String> commonTags;
  final List<String> improvementAreas;
  final List<String> strengths;
  
  // Time-based metrics
  final Map<String, double> timeSlotRatings; // "morning", "afternoon", etc.
  final Map<String, double> dayOfWeekRatings;
  final Map<String, double> monthlyTrends;

  const ServiceMetrics({
    required this.serviceId,
    required this.serviceName,
    required this.serviceType,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.aspectAverages,
    this.recentTrend = 0.0,
    this.reviewsThisMonth = 0,
    this.thisMonthAverage = 0.0,
    this.lastMonthAverage = 0.0,
    this.verifiedReviewsCount = 0,
    this.verifiedAverage = 0.0,
    this.commonTags = const [],
    this.improvementAreas = const [],
    this.strengths = const [],
    this.timeSlotRatings = const {},
    this.dayOfWeekRatings = const {},
    this.monthlyTrends = const {},
  });

  factory ServiceMetrics.fromMap(Map<String, dynamic> map) {
    return ServiceMetrics(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceType: ReviewType.values[map['serviceType'] ?? 0],
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(map['ratingDistribution'] ?? {}),
      aspectAverages: Map<ServiceAspect, double>.from(
        (map['aspectAverages'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            ServiceAspect.values[int.parse(key)],
            (value as num).toDouble(),
          ),
        ),
      ),
      recentTrend: (map['recentTrend'] ?? 0.0).toDouble(),
      reviewsThisMonth: map['reviewsThisMonth'] ?? 0,
      thisMonthAverage: (map['thisMonthAverage'] ?? 0.0).toDouble(),
      lastMonthAverage: (map['lastMonthAverage'] ?? 0.0).toDouble(),
      verifiedReviewsCount: map['verifiedReviewsCount'] ?? 0,
      verifiedAverage: (map['verifiedAverage'] ?? 0.0).toDouble(),
      commonTags: List<String>.from(map['commonTags'] ?? []),
      improvementAreas: List<String>.from(map['improvementAreas'] ?? []),
      strengths: List<String>.from(map['strengths'] ?? []),
      timeSlotRatings: Map<String, double>.from(
        (map['timeSlotRatings'] ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      dayOfWeekRatings: Map<String, double>.from(
        (map['dayOfWeekRatings'] ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      monthlyTrends: Map<String, double>.from(
        (map['monthlyTrends'] ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceType': serviceType.index,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'aspectAverages': aspectAverages.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
      'recentTrend': recentTrend,
      'reviewsThisMonth': reviewsThisMonth,
      'thisMonthAverage': thisMonthAverage,
      'lastMonthAverage': lastMonthAverage,
      'verifiedReviewsCount': verifiedReviewsCount,
      'verifiedAverage': verifiedAverage,
      'commonTags': commonTags,
      'improvementAreas': improvementAreas,
      'strengths': strengths,
      'timeSlotRatings': timeSlotRatings,
      'dayOfWeekRatings': dayOfWeekRatings,
      'monthlyTrends': monthlyTrends,
    };
  }

  bool get isExcellent => averageRating >= 4.5;
  bool get isGood => averageRating >= 3.5 && averageRating < 4.5;
  bool get isAverage => averageRating >= 2.5 && averageRating < 3.5;
  bool get isPoor => averageRating < 2.5;
  
  bool get isImproving => recentTrend > 0.1;
  bool get isDeclining => recentTrend < -0.1;
  
  String get qualityLabel {
    if (isExcellent) return 'Excellent';
    if (isGood) return 'Good';
    if (isAverage) return 'Average';
    return 'Needs Improvement';
  }
  
  ServiceAspect? get strongestAspect {
    if (aspectAverages.isEmpty) return null;
    return aspectAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
  
  ServiceAspect? get weakestAspect {
    if (aspectAverages.isEmpty) return null;
    return aspectAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  ServiceMetrics copyWith({
    String? serviceId,
    String? serviceName,
    ReviewType? serviceType,
    double? averageRating,
    int? totalReviews,
    Map<int, int>? ratingDistribution,
    Map<ServiceAspect, double>? aspectAverages,
    double? recentTrend,
    int? reviewsThisMonth,
    double? thisMonthAverage,
    double? lastMonthAverage,
    int? verifiedReviewsCount,
    double? verifiedAverage,
    List<String>? commonTags,
    List<String>? improvementAreas,
    List<String>? strengths,
    Map<String, double>? timeSlotRatings,
    Map<String, double>? dayOfWeekRatings,
    Map<String, double>? monthlyTrends,
  }) {
    return ServiceMetrics(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceType: serviceType ?? this.serviceType,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      aspectAverages: aspectAverages ?? this.aspectAverages,
      recentTrend: recentTrend ?? this.recentTrend,
      reviewsThisMonth: reviewsThisMonth ?? this.reviewsThisMonth,
      thisMonthAverage: thisMonthAverage ?? this.thisMonthAverage,
      lastMonthAverage: lastMonthAverage ?? this.lastMonthAverage,
      verifiedReviewsCount: verifiedReviewsCount ?? this.verifiedReviewsCount,
      verifiedAverage: verifiedAverage ?? this.verifiedAverage,
      commonTags: commonTags ?? this.commonTags,
      improvementAreas: improvementAreas ?? this.improvementAreas,
      strengths: strengths ?? this.strengths,
      timeSlotRatings: timeSlotRatings ?? this.timeSlotRatings,
      dayOfWeekRatings: dayOfWeekRatings ?? this.dayOfWeekRatings,
      monthlyTrends: monthlyTrends ?? this.monthlyTrends,
    );
  }
}