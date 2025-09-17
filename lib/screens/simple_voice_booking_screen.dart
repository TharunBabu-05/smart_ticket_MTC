import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../models/enhanced_ticket_model.dart';
import '../models/trip_data_model.dart' as trip_data;
import '../services/voice_multilingual_service.dart';
import '../services/enhanced_ticket_service.dart';
import '../services/razorpay_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../models/bus_stop_model.dart';
import '../data/bus_stops_data.dart';
import '../widgets/voice_guidance_widget.dart';
import 'ticket_display_screen.dart';

/// Simple Voice-Guided Ticket Booking with TTS Assistance
class SimpleVoiceBookingScreen extends StatefulWidget {
  @override
  _SimpleVoiceBookingScreenState createState() => _SimpleVoiceBookingScreenState();
}

class _SimpleVoiceBookingScreenState extends State<SimpleVoiceBookingScreen> {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final Uuid _uuid = Uuid();
  
  String _currentLanguage = 'en';
  String? _selectedSource;
  String? _selectedDestination;
  double _estimatedFare = 0.0;
  bool _isLoading = false;
  
  // Popular Chennai bus stops
  final List<String> _popularStations = [
    'Chennai Egmore',
    'Chennai Central', 
    'T Nagar',
    'Park Town',
    'Guindy',
    'Adyar',
    'Velachery',
    'Anna Nagar',
    'Vadapalani',
    'Koyambedu',
    'Tambaram',
    'Marina Beach',
    'Airport',
    'Mylapore',
    'Besant Nagar',
  ];

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _voiceService.initialize();
    await _voiceService.speakPhrase('welcome');
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onSourceChanged(String value) {
    setState(() {
      _selectedSource = value;
      _sourceController.text = value;
    });
    _calculateFare();
    _voiceService.processTextInput(value, 'source');
  }

  void _onDestinationChanged(String value) {
    setState(() {
      _selectedDestination = value;
      _destinationController.text = value;
    });
    _calculateFare();
    _voiceService.processTextInput(value, 'destination');
  }

  void _calculateFare() {
    if (_selectedSource != null && _selectedDestination != null) {
      // Simple fare calculation based on distance estimate
      final random = math.Random();
      setState(() {
        _estimatedFare = 15.0 + (random.nextDouble() * 25.0);
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await _voiceService.setLanguage(languageCode);
    setState(() => _currentLanguage = languageCode);
  }

  Future<void> _bookTicket() async {
    if (_selectedSource == null || _selectedDestination == null) {
      await _voiceService.speak('Please select both source and destination');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _voiceService.speak('Please sign in to book tickets');
        throw Exception('User not authenticated');
      }

      // First, validate location to check for distance warning
      bool hasDistanceWarning = await _checkDistanceWarning();
      
      if (hasDistanceWarning) {
        // Distance warning detected - let the warning dialog handle the flow
        // The warning dialog will call _proceedToPayment() if user confirms
        return;
      }

      // If no distance warning, proceed with normal payment flow
      await _proceedToNormalPayment();

    } catch (e) {
      String errorMessage = e.toString();
      print('❌ Error in voice ticket booking: $errorMessage');
      
      await _voiceService.speak('Booking failed. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Check if there's a distance warning without creating a ticket
  Future<bool> _checkDistanceWarning() async {
    try {
      // Import required services for location checking
      final LocationService locationService = LocationService();
      final trip_data.LocationPoint? currentLocation = await locationService.getCurrentLocation();
      
      if (currentLocation == null) {
        print('⚠️ Could not get current location - proceeding without distance check');
        return false;
      }

      // Find source bus stop
      final BusStop? sourceStop = BusStopsData.getStopByName(_selectedSource!);
      if (sourceStop == null) {
        print('⚠️ Source stop not found - proceeding without distance check');
        return false;
      }

      // Calculate distance to source stop using the trip_data LatLng type
      final trip_data.LatLng sourceStopLocation = trip_data.LatLng(sourceStop.latitude, sourceStop.longitude);
      final double distance = locationService.calculateDistance(
        currentLocation.position,
        sourceStopLocation,
      );

      print('📏 Distance to ${sourceStop.name}: ${distance.toStringAsFixed(0)}m');

      // If too far from source stop, show distance warning
      if (distance > 500) { // 500 meters threshold
        String warningMessage = 'You are ${distance.toStringAsFixed(0)}m away from ${sourceStop.name}. For accurate ticket validation, please be closer to the bus stop.';
        
        await _voiceService.speak('Distance warning detected. You are far from the bus stop.');
        
        // Show warning dialog with option to continue
        _showWarningDialog(
          '$warningMessage\n\nWould you like to proceed with booking the ticket anyway?',
          () async {
            // User chose to continue despite distance warning
            print('✅ User confirmed to continue despite distance warning');
            await _proceedToPayment();
          },
        );
        return true; // Distance warning shown
      }

      return false; // No distance warning
    } catch (e) {
      print('⚠️ Error checking distance: $e - proceeding without distance check');
      return false;
    }
  }

  // Proceed with payment after user confirms distance warning
  Future<void> _proceedToPayment() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _voiceService.speak('Please sign in to book tickets');
        throw Exception('User not authenticated');
      }

      // Show payment confirmation
      bool? proceedWithPayment = await _showPaymentConfirmationDialog(_estimatedFare,
          message: 'Proceed with booking despite distance warning?');
      if (proceedWithPayment != true) {
        await _voiceService.speak('Payment cancelled');
        return;
      }

      // Get user information for payment
      String userName = user.displayName ?? 'Smart Ticket User';
      String userEmail = user.email ?? 'user@smartticket.com';
      String userPhone = user.phoneNumber ?? '+919876543210';

      await _voiceService.speak('Processing payment despite distance warning. Please complete the payment.');

      // Process payment with Razorpay (will create ticket without location check after payment)
      await RazorpayService.payForTicket(
        context: context,
        ticketPrice: _estimatedFare,
        ticketType: 'Voice Booking (Distance Override)',
        fromStation: _selectedSource!,
        toStation: _selectedDestination!,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        onPaymentSuccess: (paymentId) async {
          await _handlePaymentSuccessWithOverride(paymentId);
        },
        onPaymentFailure: (error) {
          _handlePaymentFailure(error);
        },
      );

    } catch (e) {
      await _voiceService.speak('Payment failed. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to proceed with normal payment (no distance warning)
  Future<void> _proceedToNormalPayment() async {
    // Show payment confirmation first
    bool? proceedWithPayment = await _showPaymentConfirmationDialog(_estimatedFare);
    if (proceedWithPayment != true) {
      await _voiceService.speak('Payment cancelled');
      return;
    }

    // Get user information for payment
    final user = FirebaseAuth.instance.currentUser!;
    String userName = user.displayName ?? 'Smart Ticket User';
    String userEmail = user.email ?? 'user@smartticket.com';
    String userPhone = user.phoneNumber ?? '+919876543210';

    await _voiceService.speak('Processing payment. Please complete the payment to book your ticket.');

    // Process payment with Razorpay - use regular ticket creation after payment
    await RazorpayService.payForTicket(
      context: context,
      ticketPrice: _estimatedFare,
      ticketType: 'Voice Booking',
      fromStation: _selectedSource!,
      toStation: _selectedDestination!,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      onPaymentSuccess: (paymentId) async {
        // Use regular ticket creation since location was already verified
        await _handlePaymentSuccess(paymentId);
      },
      onPaymentFailure: (error) {
        _handlePaymentFailure(error);
      },
    );
  }

  Future<void> _proceedWithPayment() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _voiceService.speak('Please sign in to book tickets');
        throw Exception('User not authenticated');
      }

      // Show payment confirmation for distance override case
      bool? proceedWithPayment = await _showPaymentConfirmationDialog(_estimatedFare, 
          message: 'Proceed with booking despite distance warning?');
      if (proceedWithPayment != true) {
        await _voiceService.speak('Payment cancelled');
        return;
      }

      // Get user information for payment
      String userName = user.displayName ?? 'Smart Ticket User';
      String userEmail = user.email ?? 'user@smartticket.com';
      String userPhone = user.phoneNumber ?? '+919876543210';

      await _voiceService.speak('Processing payment despite distance warning. Please complete the payment.');

      // Process payment with Razorpay (will create ticket without location check after payment)
      await RazorpayService.payForTicket(
        context: context,
        ticketPrice: _estimatedFare,
        ticketType: 'Voice Booking (Distance Override)',
        fromStation: _selectedSource!,
        toStation: _selectedDestination!,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        onPaymentSuccess: (paymentId) async {
          await _handlePaymentSuccessWithOverride(paymentId);
        },
        onPaymentFailure: (error) {
          _handlePaymentFailure(error);
        },
      );

    } catch (e) {
      await _voiceService.speak('Booking still failed. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show payment confirmation dialog
  Future<bool?> _showPaymentConfirmationDialog(double fare, {String? message}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirm Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
            ],
            Text('Route: ${_selectedSource} → ${_selectedDestination}'),
            SizedBox(height: 8),
            Text('Fare: ₹${fare.toStringAsFixed(2)}', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 12),
            Text('Payment will be processed through Razorpay gateway.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Proceed to Pay'),
          ),
        ],
      ),
    );
  }

  // Handle successful payment
  Future<void> _handlePaymentSuccess(String paymentId) async {
    try {
      print('✅ Payment successful for voice booking: $paymentId');
      await _voiceService.speak('Payment successful! Creating your ticket now.');

      // Create ticket after successful payment (voice booking skips location check)
      print('🎫 Creating ticket without location check...');
      final ticket = await EnhancedTicketService.issueTicketWithoutLocationCheck(
        sourceName: _selectedSource!,
        destinationName: _selectedDestination!,
        fare: _estimatedFare,
        paymentId: paymentId, // Include payment ID
      );
      print('✅ Ticket created successfully: ${ticket.ticketId}');

      // Try to add payment notification (but don't fail if it doesn't work)
      try {
        await NotificationService().addPaymentNotification(
          paymentId: paymentId,
          amount: _estimatedFare.toStringAsFixed(2),
          route: '$_selectedSource to $_selectedDestination',
        );
        print('✅ Payment notification added');
      } catch (notifError) {
        print('⚠️ Payment notification failed but continuing: $notifError');
      }

      await _voiceService.speak('Ticket booked successfully!');

      // Navigate to ticket display
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: ticket.sessionId,
            tripData: trip_data.TripData(
              ticketId: ticket.ticketId,
              userId: ticket.userId,
              startTime: ticket.issueTime,
              sourceLocation: trip_data.LatLng(ticket.sourceLocation.latitude, ticket.sourceLocation.longitude),
              destinationLocation: trip_data.LatLng(ticket.destinationLocation.latitude, ticket.destinationLocation.longitude),
              sourceName: ticket.sourceName,
              destinationName: ticket.destinationName,
              status: trip_data.TripStatus.active,
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error creating ticket after payment: $e');
      await _voiceService.speak('Payment was successful but ticket creation failed. Please contact support.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful but ticket creation failed. Contact support with payment ID: $paymentId'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Handle successful payment with distance override
  Future<void> _handlePaymentSuccessWithOverride(String paymentId) async {
    try {
      print('✅ Payment successful for voice booking with distance override: $paymentId');
      await _voiceService.speak('Payment successful! Creating your ticket now despite distance warning.');

      // Force booking without location check (distance override)
      final ticket = await EnhancedTicketService.issueTicketWithoutLocationCheck(
        sourceName: _selectedSource!,
        destinationName: _selectedDestination!,
        fare: _estimatedFare,
        paymentId: paymentId,
      );

      // Add payment success notification
      await NotificationService().addPaymentNotification(
        paymentId: paymentId,
        amount: _estimatedFare.toStringAsFixed(2),
        route: '$_selectedSource to $_selectedDestination',
      );

      await _voiceService.speak('Ticket booked successfully despite distance warning!');

      // Navigate to ticket display
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: ticket.sessionId,
            tripData: trip_data.TripData(
              ticketId: ticket.ticketId,
              userId: ticket.userId,
              startTime: ticket.issueTime,
              sourceLocation: trip_data.LatLng(ticket.sourceLocation.latitude, ticket.sourceLocation.longitude),
              destinationLocation: trip_data.LatLng(ticket.destinationLocation.latitude, ticket.destinationLocation.longitude),
              sourceName: ticket.sourceName,
              destinationName: ticket.destinationName,
              status: trip_data.TripStatus.active,
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error creating ticket after payment (override): $e');
      await _voiceService.speak('Payment was successful but ticket creation failed. Please contact support.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful but ticket creation failed. Contact support with payment ID: $paymentId'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Handle payment failure
  void _handlePaymentFailure(String error) async {
    print('❌ Payment failed for voice booking: $error');
    await _voiceService.speak('Payment failed. Please try again.');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $error'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Guided Booking'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _voiceService.speakPhrase('welcome'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selector
            LanguageSelectorWidget(
              currentLanguage: _currentLanguage,
              onLanguageChanged: _changeLanguage,
              voiceService: _voiceService,
            ),
            
            SizedBox(height: 20),
            
            // Source Station Section
            _buildStationSection(
              title: 'From Station',
              controller: _sourceController,
              fieldType: 'source',
              onChanged: _onSourceChanged,
            ),
            
            SizedBox(height: 20),
            
            // Destination Station Section  
            _buildStationSection(
              title: 'To Station',
              controller: _destinationController,
              fieldType: 'destination',
              onChanged: _onDestinationChanged,
            ),
            
            SizedBox(height: 20),
            
            // Popular Stations Quick Select
            _buildPopularStations(),
            
            SizedBox(height: 20),
            
            // Fare Display
            if (_estimatedFare > 0) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Fare:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₹${_estimatedFare.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
            
            // Book Ticket Button
            ElevatedButton(
              onPressed: _isLoading ? null : _bookTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Book Ticket',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSection({
    required String title,
    required TextEditingController controller,
    required String fieldType,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8),
        
        // Voice Guidance Widget
        VoiceGuidanceWidget(
          fieldType: fieldType,
          hint: 'Get voice guidance for $title',
        ),
        
        SizedBox(height: 12),
        
        // Enhanced Text Field
        VoiceTextField(
          label: title,
          fieldType: fieldType,
          controller: controller,
          suggestions: _popularStations,
          onChanged: onChanged,
          voiceService: _voiceService,
        ),
      ],
    );
  }

  Widget _buildPopularStations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Popular Stations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () => _voiceService.announcePopularStations(_popularStations),
                  child: Text('🔊 Listen'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularStations.map((station) {
                return ActionChip(
                  label: Text(
                    station,
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    if (_sourceController.text.isEmpty) {
                      _onSourceChanged(station);
                    } else if (_destinationController.text.isEmpty) {
                      _onDestinationChanged(station);
                    } else {
                      // Show dialog to choose which field to fill
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Select Field'),
                          content: Text('Which field would you like to update with "$station"?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _onSourceChanged(station);
                              },
                              child: Text('From'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _onDestinationChanged(station);
                              },
                              child: Text('To'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarningDialog(String message, VoidCallback onContinue) {
    print('🚨 Showing distance warning dialog: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Distance Warning'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ User cancelled voice ticket booking');
              Navigator.of(context).pop();
              _voiceService.speak('Booking cancelled');
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              print('✅ User chose to book anyway despite distance warning');
              Navigator.of(context).pop();
              _voiceService.speak('Proceeding with booking despite distance warning');
              onContinue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Book Anyway'),
          ),
        ],
      ),
    );
  }
}
