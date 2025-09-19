import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/trip_data_model.dart';
import '../models/enhanced_ticket_model.dart';
import '../models/bus_stop_model.dart';
import '../services/location_service.dart';
import '../services/enhanced_ticket_service.dart';
import '../services/razorpay_service.dart';
import '../services/notification_service.dart';
import '../data/bus_stops_data.dart';
import '../themes/app_theme.dart';
import 'ticket_display_screen.dart';

class TicketBookingScreen extends StatefulWidget {
  @override
  _TicketBookingScreenState createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  final LocationService _locationService = LocationService();
  final Uuid _uuid = Uuid();
  
  String? _selectedFromStop;
  String? _selectedToStop;
  double _estimatedFare = 0.0;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: 'Book Bus Ticket',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context),
            const SizedBox(height: 20),
            _buildRouteSelectionCard(context),
            const SizedBox(height: 20),
            _buildFareInfoCard(),
            const SizedBox(height: 20),
            _buildSecurityInfo(),
            const SizedBox(height: 30),
            _buildBookTicketButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      decoration: AppTheme.createCardDecoration(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_filled,
            size: 56,
            color: AppTheme.getPrimaryTextColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Smart Ticketing System',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.getPrimaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Secure digital ticketing with location tracking',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelectionCard(BuildContext context) {
    return Container(
      decoration: AppTheme.createCardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Route',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.getPrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildStopDropdown(
            'From',
            _selectedFromStop,
            (value) => setState(() => _selectedFromStop = value),
            Icons.location_on,
          ),
          const SizedBox(height: 16),
          _buildStopDropdown(
            'To',
            _selectedToStop,
            (value) => setState(() => _selectedToStop = value),
            Icons.location_on,
          ),
          if (_selectedFromStop != null && _selectedToStop != null) ...[
            const SizedBox(height: 16),
            _buildRoutePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildStopDropdown(
    String label,
    String? selectedValue,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Text('Select ${label.toLowerCase()}'),
              isExpanded: true,
              items: BusStopsData.stopNames
                  .map((stopName) => DropdownMenuItem(
                        value: stopName,
                        child: Text(stopName),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePreview() {
    BusStop? sourceStop = BusStopsData.getStopByName(_selectedFromStop!);
    BusStop? destStop = BusStopsData.getStopByName(_selectedToStop!);
    
    if (sourceStop == null || destStop == null) return Container();
    
    int stops = (destStop.sequence - sourceStop.sequence).abs();
    double estimatedTime = stops * 5.0; // 5 minutes per stop
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Route Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stops: $stops'),
              Text('Est. Time: ${estimatedTime.toInt()} min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareInfoCard() {
    if (_selectedFromStop == null || _selectedToStop == null) {
      return SizedBox.shrink();
    }

    BusStop? sourceStop = BusStopsData.getStopByName(_selectedFromStop!);
    BusStop? destStop = BusStopsData.getStopByName(_selectedToStop!);
    
    if (sourceStop == null || destStop == null) return SizedBox.shrink();
    
    int stops = (destStop.sequence - sourceStop.sequence).abs();
    double fare = 10.0 + (stops * 5.0); // Base fare + per stop

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Fare Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Base Fare:'),
                Text('₹10.00'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance Charge ($stops stops):'),
                Text('₹${(stops * 5.0).toStringAsFixed(2)}'),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Fare:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '₹${fare.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Secure Digital Ticket',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Digital Ticket Features',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• QR code for easy verification', style: TextStyle(fontSize: 13)),
                  Text('• 2-hour validity period', style: TextStyle(fontSize: 13)),
                  Text('• Secure digital storage', style: TextStyle(fontSize: 13)),
                  Text('• Instant ticket generation', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.verified, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text(
                  'Secure and validated by Smart Ticket MTC',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookTicketButton() {
    bool canBook = _selectedFromStop != null && 
                   _selectedToStop != null && 
                   _selectedFromStop != _selectedToStop;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canBook && !_isLoading ? _bookTicket : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Book Ticket & Start Journey',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Future<void> _bookTicket() async {
    print('🎫 Starting ticket booking with location verification...');
    setState(() => _isLoading = true);
    
    double fare = 0.0;
    BusStop? sourceStop;
    BusStop? destStop;

    try {
      // Step 1: Validate selections
      print('📋 Step 1: Validating selections...');
      if (_selectedFromStop == null || _selectedToStop == null) {
        throw Exception('Please select both source and destination stops');
      }

      if (_selectedFromStop == _selectedToStop) {
        throw Exception('Source and destination cannot be the same');
      }

      // Step 2: Find selected stops
      print('🔍 Step 2: Finding bus stops...');
      sourceStop = BusStopsData.getStopByName(_selectedFromStop!);
      destStop = BusStopsData.getStopByName(_selectedToStop!);
      
      if (sourceStop == null || destStop == null) {
        throw Exception('Invalid bus stops selected');
      }

      // Step 3: Calculate fare
      print('💰 Step 3: Calculating fare...');
      int stops = (destStop.sequence - sourceStop.sequence).abs();
      fare = 10.0 + (stops * 5.0);
      print('✅ Fare calculated: ₹$fare for $stops stops');

      // Step 4: Location condition check
      print('📍 Step 4: Checking user location...');
      bool locationVerified = await _verifyUserLocation(sourceStop);
      
      if (!locationVerified) {
        // Show location verification failed, but allow to continue
        bool? continueAnyway = await _showLocationWarningDialog();
        if (continueAnyway != true) {
          print('❌ User cancelled due to location verification');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Step 5: Proceed to payment after location checks
      print('💳 Step 5: Proceeding to payment...');
      await _proceedToPayment(fare, sourceStop, destStop);

    } catch (e) {
      String errorMessage = e.toString();
      print('❌ Error in ticket booking: $errorMessage');
      
      // Check if this is a distance warning
      if (errorMessage.contains('DISTANCE_WARNING:')) {
        String warningMessage = errorMessage.replaceFirst('Exception: DISTANCE_WARNING:', '');
        
        // Show warning dialog with option to continue
        _showWarningDialog(
          '$warningMessage\n\nWould you like to proceed with booking the ticket?',
          () async {
            // User chose to continue despite distance warning
            print('✅ User confirmed to continue despite distance warning');
            await _proceedToPayment(fare, sourceStop!, destStop!);
          },
        );
      } else {
        // This is a real error
        _showErrorDialog('Booking Failed', errorMessage);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _verifyUserLocation(BusStop sourceStop) async {
    try {
      // Get current location
      LocationService locationService = LocationService();
      LocationPoint? currentLocation = await locationService.getCurrentLocation();
      
      if (currentLocation == null) {
        print('⚠️ Could not get current location');
        return false;
      }

      // Calculate distance to source stop using LocationService method
      LatLng sourceStopLocation = LatLng(sourceStop.latitude, sourceStop.longitude);
      double distance = locationService.calculateDistance(
        currentLocation.position,
        sourceStopLocation,
      );

      print('📏 Distance to ${sourceStop.name}: ${distance.toStringAsFixed(0)}m');

      // If too far from source stop, throw distance warning
      if (distance > 500) { // 500 meters threshold
        throw Exception('DISTANCE_WARNING:You are ${distance.toStringAsFixed(0)}m away from ${sourceStop.name}. For accurate ticket validation, please be closer to the bus stop.');
      }

      return true;
    } catch (e) {
      if (e.toString().contains('DISTANCE_WARNING:')) {
        rethrow; // Re-throw distance warnings
      }
      print('⚠️ Location verification error: $e');
      return false; // Return false for other location errors
    }
  }

  Future<void> _proceedToPayment(double fare, BusStop sourceStop, BusStop destStop) async {
    try {
      // Get user information for payment
      User? user = FirebaseAuth.instance.currentUser;
      String userName = user?.displayName ?? 'Smart Ticket User';
      String userEmail = user?.email ?? 'user@smartticket.com';
      String userPhone = user?.phoneNumber ?? '+919876543210';

      // Show payment confirmation
      bool? proceedWithPayment = await _showPaymentConfirmationDialog(fare);
      if (proceedWithPayment != true) {
        print('❌ User cancelled payment');
        return;
      }

      // Process payment with Razorpay
      print('💳 Processing payment...');
      await RazorpayService.payForTicket(
        context: context,
        ticketPrice: fare,
        ticketType: 'Regular',
        fromStation: _selectedFromStop!,
        toStation: _selectedToStop!,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        onPaymentSuccess: (paymentId) async {
          print('✅ Payment successful: $paymentId');
          await _handlePaymentSuccess(paymentId, sourceStop, destStop, fare);
        },
        onPaymentFailure: (error) {
          print('❌ Payment failed: $error');
          _handlePaymentFailure(error);
        },
      );
    } catch (e) {
      print('❌ Error in payment process: $e');
      _showErrorDialog('Payment Error', 'Failed to process payment: $e');
    }
  }

  Future<void> _handlePaymentSuccess(String paymentId, BusStop sourceStop, BusStop destStop, double fare) async {
    try {
      print('🎫 Payment successful, creating ticket...');
      
      // Create ticket after successful payment (skip location verification since we already did it)
      EnhancedTicket ticket = await EnhancedTicketService.issueTicketWithoutLocationCheck(
        sourceName: _selectedFromStop!,
        destinationName: _selectedToStop!,
        fare: fare,
        paymentId: paymentId, // Include payment ID
      );

      print('✅ Ticket issued successfully: ${ticket.ticketId}');
      
      // Add payment success notification
      await NotificationService().addPaymentNotification(
        paymentId: paymentId,
        amount: fare.toStringAsFixed(2),
        route: '$_selectedFromStop to $_selectedToStop',
      );
      
      String sessionId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';

      // Navigate to ticket display
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: sessionId,
            tripData: TripData(
              ticketId: ticket.ticketId,
              userId: 'demo_user_123',
              sourceName: _selectedFromStop!,
              destinationName: _selectedToStop!,
              startTime: DateTime.now(),
              sourceLocation: LatLng(sourceStop.latitude, sourceStop.longitude),
              destinationLocation: LatLng(destStop.latitude, destStop.longitude),
              status: TripStatus.active,
              gpsTrail: [],
              sensorData: [],
            ),
            connectionCode: null,
          ),
        ),
      );
      print('✅ Navigation completed');
    } catch (e) {
      print('❌ Error creating ticket after payment: $e');
      _showErrorDialog('Ticket Creation Failed', 
        'Payment was successful but ticket creation failed. Please contact support with payment ID: $paymentId');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentFailure(String error) {
    setState(() => _isLoading = false);
    _showErrorDialog('Payment Failed', 'Payment could not be processed: $error');
  }

  Future<bool?> _showPaymentConfirmationDialog(double fare) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
            Text('Journey Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('From: $_selectedFromStop'),
            Text('To: $_selectedToStop'),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Fare:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${fare.toStringAsFixed(2)}', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ],
            ),
            SizedBox(height: 16),
            Text('You will be redirected to Razorpay for secure payment processing.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payment, size: 16),
                SizedBox(width: 4),
                Text('Pay Now'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLocationWarningDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to verify your location near the bus stop.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text('This could be due to:'),
            Text('• GPS signal issues'),
            Text('• Location permissions'),
            Text('• Being too far from the stop'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'For best experience, please enable location and be near the bus stop.',
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
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
              print('❌ User cancelled ticket booking');
              Navigator.of(context).pop();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              print('✅ User chose to book anyway despite distance warning');
              Navigator.of(context).pop();
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
