import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_data_model.dart';
import '../models/fraud_analysis_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Uuid _uuid = Uuid();

  // Collections
  static const String _tripsCollection = 'trips';
  static const String _fraudAlertsCollection = 'fraudAlerts';
  static const String _usersCollection = 'users';
  static const String _busStopsCollection = 'busStops';

  /// Save trip data to Firestore
  static Future<void> saveTripData(TripData tripData, [FraudAnalysis? analysis]) async {
    try {
      if (_firestore == null) {
        print('Firebase not initialized - skipping trip data save');
        return;
      }
      
      Map<String, dynamic> data = tripData.toMap();
      
      if (analysis != null) {
        data['fraudAnalysis'] = analysis.toMap();
      }
      
      await _firestore!
          .collection(_tripsCollection)
          .doc(tripData.ticketId)
          .set(data, SetOptions(merge: true));
      
      print('Trip data saved successfully');
    } catch (e) {
      print('Error saving trip data: $e');
      throw e;
    }
  }

  /// Get trip data from Firestore
  static Future<TripData?> getTripData(String ticketId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_tripsCollection)
          .doc(ticketId)
          .get();
      
      if (doc.exists) {
        return TripData.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting trip data: $e');
      return null;
    }
  }

  /// Create fraud alert
  static Future<void> createFraudAlert(FraudAlert alert) async {
    try {
      await _firestore
          .collection(_fraudAlertsCollection)
          .doc(alert.alertId)
          .set(alert.toMap());
      
      print('Fraud alert created successfully');
    } catch (e) {
      print('Error creating fraud alert: $e');
      throw e;
    }
  }

  /// Get fraud alerts for conductor dashboard
  static Stream<List<FraudAlert>> getFraudAlertsStream() {
    return _firestore
        .collection(_fraudAlertsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FraudAlert.fromMap(doc.data()))
          .toList();
    });
  }

  /// Update fraud alert status
  static Future<void> updateFraudAlert(
    String alertId, 
    FraudAlertStatus status, 
    {String? resolvedBy, String? resolution}
  ) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.toString().split('.').last,
        'resolvedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (resolvedBy != null) updateData['resolvedBy'] = resolvedBy;
      if (resolution != null) updateData['resolution'] = resolution;
      
      await _firestore
          .collection(_fraudAlertsCollection)
          .doc(alertId)
          .update(updateData);
      
      print('Fraud alert updated successfully');
    } catch (e) {
      print('Error updating fraud alert: $e');
      throw e;
    }
  }

  /// Save user trip history
  static Future<void> saveUserTripHistory(String userId, TripData tripData) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('tripHistory')
          .doc(tripData.ticketId)
          .set({
        'ticketId': tripData.ticketId,
        'startTime': tripData.startTime.millisecondsSinceEpoch,
        'endTime': tripData.endTime?.millisecondsSinceEpoch,
        'sourceName': tripData.sourceName,
        'destinationName': tripData.destinationName,
        'status': tripData.status.toString().split('.').last,
        'fraudConfidence': tripData.fraudConfidence,
      });
    } catch (e) {
      print('Error saving user trip history: $e');
    }
  }

  /// Get user's active trips
  static Future<List<TripData>> getUserActiveTrips(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_tripsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('startTime', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => TripData.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user active trips: $e');
      return [];
    }
  }

  /// Expire ticket (simplified version)
  static Future<void> expireTicket(String ticketId) async {
    try {
      await updateTripStatus(ticketId, TripStatus.completed);
      print('Ticket expired: $ticketId');
    } catch (e) {
      print('Error expiring ticket: $e');
    }
  }

  /// Get streaming status (simplified)
  static bool get isStreaming => false; // Simplified for now
  static String? get currentStreamingTicket => null; // Simplified for now

  /// Get user trip history
  static Future<List<TripData>> getUserTripHistory(String userId, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('tripHistory')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();
      
      List<TripData> trips = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        String ticketId = data != null && data['ticketId'] != null 
            ? data['ticketId'] 
            : doc.id;
        TripData? tripData = await getTripData(ticketId);
        if (tripData != null) {
          trips.add(tripData);
        }
      }
      
      return trips;
    } catch (e) {
      print('Error getting user trip history: $e');
      return [];
    }
  }

  /// Save bus stops data
  static Future<void> saveBusStops(List<BusStop> busStops) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var stop in busStops) {
        DocumentReference docRef = _firestore
            .collection(_busStopsCollection)
            .doc(stop.id);
        batch.set(docRef, stop.toMap());
      }
      
      await batch.commit();
      print('Bus stops saved successfully');
    } catch (e) {
      print('Error saving bus stops: $e');
      throw e;
    }
  }

  /// Get bus stops
  static Future<List<BusStop>> getBusStops() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_busStopsCollection)
          .orderBy('sequence')
          .get();
      
      return snapshot.docs
          .map((doc) => BusStop.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting bus stops: $e');
      return [];
    }
  }

  /// Real-time trip monitoring for conductors
  static Stream<List<TripData>> getActiveTripStream() {
    return _firestore
        .collection(_tripsCollection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TripData.fromMap(doc.data()))
          .toList();
    });
  }

  /// Update trip status
  static Future<void> updateTripStatus(String ticketId, TripStatus status) async {
    try {
      await _firestore
          .collection(_tripsCollection)
          .doc(ticketId)
          .update({
        'status': status.toString().split('.').last,
        'endTime': status == TripStatus.completed 
            ? DateTime.now().millisecondsSinceEpoch 
            : null,
      });
    } catch (e) {
      print('Error updating trip status: $e');
      throw e;
    }
  }

  /// Generate unique IDs
  static String generateTicketId() => _uuid.v4();
  static String generateAlertId() => _uuid.v4();

  /// Analytics and reporting
  static Future<Map<String, dynamic>> getFraudStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_fraudAlertsCollection);
      
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      int totalAlerts = snapshot.docs.length;
      int resolvedAlerts = 0;
      int falsePositives = 0;
      double avgConfidence = 0.0;
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        String status = data['status'] ?? '';
        if (status == 'resolved') resolvedAlerts++;
        if (status == 'falsePositive') falsePositives++;
        
        avgConfidence += (data['fraudConfidence'] ?? 0.0);
      }
      
      if (totalAlerts > 0) {
        avgConfidence /= totalAlerts;
      }
      
      return {
        'totalAlerts': totalAlerts,
        'resolvedAlerts': resolvedAlerts,
        'falsePositives': falsePositives,
        'averageConfidence': avgConfidence,
        'accuracyRate': totalAlerts > 0 
            ? ((totalAlerts - falsePositives) / totalAlerts) * 100 
            : 0.0,
      };
    } catch (e) {
      print('Error getting fraud statistics: $e');
      return {};
    }
  }

  /// Batch update for performance
  static Future<void> batchUpdateTrips(List<TripData> trips) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var trip in trips) {
        DocumentReference docRef = _firestore
            .collection(_tripsCollection)
            .doc(trip.ticketId);
        batch.set(docRef, trip.toMap(), SetOptions(merge: true));
      }
      
      await batch.commit();
      print('Batch update completed successfully');
    } catch (e) {
      print('Error in batch update: $e');
      throw e;
    }
  }

  /// Clean up old trip data (for privacy compliance)
  static Future<void> cleanupOldTripData({int daysToKeep = 30}) async {
    try {
      DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      QuerySnapshot snapshot = await _firestore
          .collection(_tripsCollection)
          .where('startTime', isLessThan: cutoffDate.millisecondsSinceEpoch)
          .get();
      
      WriteBatch batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Cleaned up ${snapshot.docs.length} old trip records');
    } catch (e) {
      print('Error cleaning up old trip data: $e');
    }
  }
}
