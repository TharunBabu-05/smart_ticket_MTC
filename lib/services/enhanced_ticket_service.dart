import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../models/enhanced_ticket_model.dart';
import '../models/trip_data_model.dart' as trip;
import '../models/bus_stop_model.dart';
import '../services/cross_platform_service.dart';
import '../services/location_service.dart';
import '../data/bus_stops_data.dart';

/// Custom result class for location verification
class LocationVerificationResult {
  final bool shouldShowWarning;
  final String? warningMessage;
  final double distance;
  final String stopName;
  
  LocationVerificationResult({
    required this.shouldShowWarning,
    this.warningMessage,
    required this.distance,
    required this.stopName,
  });
}

class EnhancedTicketService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ticketsCollection = 'enhanced_tickets';
  static const String _penaltiesCollection = 'penalties';
  
  static Timer? _validationTimer;
  static StreamController<EnhancedTicket>? _ticketUpdateController;
  static EnhancedTicket? _currentActiveTicket;

  /// Initialize the enhanced ticket service
  static Future<void> initialize() async {
    try {
      await CrossPlatformService.initialize();
      _ticketUpdateController = StreamController<EnhancedTicket>.broadcast();
      print('Enhanced ticket service initialized');
    } catch (e) {
      print('Error initializing enhanced ticket service: $e');
      throw e;
    }
  }

  /// Create and issue a new enhanced ticket
  static Future<EnhancedTicket> issueTicket({
    required String sourceName,
    required String destinationName,
    required double fare,
  }) async {
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get source and destination locations
      BusStop? sourceStop = BusStopsData.getStopByName(sourceName);
      BusStop? destStop = BusStopsData.getStopByName(destinationName);
      
      if (sourceStop == null || destStop == null) {
        throw Exception('Invalid bus stops selected');
      }

      // Verify user location (near source stop)
      LocationVerificationResult locationResult = await _verifyUserLocation(sourceStop);
      
      // If warning is needed, throw a special exception that the UI can catch
      if (locationResult.shouldShowWarning) {
        throw Exception('DISTANCE_WARNING:${locationResult.warningMessage}');
      }

      // Generate ticket details
      String ticketId = _generateTicketId();
      DateTime issueTime = DateTime.now();
      DateTime validUntil = issueTime.add(Duration(hours: 2));
      String qrCode = _generateQRCode(ticketId);

      // Create cross-platform session
      trip.TripData tripData = trip.TripData(
        ticketId: ticketId,
        userId: user.uid,
        startTime: issueTime,
        sourceLocation: trip.LatLng(sourceStop.latitude, sourceStop.longitude),
        destinationLocation: trip.LatLng(destStop.latitude, destStop.longitude),
        sourceName: sourceName,
        destinationName: destinationName,
        status: trip.TripStatus.active,
      );

      String sessionId = await CrossPlatformService.createTripSession(tripData);

      // Create enhanced ticket
      EnhancedTicket ticket = EnhancedTicket(
        ticketId: ticketId,
        userId: user.uid,
        sessionId: sessionId,
        issueTime: issueTime,
        validUntil: validUntil,
        sourceName: sourceName,
        destinationName: destinationName,
        sourceLocation: gmaps.LatLng(sourceStop.latitude, sourceStop.longitude),
        destinationLocation: gmaps.LatLng(destStop.latitude, destStop.longitude),
        fare: fare,
        qrCode: qrCode,
        metadata: {
          'sourceStopId': sourceStop.id,
          'destStopId': destStop.id,
          'sourceLatitude': sourceStop.latitude,
          'sourceLongitude': sourceStop.longitude,
          'destLatitude': destStop.latitude,
          'destLongitude': destStop.longitude,
        },
      );

      // Save to Firebase
      await _saveTicketToFirebase(ticket);

      // Start location tracking and cross-platform streaming
      await _startTicketValidation(ticket);

      _currentActiveTicket = ticket;
      print('Enhanced ticket issued: ${ticket.ticketId}');
      
      return ticket;
    } catch (e) {
      print('Error issuing ticket: $e');
      throw e;
    }
  }

  /// Create and issue a new enhanced ticket without location verification
  static Future<EnhancedTicket> issueTicketWithoutLocationCheck({
    required String sourceName,
    required String destinationName,
    required double fare,
  }) async {
    try {
      print('🚀 Starting simple ticket creation...');
      
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      print('✅ User authenticated: ${user.uid}');

      // Get source and destination locations
      BusStop? sourceStop = BusStopsData.getStopByName(sourceName);
      BusStop? destStop = BusStopsData.getStopByName(destinationName);
      
      if (sourceStop == null || destStop == null) {
        throw Exception('Invalid bus stops selected');
      }
      print('✅ Bus stops found: $sourceName -> $destinationName');

      // Generate simple ticket details
      String ticketId = _generateTicketId();
      DateTime issueTime = DateTime.now();
      DateTime validUntil = issueTime.add(Duration(hours: 2));
      String qrCode = _generateQRCode(ticketId);
      print('✅ Ticket details generated: $ticketId');

      // Create simple enhanced ticket (no complex background processes)
      EnhancedTicket ticket = EnhancedTicket(
        ticketId: ticketId,
        userId: user.uid,
        sessionId: 'simple_$ticketId', // Simple session ID
        issueTime: issueTime,
        validUntil: validUntil,
        sourceName: sourceName,
        destinationName: destinationName,
        sourceLocation: gmaps.LatLng(sourceStop.latitude, sourceStop.longitude),
        destinationLocation: gmaps.LatLng(destStop.latitude, destStop.longitude),
        fare: fare,
        qrCode: qrCode,
        metadata: {
          'sourceStopId': sourceStop.id,
          'destStopId': destStop.id,
          'sourceLatitude': sourceStop.latitude,
          'sourceLongitude': sourceStop.longitude,
          'destLatitude': destStop.latitude,
          'destLongitude': destStop.longitude,
          'distantBooking': true,
          'simpleBooking': true, // Flag for simplified booking
        },
      );
      print('✅ Ticket object created successfully');

      // Store locally first (in memory)
      _currentActiveTicket = ticket;
      
      // Also store in persistent storage (SharedPreferences)
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String ticketKey = 'ticket_${user.uid}_${ticket.ticketId}';
        String ticketJson = jsonEncode(ticket.toMap());
        await prefs.setString(ticketKey, ticketJson);
        print('✅ Ticket stored in persistent local storage: $ticketKey');
      } catch (e) {
        print('⚠️ Failed to store ticket in persistent storage: $e');
      }
      
      print('✅ Ticket stored locally');

      // Try to save to Firebase (but don't block if it fails)
      _saveTicketToFirebaseAsync(ticket);

      print('🎉 Ticket booking completed successfully: ${ticket.ticketId}');
      return ticket;
      
    } catch (e) {
      print('❌ Error in simple ticket booking: $e');
      throw e;
    }
  }

  /// Save ticket to Firebase asynchronously (non-blocking)
  static void _saveTicketToFirebaseAsync(EnhancedTicket ticket) {
    Future.delayed(Duration.zero, () async {
      try {
        print('📤 Attempting async Firebase save...');
        await _saveTicketToFirebase(ticket).timeout(Duration(seconds: 5));
        print('✅ Ticket saved to Firebase successfully');
      } catch (e) {
        print('⚠️ Firebase save failed (continuing anyway): $e');
      }
    });
  }

  /// Verify user location and return verification result
  static Future<LocationVerificationResult> _verifyUserLocation(BusStop sourceStop) async {
    try {
      Location location = Location();
      
      // Check permissions
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location services must be enabled to book tickets');
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission is required to verify your position');
        }
      }

      LocationData locationData = await location.getLocation();
      
      // Calculate distance to source stop
      LocationService locationService = LocationService();
      double distance = locationService.calculateDistance(
        trip.LatLng(locationData.latitude!, locationData.longitude!),
        trip.LatLng(sourceStop.latitude, sourceStop.longitude),
      );

      // Return verification result based on distance
      if (distance > 200) {
        return LocationVerificationResult(
          shouldShowWarning: true,
          warningMessage: 'You are ${(distance/1000).toStringAsFixed(1)}km away from ${sourceStop.name}. You can still book the ticket from here, but please plan to reach the bus stop on time.',
          distance: distance,
          stopName: sourceStop.name,
        );
      } else {
        return LocationVerificationResult(
          shouldShowWarning: false,
          distance: distance,
          stopName: sourceStop.name,
        );
      }
    } catch (e) {
      print('Location verification error: $e');
      rethrow;
    }
  }

  /// Start ticket validation and monitoring
  static Future<void> _startTicketValidation(EnhancedTicket ticket) async {
    try {
      // Start cross-platform data streaming
      await CrossPlatformService.startDataStreaming(ticket.sessionId);

      // Start validation timer
      _validationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
        _validateTicketStatus(ticket);
      });

      // Listen for location warnings
      _listenForLocationWarnings(ticket);

      print('Ticket validation started for: ${ticket.ticketId}');
    } catch (e) {
      print('Error starting ticket validation: $e');
    }
  }

  /// Validate ticket status periodically
  static Future<void> _validateTicketStatus(EnhancedTicket ticket) async {
    try {
      // Check if ticket has expired
      if (!ticket.isValid) {
        await _expireTicket(ticket);
        return;
      }

      // Check location services
      Location location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      
      if (!serviceEnabled) {
        // Show warning about location services
        _ticketUpdateController?.add(ticket.copyWith(
          metadata: {
            ...ticket.metadata,
            'locationWarning': 'Location services are disabled. Please enable to continue validation.',
          },
        ));
      }

      // Update ticket in Firebase
      await _updateTicketStatus(ticket);

    } catch (e) {
      print('Error validating ticket status: $e');
    }
  }

  /// Listen for location warnings and notifications
  static void _listenForLocationWarnings(EnhancedTicket ticket) {
    Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_currentActiveTicket?.ticketId != ticket.ticketId) {
        timer.cancel();
        return;
      }

      try {
        Location location = Location();
        bool serviceEnabled = await location.serviceEnabled();
        
        if (!serviceEnabled) {
          // Send location warning
          _showLocationWarning(
            'Location services are required',
            'Please enable location services to continue ticket validation. Your ticket may be flagged if location is disabled.',
          );
        }
      } catch (e) {
        print('Error checking location status: $e');
      }
    });
  }

  /// Complete ticket journey and analyze for fraud
  static Future<Map<String, dynamic>> completeTicket(
    String ticketId, 
    String actualExitStop
  ) async {
    try {
      EnhancedTicket? ticket = await getTicketById(ticketId);
      if (ticket == null) {
        throw Exception('Ticket not found');
      }

      // Stop cross-platform streaming
      await CrossPlatformService.stopDataStreaming();

      // Analyze for fraud
      Map<String, dynamic> fraudAnalysis = await CrossPlatformService.analyzeFraudAtExit(
        ticket.sessionId,
        actualExitStop,
        ticket.destinationName,
      );

      // Create penalty if fraud detected
      if (fraudAnalysis['isFraud'] == true) {
        await _createPenalty(ticket, fraudAnalysis);
      }

      // Mark ticket as completed
      await _completeTicket(ticket, actualExitStop);

      // Stop validation timer
      _validationTimer?.cancel();
      _currentActiveTicket = null;

      print('Ticket completed: $ticketId');
      return fraudAnalysis;

    } catch (e) {
      print('Error completing ticket: $e');
      throw e;
    }
  }

  /// Create penalty for fraud detection
  static Future<void> _createPenalty(EnhancedTicket ticket, Map<String, dynamic> fraudAnalysis) async {
    try {
      PenaltyInfo penalty = PenaltyInfo(
        ticketId: ticket.ticketId,
        sessionId: ticket.sessionId,
        userId: ticket.userId,
        reason: 'Distance violation - traveled beyond paid destination',
        amount: fraudAnalysis['penaltyAmount']?.toDouble() ?? 0.0,
        extraStops: fraudAnalysis['extraStops'] ?? 0,
        plannedExit: ticket.destinationName,
        actualExit: fraudAnalysis['actualExitStop'] ?? '',
        detectedAt: DateTime.now(),
      );

      await _firestore
          .collection(_penaltiesCollection)
          .doc(ticket.ticketId)
          .set(penalty.toMap());

      print('Penalty created for ticket: ${ticket.ticketId}');
    } catch (e) {
      print('Error creating penalty: $e');
    }
  }

  /// Save ticket to Firebase
  static Future<void> _saveTicketToFirebase(EnhancedTicket ticket) async {
    try {
      await _firestore
          .collection(_ticketsCollection)
          .doc(ticket.ticketId)
          .set(ticket.toMap());
    } catch (e) {
      print('Error saving ticket to Firebase: $e');
      throw e;
    }
  }

  /// Update ticket status
  static Future<void> _updateTicketStatus(EnhancedTicket ticket) async {
    try {
      await _firestore
          .collection(_ticketsCollection)
          .doc(ticket.ticketId)
          .update({
        'status': ticket.status.toString().split('.').last,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating ticket status: $e');
    }
  }

  /// Expire ticket
  static Future<void> _expireTicket(EnhancedTicket ticket) async {
    try {
      EnhancedTicket expiredTicket = ticket.copyWith(status: TicketStatus.expired);
      
      await _firestore
          .collection(_ticketsCollection)
          .doc(ticket.ticketId)
          .update({
        'status': 'expired',
        'expiredAt': DateTime.now().millisecondsSinceEpoch,
      });

      await CrossPlatformService.stopDataStreaming();
      _validationTimer?.cancel();
      _currentActiveTicket = null;

      _ticketUpdateController?.add(expiredTicket);
      print('Ticket expired: ${ticket.ticketId}');
    } catch (e) {
      print('Error expiring ticket: $e');
    }
  }

  /// Complete ticket
  static Future<void> _completeTicket(EnhancedTicket ticket, String exitStop) async {
    try {
      await _firestore
          .collection(_ticketsCollection)
          .doc(ticket.ticketId)
          .update({
        'status': 'completed',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'actualExitStop': exitStop,
      });
    } catch (e) {
      print('Error completing ticket: $e');
    }
  }

  /// Get ticket by ID
  static Future<EnhancedTicket?> getTicketById(String ticketId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_ticketsCollection)
          .doc(ticketId)
          .get();

      if (doc.exists) {
        return EnhancedTicket.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting ticket: $e');
      return null;
    }
  }

  /// Get user's active tickets
  static Future<List<EnhancedTicket>> getUserActiveTickets(String userId) async {
    try {
      // First try Firebase
      QuerySnapshot snapshot = await _firestore
          .collection(_ticketsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('issueTime', descending: true)
          .get();

      List<EnhancedTicket> firebaseTickets = snapshot.docs
          .map((doc) => EnhancedTicket.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      print('✅ Retrieved ${firebaseTickets.length} tickets from Firebase');
      return firebaseTickets;
    } catch (e) {
      print('❌ Firebase failed, checking local storage: $e');
      
      // Fallback to local storage
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        
        // Debug: Print all keys
        Set<String> allKeys = prefs.getKeys();
        print('🔍 All SharedPreferences keys: ${allKeys.toList()}');
        
        List<String> ticketKeys = allKeys
            .where((key) => key.startsWith('ticket_$userId'))
            .toList();
        
        print('🔍 Filtered ticket keys for user $userId: $ticketKeys');
        
        List<EnhancedTicket> localTickets = [];
        
        for (String key in ticketKeys) {
          String? ticketJson = prefs.getString(key);
          if (ticketJson != null) {
            try {
              Map<String, dynamic> ticketData = jsonDecode(ticketJson);
              EnhancedTicket ticket = EnhancedTicket.fromMap(ticketData);
              
              print('🎫 Found ticket: ${ticket.ticketId}, status: ${ticket.status}, valid: ${ticket.isValid}');
              
              // Only include active tickets
              if (ticket.status == TicketStatus.active && ticket.isValid) {
                localTickets.add(ticket);
              }
            } catch (parseError) {
              print('❌ Error parsing ticket $key: $parseError');
            }
          }
        }
        
        // Sort by issue time (newest first)
        localTickets.sort((a, b) => b.issueTime.compareTo(a.issueTime));
        
        print('✅ Retrieved ${localTickets.length} tickets from local storage');
        return localTickets;
      } catch (localError) {
        print('❌ Local storage also failed: $localError');
        return [];
      }
    }
  }

  /// Get user's penalties
  static Future<List<PenaltyInfo>> getUserPenalties(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_penaltiesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('detectedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PenaltyInfo.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user penalties: $e');
      return [];
    }
  }

  /// Generate unique ticket ID
  static String _generateTicketId() {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'TKT_$timestamp$random';
  }

  /// Generate QR code data
  static String _generateQRCode(String ticketId) {
    return 'SMART_TICKET_MTC:$ticketId:${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Show location warning
  static void _showLocationWarning(String title, String message) {
    // This would typically show a notification or in-app alert
    print('LOCATION WARNING: $title - $message');
  }

  /// Get ticket update stream
  static Stream<EnhancedTicket>? get ticketUpdateStream => _ticketUpdateController?.stream;

  /// Get current active ticket
  static EnhancedTicket? get currentActiveTicket => _currentActiveTicket;

  /// Dispose resources
  static Future<void> dispose() async {
    _validationTimer?.cancel();
    await CrossPlatformService.stopDataStreaming();
    await _ticketUpdateController?.close();
    _currentActiveTicket = null;
  }
}
