import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_data_model.dart';
import '../models/enhanced_ticket_model.dart';
import '../models/bus_stop_model.dart';
import '../services/location_service.dart';
import '../services/enhanced_ticket_service.dart';
import '../data/bus_stops_data.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Bus Ticket'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 20),
            _buildRouteSelectionCard(),
            SizedBox(height: 20),
            _buildFareInfoCard(),
            SizedBox(height: 20),
            _buildSecurityInfo(),
            SizedBox(height: 30),
            _buildBookTicketButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.directions_bus,
              size: 48,
              color: Colors.blue,
            ),
            SizedBox(height: 12),
            Text(
              'Smart Ticketing System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Secure digital ticketing with location tracking',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSelectionCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Route',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildStopDropdown(
              'From',
              _selectedFromStop,
              (value) => setState(() => _selectedFromStop = value),
              Icons.location_on,
            ),
            SizedBox(height: 16),
            _buildStopDropdown(
              'To',
              _selectedToStop,
              (value) => setState(() => _selectedToStop = value),
              Icons.location_on,
            ),
            if (_selectedFromStop != null && _selectedToStop != null) ...[
              SizedBox(height: 16),
              _buildRoutePreview(),
            ],
          ],
        ),
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
    print('🎫 Starting simplified ticket booking...');
    setState(() => _isLoading = true);
    
    double fare = 0.0;
    String? sessionId;
    String? connectionCode; // Declare here so it's available in catch block

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
      BusStop? sourceStop = BusStopsData.getStopByName(_selectedFromStop!);
      BusStop? destStop = BusStopsData.getStopByName(_selectedToStop!);
      
      if (sourceStop == null || destStop == null) {
        throw Exception('Invalid bus stops selected.');
      }

      // Step 3: Calculate fare
      print('💰 Step 3: Calculating fare...');
      int stops = (destStop.sequence - sourceStop.sequence).abs();
      fare = 10.0 + (stops * 5.0);
      print('✅ Fare calculated: ₹$fare for $stops stops');

      // Step 4: Show consent dialog
      print('📝 Step 4: Getting user consent...');
      bool? proceedWithBooking = await _showSimpleConsentDialog();
      if (proceedWithBooking != true) {
        print('❌ User declined consent');
        setState(() => _isLoading = false);
        return;
      }
      print('✅ User provided consent');

      // Step 5: Create simple ticket data
      print('📊 Step 5: Creating ticket data...');
      String ticketId = _uuid.v4();
      String simpleSessionId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';
      
      print('✅ Ticket data created: $ticketId');

      // Step 6: Issue ticket directly (simplified process)
      print('🎫 Step 6: Issuing ticket...');
      EnhancedTicket ticket = await EnhancedTicketService.issueTicket(
        sourceName: _selectedFromStop!,
        destinationName: _selectedToStop!,
        fare: fare,
      );

      print('✅ Ticket issued successfully: ${ticket.ticketId}');

      // Step 7: Navigate to ticket display
      print('🚀 Step 7: Navigating to ticket display...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: simpleSessionId, // Use the definite non-null value
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
            connectionCode: null, // Simplified - no connection code needed
          ),
        ),
      );
      print('✅ Navigation completed');

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
            try {
              print('🎫 User confirmed to book despite distance warning');
              setState(() => _isLoading = true);
              
              // Issue ticket without location verification
              EnhancedTicket ticket = await EnhancedTicketService.issueTicketWithoutLocationCheck(
                sourceName: _selectedFromStop!,
                destinationName: _selectedToStop!,
                fare: fare,
              );

              ticket = ticket.copyWith(
                sessionId: sessionId,
                metadata: {
                  ...ticket.metadata,
                  'connectionCode': connectionCode,
                },
              );
              print('✅ Ticket issued with warning: ${ticket.ticketId}');

              // Navigate to ticket display screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketDisplayScreen(
                    ticket: ticket,
                    sessionId: sessionId ?? 'fallback_session',
                    connectionCode: connectionCode,
                    tripData: TripData(
                      ticketId: ticket.ticketId,
                      userId: 'demo_user_123',
                      sourceName: _selectedFromStop!,
                      destinationName: _selectedToStop!,
                      startTime: DateTime.now(),
                      sourceLocation: LatLng(0, 0),
                      destinationLocation: LatLng(0, 0),
                      status: TripStatus.active,
                      gpsTrail: [],
                      sensorData: [],
                    ),
                  ),
                ),
              );
            } catch (innerE) {
              print('❌ Error in ticket booking after warning: $innerE');
              _showErrorDialog('Failed to book ticket after warning: $innerE');
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          },
        );
      } else {
        // This is a real error
        _showErrorDialog('Failed to book ticket: $errorMessage');
      }
    } finally {
      // Always ensure loading is stopped
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showSimpleConsentDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.confirmation_number, color: Colors.blue),
            SizedBox(width: 8),
            Text('Ticket Booking Confirmation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please confirm your ticket booking:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route: $_selectedFromStop → $_selectedToStop'),
                  Text('Fare: ₹${_estimatedFare.toStringAsFixed(0)}'),
                  Text('Validity: 2 hours from booking'),
                  SizedBox(height: 8),
                  Text(
                    'You agree to:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text('• Use ticket for intended journey only'),
                  Text('• Present QR code when requested'),
                  Text('• Follow MTC guidelines'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Confirm & Book', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
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
