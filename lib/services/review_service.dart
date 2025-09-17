import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/rating_model.dart';

class ReviewService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _ratingsCollection = 'bus_ratings';
  static const String _metricsCollection = 'service_metrics';

  // Local cache
  List<BusServiceRating> _recentReviews = [];
  Map<String, ServiceMetrics> _serviceMetrics = {};
  Map<String, List<BusServiceRating>> _reviewsCache = {};

  // Getters
  List<BusServiceRating> get recentReviews => _recentReviews;
  Map<String, ServiceMetrics> get serviceMetrics => _serviceMetrics;

  /// Submit a new rating and review
  Future<bool> submitReview(BusServiceRating rating) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create rating document
      final ratingWithUser = rating.copyWith(
        id: _firestore.collection(_ratingsCollection).doc().id,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userAvatar: user.photoURL ?? '',
        reviewDate: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection(_ratingsCollection)
          .doc(ratingWithUser.id)
          .set(ratingWithUser.toMap());

      // Update local cache
      _recentReviews.insert(0, ratingWithUser);
      _addToReviewsCache(ratingWithUser);

      // Update service metrics
      await _updateServiceMetrics(ratingWithUser);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return false;
    }
  }

  /// Get reviews for a specific service (bus/route/driver)
  Future<List<BusServiceRating>> getServiceReviews({
    required String serviceId,
    required ReviewType type,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy,
    String? lastDocumentId,
    String? searchQuery,
    List<ServiceAspect>? filterAspects,
    double? minRating,
  }) async {
    try {
      final cacheKey = '${type.name}_$serviceId';
      
      // Return cached data if available (only if no filters applied)
      if (_reviewsCache.containsKey(cacheKey) && 
          startAfter == null && 
          searchQuery == null && 
          filterAspects == null && 
          minRating == null) {
        return _reviewsCache[cacheKey]!;
      }

      Query query = _firestore
          .collection(_ratingsCollection)
          .where('reviewType', isEqualTo: type.index)
          .orderBy('reviewDate', descending: true)
          .limit(limit);

      // Add service-specific filter
      switch (type) {
        case ReviewType.busService:
          query = query.where('busNumber', isEqualTo: serviceId);
          break;
        case ReviewType.route:
          query = query.where('routeId', isEqualTo: serviceId);
          break;
        case ReviewType.driver:
          query = query.where('driverId', isEqualTo: serviceId);
          break;
        case ReviewType.station:
          query = query.where('boardingPoint', isEqualTo: serviceId);
          break;
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final reviews = snapshot.docs
          .map((doc) => BusServiceRating.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Cache the results
      if (startAfter == null) {
        _reviewsCache[cacheKey] = reviews;
      }

      return reviews;
    } catch (e) {
      debugPrint('Error getting service reviews: $e');
      return [];
    }
  }

  /// Get recent reviews across all services
  Future<List<BusServiceRating>> getRecentReviews({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_ratingsCollection)
          .orderBy('reviewDate', descending: true)
          .limit(limit)
          .get();

      _recentReviews = snapshot.docs
          .map((doc) => BusServiceRating.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      notifyListeners();
      return _recentReviews;
    } catch (e) {
      debugPrint('Error getting recent reviews: $e');
      return [];
    }
  }

  /// Get reviews by current user
  Future<List<BusServiceRating>> getUserReviews() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_ratingsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('reviewDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BusServiceRating.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting user reviews: $e');
      return [];
    }
  }

  /// Get service metrics
  Future<ServiceMetrics?> getServiceMetrics(String serviceId, ReviewType type) async {
    try {
      final cacheKey = '${type.name}_$serviceId';
      
      // Return cached metrics if available
      if (_serviceMetrics.containsKey(cacheKey)) {
        return _serviceMetrics[cacheKey];
      }

      final doc = await _firestore
          .collection(_metricsCollection)
          .doc(cacheKey)
          .get();

      if (doc.exists) {
        final metrics = ServiceMetrics.fromMap(doc.data() as Map<String, dynamic>);
        _serviceMetrics[cacheKey] = metrics;
        return metrics;
      }

      // If no metrics exist, calculate them
      return await _calculateServiceMetrics(serviceId, type);
    } catch (e) {
      debugPrint('Error getting service metrics: $e');
      return null;
    }
  }

  /// Vote on review helpfulness
  Future<bool> voteOnReview(String reviewId, bool isHelpful) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final reviewDoc = _firestore.collection(_ratingsCollection).doc(reviewId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reviewDoc);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final rating = BusServiceRating.fromMap(data);
        
        // Update vote counts
        final updatedRating = rating.copyWith(
          helpfulVotes: isHelpful ? rating.helpfulVotes + 1 : rating.helpfulVotes,
          totalVotes: rating.totalVotes + 1,
        );

        transaction.update(reviewDoc, updatedRating.toMap());
      });

      return true;
    } catch (e) {
      debugPrint('Error voting on review: $e');
      return false;
    }
  }

  /// Report a review
  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection(_ratingsCollection).doc(reviewId).update({
        'reportedBy': FieldValue.arrayUnion([user.uid]),
        'reportReason': reason,
      });

      return true;
    } catch (e) {
      debugPrint('Error reporting review: $e');
      return false;
    }
  }

  /// Search reviews
  Future<List<BusServiceRating>> searchReviews({
    required String query,
    ReviewType? type,
    int? minRating,
    int? maxRating,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection(_ratingsCollection);

      // Add filters
      if (type != null) {
        firestoreQuery = firestoreQuery.where('reviewType', isEqualTo: type.index);
      }

      if (minRating != null) {
        firestoreQuery = firestoreQuery.where('overallRating', isGreaterThanOrEqualTo: minRating);
      }

      if (maxRating != null) {
        firestoreQuery = firestoreQuery.where('overallRating', isLessThanOrEqualTo: maxRating);
      }

      if (startDate != null) {
        firestoreQuery = firestoreQuery.where('reviewDate', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        firestoreQuery = firestoreQuery.where('reviewDate', isLessThanOrEqualTo: endDate);
      }

      firestoreQuery = firestoreQuery
          .orderBy('reviewDate', descending: true)
          .limit(limit);

      final snapshot = await firestoreQuery.get();
      final allReviews = snapshot.docs
          .map((doc) => BusServiceRating.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by text query (client-side since Firestore doesn't support full-text search)
      if (query.isNotEmpty) {
        final searchTerms = query.toLowerCase().split(' ');
        return allReviews.where((review) {
          final searchableText = '${review.reviewTitle} ${review.reviewText} ${review.busNumber} ${review.routeName}'.toLowerCase();
          return searchTerms.any((term) => searchableText.contains(term));
        }).toList();
      }

      return allReviews;
    } catch (e) {
      debugPrint('Error searching reviews: $e');
      return [];
    }
  }

  /// Get top-rated services
  Future<List<ServiceMetrics>> getTopRatedServices({
    required ReviewType type,
    int limit = 10,
    int minReviews = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_metricsCollection)
          .where('serviceType', isEqualTo: type.index)
          .where('totalReviews', isGreaterThanOrEqualTo: minReviews)
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ServiceMetrics.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting top-rated services: $e');
      return [];
    }
  }

  /// Update an existing review
  Future<bool> updateReview(BusServiceRating updatedRating) async {
    try {
      await _firestore
          .collection(_ratingsCollection)
          .doc(updatedRating.id)
          .update(updatedRating.toMap());

      // Update caches
      final serviceId = _getServiceId(updatedRating);
      final cacheKey = '${updatedRating.reviewType.name}_$serviceId';
      
      if (_reviewsCache.containsKey(cacheKey)) {
        final reviews = _reviewsCache[cacheKey]!;
        final index = reviews.indexWhere((r) => r.id == updatedRating.id);
        if (index >= 0) {
          reviews[index] = updatedRating;
        }
      }

      final recentIndex = _recentReviews.indexWhere((r) => r.id == updatedRating.id);
      if (recentIndex >= 0) {
        _recentReviews[recentIndex] = updatedRating;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_ratingsCollection).doc(reviewId).delete();

      // Remove from caches
      _recentReviews.removeWhere((r) => r.id == reviewId);
      
      for (final entry in _reviewsCache.entries) {
        entry.value.removeWhere((r) => r.id == reviewId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Private method to update service metrics
  Future<void> _updateServiceMetrics(BusServiceRating rating) async {
    try {
      final serviceId = _getServiceId(rating);
      final cacheKey = '${rating.reviewType.name}_$serviceId';
      
      await _firestore.runTransaction((transaction) async {
        final metricsDoc = _firestore.collection(_metricsCollection).doc(cacheKey);
        final snapshot = await transaction.get(metricsDoc);
        
        ServiceMetrics metrics;
        if (snapshot.exists) {
          metrics = ServiceMetrics.fromMap(snapshot.data() as Map<String, dynamic>);
        } else {
          metrics = ServiceMetrics(
            serviceId: serviceId,
            serviceName: _getServiceName(rating),
            serviceType: rating.reviewType,
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            aspectAverages: {},
          );
        }

        // Update metrics with new rating
        final updatedMetrics = _calculateUpdatedMetrics(metrics, rating);
        transaction.set(metricsDoc, updatedMetrics.toMap());
        
        // Update cache
        _serviceMetrics[cacheKey] = updatedMetrics;
      });
    } catch (e) {
      debugPrint('Error updating service metrics: $e');
    }
  }

  /// Private method to calculate updated metrics
  ServiceMetrics _calculateUpdatedMetrics(ServiceMetrics current, BusServiceRating newRating) {
    final totalReviews = current.totalReviews + 1;
    final newAverage = ((current.averageRating * current.totalReviews) + newRating.overallRating) / totalReviews;
    
    // Update rating distribution
    final newDistribution = Map<int, int>.from(current.ratingDistribution);
    final roundedRating = newRating.overallRating.round();
    newDistribution[roundedRating] = (newDistribution[roundedRating] ?? 0) + 1;
    
    // Update aspect averages
    final newAspectAverages = Map<ServiceAspect, double>.from(current.aspectAverages);
    for (final entry in newRating.aspectRatings.entries) {
      final currentAverage = newAspectAverages[entry.key] ?? 0.0;
      final currentCount = current.totalReviews > 0 ? current.totalReviews : 1;
      newAspectAverages[entry.key] = ((currentAverage * currentCount) + entry.value) / totalReviews;
    }

    return current.copyWith(
      averageRating: newAverage,
      totalReviews: totalReviews,
      ratingDistribution: newDistribution,
      aspectAverages: newAspectAverages,
    );
  }

  /// Private method to calculate metrics from scratch
  Future<ServiceMetrics?> _calculateServiceMetrics(String serviceId, ReviewType type) async {
    try {
      final reviews = await getServiceReviews(serviceId: serviceId, type: type, limit: 1000);
      
      if (reviews.isEmpty) return null;

      final totalReviews = reviews.length;
      final averageRating = reviews.map((r) => r.overallRating).reduce((a, b) => a + b) / totalReviews;
      
      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final review in reviews) {
        final roundedRating = review.overallRating.round();
        ratingDistribution[roundedRating] = (ratingDistribution[roundedRating] ?? 0) + 1;
      }

      final aspectTotals = <ServiceAspect, double>{};
      final aspectCounts = <ServiceAspect, int>{};
      
      for (final review in reviews) {
        for (final entry in review.aspectRatings.entries) {
          aspectTotals[entry.key] = (aspectTotals[entry.key] ?? 0) + entry.value;
          aspectCounts[entry.key] = (aspectCounts[entry.key] ?? 0) + 1;
        }
      }

      final aspectAverages = <ServiceAspect, double>{};
      for (final aspect in aspectTotals.keys) {
        aspectAverages[aspect] = aspectTotals[aspect]! / aspectCounts[aspect]!;
      }

      final metrics = ServiceMetrics(
        serviceId: serviceId,
        serviceName: _getServiceName(reviews.first),
        serviceType: type,
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        aspectAverages: aspectAverages,
      );

      // Cache and save metrics
      final cacheKey = '${type.name}_$serviceId';
      _serviceMetrics[cacheKey] = metrics;
      await _firestore.collection(_metricsCollection).doc(cacheKey).set(metrics.toMap());

      return metrics;
    } catch (e) {
      debugPrint('Error calculating service metrics: $e');
      return null;
    }
  }

  /// Helper methods
  void _addToReviewsCache(BusServiceRating rating) {
    final serviceId = _getServiceId(rating);
    final cacheKey = '${rating.reviewType.name}_$serviceId';
    
    if (_reviewsCache.containsKey(cacheKey)) {
      _reviewsCache[cacheKey]!.insert(0, rating);
    }
  }

  String _getServiceId(BusServiceRating rating) {
    switch (rating.reviewType) {
      case ReviewType.busService:
        return rating.busNumber;
      case ReviewType.route:
        return rating.routeId;
      case ReviewType.driver:
        return rating.driverId;
      case ReviewType.station:
        return rating.boardingPoint;
    }
  }

  String _getServiceName(BusServiceRating rating) {
    switch (rating.reviewType) {
      case ReviewType.busService:
        return 'Bus ${rating.busNumber}';
      case ReviewType.route:
        return rating.routeName;
      case ReviewType.driver:
        return 'Driver ${rating.driverId}';
      case ReviewType.station:
        return rating.boardingPoint;
    }
  }

  /// Clear cache
  void clearCache() {
    _reviewsCache.clear();
    _serviceMetrics.clear();
    _recentReviews.clear();
    notifyListeners();
  }
}

extension ServiceMetricsCopyWith on ServiceMetrics {
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