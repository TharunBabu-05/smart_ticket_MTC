import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models/emergency_contact_model.dart';
import 'notification_service.dart';
import 'location_service.dart';

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Location _location = Location();
  
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _sosTimer;
  bool _isLocationSharingActive = false;
  bool _isSosActive = false;
  List<EmergencyContact> _emergencyContacts = [];

  // Initialize safety service
  Future<void> initialize() async {
    await _loadEmergencyContacts();
    await _setupLocationPermissions();
  }

  // Emergency SOS Features
  Future<void> activateEmergencySOS() async {
    try {
      _isSosActive = true;
      
      // Get current location
      final locationData = await _location.getLocation();
      final user = _auth.currentUser;
      
      if (user == null) throw Exception('User not authenticated');

      // Create emergency alert document
      final emergencyAlert = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous User',
        'userEmail': user.email,
        'location': {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'accuracy': locationData.accuracy,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'alertType': 'SOS',
        'description': 'Emergency SOS activated',
      };

      // Save to Firestore
      final docRef = await _firestore
          .collection('emergency_alerts')
          .add(emergencyAlert);

      // Start location tracking for SOS
      await _startEmergencyLocationTracking(docRef.id);

      // Send alerts to emergency contacts
      await _sendEmergencyAlerts(locationData);

      // Send SMS to emergency services (simulation)
      await _alertEmergencyServices(locationData);

      // Create persistent notification
      await NotificationService().showEmergencyNotification();

      print('Emergency SOS activated successfully');
    } catch (e) {
      print('Error activating SOS: $e');
      throw Exception('Failed to activate emergency SOS: $e');
    }
  }

  Future<void> deactivateEmergencySOS() async {
    try {
      _isSosActive = false;
      _sosTimer?.cancel();
      await stopLocationSharing();
      
      // Update all active alerts to resolved
      final user = _auth.currentUser;
      if (user != null) {
        final alerts = await _firestore
            .collection('emergency_alerts')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .get();

        for (final doc in alerts.docs) {
          await doc.reference.update({
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await NotificationService().cancelEmergencyNotification();
      print('Emergency SOS deactivated');
    } catch (e) {
      print('Error deactivating SOS: $e');
    }
  }

  // Live Location Sharing
  Future<void> startLocationSharing({List<String>? contactIds, Duration? duration}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // If no contactIds provided, use all emergency contacts
      List<String> targetContactIds = contactIds ?? _emergencyContacts.map((c) => c.id).toList();

      final location = await LocationService().getCurrentLocation();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('location_sharing_active', true);
      _isLocationSharingActive = true;

      // Store sharing session in Firestore
      await _firestore.collection('location_sharing').doc(user.uid).set({
        'userId': user.uid,
        'contactIds': targetContactIds,
        'isActive': true,
        'startedAt': FieldValue.serverTimestamp(),
        'expiresAt': duration != null ? 
            Timestamp.fromDate(DateTime.now().add(duration)) : null,
        'currentLocation': {
          'latitude': location?.position.latitude ?? 0.0,
          'longitude': location?.position.longitude ?? 0.0,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      // Start location tracking
      _locationSubscription = _location.onLocationChanged.listen((locationData) {
        _updateSharedLocation(locationData);
      });

      // Set auto-stop timer if duration specified
      if (duration != null) {
        Timer(duration, () {
          stopLocationSharing();
        });
      }

      // Notify selected contacts
      for (String contactId in targetContactIds) {
        final contact = await _getContactById(contactId);
        if (contact != null) {
          await _sendLocationSharingNotification(contact, location);
        }
      }

      await NotificationService().showLocationSharingNotification();
      print('Location sharing started');
    } catch (e) {
      print('Error starting location sharing: $e');
      throw Exception('Failed to start location sharing: $e');
    }
  }

  Future<void> stopLocationSharing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_sharing_active', false);
      _isLocationSharingActive = false;
      _locationSubscription?.cancel();
      _locationSubscription = null;

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('location_sharing').doc(user.uid).update({
          'isActive': false,
          'stoppedAt': FieldValue.serverTimestamp(),
        });
      }

      await NotificationService().cancelLocationSharingNotification();
      print('Location sharing stopped');
    } catch (e) {
      print('Error stopping location sharing: $e');
    }
  }

  // Emergency Contacts Management
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .add(contact.toJson());

      _emergencyContacts.add(contact);
      await _saveContactsLocally();
      print('Emergency contact added: ${contact.name}');
    } catch (e) {
      print('Error adding emergency contact: $e');
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  Future<void> removeEmergencyContact(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();

      _emergencyContacts.removeWhere((c) => c.id == contactId);
      await _saveContactsLocally();
      print('Emergency contact removed');
    } catch (e) {
      print('Error removing emergency contact: $e');
    }
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    if (_emergencyContacts.isEmpty) {
      await _loadEmergencyContacts();
    }
    return List.from(_emergencyContacts);
  }

  // Women Safety Features
  Future<List<String>> getWomenOnlyBuses() async {
    try {
      // Simulate women-only bus routes data
      final womenOnlyRoutes = [
        'Route 12A - Women Special',
        'Route 45W - Ladies Only',
        'Route 78F - Women Safety',
        'Metro Pink Line - Ladies Coach',
        'Route 156W - Women Priority',
      ];

      return womenOnlyRoutes;
    } catch (e) {
      print('Error fetching women-only buses: $e');
      return [];
    }
  }

  Future<void> sendWomenSafetyNotification(String busRoute) async {
    await NotificationService().showWomenSafetyNotification(
      '$busRoute is arriving in 5 minutes at your stop.',
    );
  }

  // Safe Route Recommendations
  Future<List<Map<String, dynamic>>> getSafeRouteRecommendations({
    required double sourceLat,
    required double sourceLon,
    required double destLat,
    required double destLon,
  }) async {
    try {
      final currentHour = DateTime.now().hour;
      final isNightTime = currentHour < 6 || currentHour > 22;
      
      List<Map<String, dynamic>> recommendations = [];

      if (isNightTime) {
        recommendations.add({
          'title': '🚇 Metro Route (Safest)',
          'description': 'Well-lit metro stations with security',
          'safetyScore': 95,
          'features': ['CCTV Coverage', 'Security Guards', 'Good Lighting'],
          'estimatedTime': '25 mins',
          'cost': '₹35',
        });

        recommendations.add({
          'title': '🚌 AC Bus Routes',
          'description': 'Main road routes with frequent stops',
          'safetyScore': 85,
          'features': ['Main Roads', 'Frequent Service', 'GPS Tracking'],
          'estimatedTime': '35 mins',
          'cost': '₹25',
        });
      } else {
        recommendations.add({
          'title': '🚌 Direct Bus Route',
          'description': 'Fastest public transport option',
          'safetyScore': 88,
          'features': ['Direct Route', 'Regular Service', 'Safe Stops'],
          'estimatedTime': '20 mins',
          'cost': '₹15',
        });

        recommendations.add({
          'title': '🚇 Metro + Bus Combo',
          'description': 'Most economical safe option',
          'safetyScore': 90,
          'features': ['Metro Safety', 'Short Bus Connect', 'Well Lit'],
          'estimatedTime': '30 mins',
          'cost': '₹22',
        });
      }

      // Add women-only options if user is female (can be determined from profile)
      recommendations.add({
        'title': '👩 Women-Only Services',
        'description': 'Ladies special buses and coaches',
        'safetyScore': 98,
        'features': ['Women Only', 'Enhanced Security', 'Priority Seating'],
        'estimatedTime': '28 mins',
        'cost': '₹20',
      });

      return recommendations;
    } catch (e) {
      print('Error getting safe route recommendations: $e');
      return [];
    }
  }

  // Helper Methods
  Future<void> _startEmergencyLocationTracking(String alertId) async {
    _sosTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!_isSosActive) {
        timer.cancel();
        return;
      }

      try {
        final locationData = await _location.getLocation();
        await _firestore
            .collection('emergency_alerts')
            .doc(alertId)
            .collection('location_history')
            .add({
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'accuracy': locationData.accuracy,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating emergency location: $e');
      }
    });
  }

  Future<void> _updateSharedLocation(LocationData locationData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('shared_locations').doc(user.uid).set({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'accuracy': locationData.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
        'batteryLevel': await _getBatteryLevel(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating shared location: $e');
    }
  }

  Future<void> _sendEmergencyAlerts(LocationData locationData) async {
    for (final contact in _emergencyContacts) {
      try {
        // Send notification through app if contact is app user
        await NotificationService().sendEmergencyAlert(
          contact.name,
          'Emergency alert from ${_auth.currentUser?.displayName ?? 'Someone'}\n'
              'Location: https://maps.google.com/?q=${locationData.latitude},${locationData.longitude}',
        );

        // Simulate SMS sending (in real app, use SMS gateway)
        print('Emergency SMS sent to ${contact.phoneNumber}');
      } catch (e) {
        print('Error sending alert to ${contact.name}: $e');
      }
    }
  }

  Future<void> _alertEmergencyServices(LocationData locationData) async {
    // Simulate contacting emergency services
    // In real implementation, this would integrate with local emergency services API
    print('Emergency services alerted: Location ${locationData.latitude}, ${locationData.longitude}');
  }

  Future<void> _setupLocationPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // Configure location settings for safety features
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000, // 10 seconds
      distanceFilter: 10, // 10 meters
    );
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .get();

      _emergencyContacts = snapshot.docs
          .map((doc) => EmergencyContact.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      print('Error loading emergency contacts: $e');
      await _loadContactsFromLocal();
    }
  }

  Future<void> _saveContactsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = _emergencyContacts.map((c) => c.toJson()).toList();
      await prefs.setString('emergency_contacts', json.encode(contactsJson));
    } catch (e) {
      print('Error saving contacts locally: $e');
    }
  }

  Future<void> _loadContactsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsData = prefs.getString('emergency_contacts');
      if (contactsData != null) {
        final List<dynamic> contactsList = json.decode(contactsData);
        _emergencyContacts = contactsList
            .map((data) => EmergencyContact.fromJson(data))
            .toList();
      }
    } catch (e) {
      print('Error loading contacts from local: $e');
    }
  }

  Future<int> _getBatteryLevel() async {
    try {
      const platform = MethodChannel('battery');
      final batteryLevel = await platform.invokeMethod('getBatteryLevel');
      return batteryLevel;
    } catch (e) {
      return -1; // Battery level unknown
    }
  }

  // Getters
  bool get isLocationSharingActive => _isLocationSharingActive;
  bool get isSosActive => _isSosActive;

  // Additional status check methods for UI integration
  Future<bool> isEmergencySOSActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('emergency_sos_active') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isWomenSafetyEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('women_safety_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contact.id)
          .update(contact.toJson());

      final index = _emergencyContacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _emergencyContacts[index] = contact;
        await _saveContactsLocally();
      }
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  Future<EmergencyContact?> _getContactById(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .get();

      if (doc.exists) {
        return EmergencyContact.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendLocationSharingNotification(EmergencyContact contact, location) async {
    // Implementation would send notification via SMS/push notification
    // This is a placeholder for the actual notification sending logic
    print('Sending location sharing notification to ${contact.name}');
  }

  // Cleanup
  Future<void> dispose() async {
    _locationSubscription?.cancel();
    _sosTimer?.cancel();
  }
}