import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_data_model.dart';
import '../models/enhanced_ticket_model.dart';
import '../models/bus_stop_model.dart';
import '../services/location_service.dart';
import '../services/enhanced_ticket_service.dart';
import '../services/fraud_detection_service_new.dart';
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
            _buildFraudDetectionInfo(),
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
              'Advanced fraud detection with GPS and sensor monitoring',
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

  Widget _buildFraudDetectionInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Fraud Detection System',
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Anti-Fraud Monitoring Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• Your phone sensors will be monitored', style: TextStyle(fontSize: 13)),
                  Text('• GPS location tracking enabled', style: TextStyle(fontSize: 13)),
                  Text('• Data synced with bus gyroscope system', style: TextStyle(fontSize: 13)),
                  Text('• Penalty: ₹5 per extra stop if fraud detected', style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sync, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text(
                  'Connected to Gyro-Comparator System via unique code',
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
    print('🎫 Starting ticket booking with cross-platform fraud detection...');
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
      bool? proceedWithBooking = await _showEnhancedConsentDialog();
      if (proceedWithBooking != true) {
        print('❌ User declined consent');
        setState(() => _isLoading = false);
        return;
      }
      print('✅ User provided consent');

      // Step 5: Create trip data
      print('📊 Step 5: Creating trip data...');
      TripData tripData = TripData(
        ticketId: _uuid.v4(),
        userId: 'demo_user_123', // In production, get from auth
        sourceName: _selectedFromStop!,
        destinationName: _selectedToStop!,
        startTime: DateTime.now(),
        sourceLocation: LatLng(sourceStop.latitude, sourceStop.longitude),
        destinationLocation: LatLng(destStop.latitude, destStop.longitude),
        status: TripStatus.active,
        gpsTrail: [],
        sensorData: [],
      );
      print('✅ Trip data created');

      // Step 6: Initialize fraud detection service and create session
      print('🔧 Step 6: Initializing fraud detection service...');
      try {
        await FraudDetectionService.initialize();
        print('✅ Fraud detection service initialized');
        
        // Create ticket with fraud detection (now returns connection data)
        print('🔗 Creating ticket with fraud detection...');
        Map<String, String> connectionData = await FraudDetectionService.createTicketWithFraudDetection(tripData);
        sessionId = connectionData['sessionId'] ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}';
        connectionCode = connectionData['connectionCode'];
        
        print('✅ Session created with ID: $sessionId');
        if (connectionCode != null) {
          print('� Connection code generated: $connectionCode');
          print('📱 Gyro-comparator app can use this code to connect');
        }
      } catch (e) {
        print('⚠️ Warning: Cross-platform service failed: $e');
        sessionId = 'fallback_session_${DateTime.now().millisecondsSinceEpoch}';
        print('📝 Using fallback session ID: $sessionId');
        
        // Show user a warning but continue with booking
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Advanced fraud detection unavailable. Basic ticket issued.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Step 7: Issue ticket (store in main database)
      print('🎫 Step 7: Issuing enhanced ticket...');
      EnhancedTicket ticket = await EnhancedTicketService.issueTicket(
        sourceName: _selectedFromStop!,
        destinationName: _selectedToStop!,
        fare: fare,
      );

      // Update ticket with session ID and connection code
      ticket = ticket.copyWith(
        sessionId: sessionId,
        metadata: {
          ...ticket.metadata,
          'connectionCode': connectionCode,
        },
      );
      print('✅ Enhanced ticket issued: ${ticket.ticketId}');
      print('🔗 Linked to session: $sessionId');
      if (connectionCode != null) {
        print('🔑 Connection code: $connectionCode');
      }

      // Step 8: Navigate to ticket display
      print('🚀 Step 8: Navigating to ticket display...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: sessionId!,
            tripData: tripData,
            connectionCode: connectionCode,
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

  Future<bool?> _showEnhancedConsentDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 8),
            Text('Fraud Detection Consent'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This ticket uses advanced fraud detection to prevent fare evasion.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                    Text('📱 What we monitor:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• GPS location for 2 hours'),
                    Text('• Phone gyroscope & accelerometer'),
                    Text('• Movement patterns to detect bus travel'),
                    Text('• Exit stop verification'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚌 Cross-Platform Sync:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Data shared with bus gyroscope system'),
                    Text('• Real-time sensor comparison'),
                    Text('• Automatic fraud detection'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️ Penalties:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                    SizedBox(height: 8),
                    Text('• ₹5 penalty per extra stop traveled', style: TextStyle(color: Colors.red[700])),
                    Text('• Automatic detection of fare evasion', style: TextStyle(color: Colors.red[700])),
                    Text('• No appeals for verified violations', style: TextStyle(color: Colors.red[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Accept & Start Monitoring'),
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
