import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_data_model.dart';
import '../models/enhanced_ticket_model.dart';
import '../models/bus_stop_model.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../services/enhanced_ticket_service.dart';
import '../data/bus_stops_data.dart';
import 'journey_tracking_screen.dart';
import 'simple_ticket_screen.dart';
import 'enhanced_ticket_screen.dart';

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
    print('Starting enhanced ticket booking process...');
    setState(() => _isLoading = true);
    
    double fare = 0.0; // Initialize fare variable

    try {
      // Validate selections
      if (_selectedFromStop == null || _selectedToStop == null) {
        throw Exception('Please select both source and destination stops');
      }

      if (_selectedFromStop == _selectedToStop) {
        throw Exception('Source and destination cannot be the same');
      }

      // Find selected stops
      BusStop? sourceStop = BusStopsData.getStopByName(_selectedFromStop!);
      BusStop? destStop = BusStopsData.getStopByName(_selectedToStop!);
      
      if (sourceStop == null || destStop == null) {
        throw Exception('Invalid bus stops selected.');
      }

      // Calculate fare
      int stops = (destStop.sequence - sourceStop.sequence).abs();
      fare = 10.0 + (stops * 5.0); // Base fare + per stop

      // Show location warning and get consent
      bool? proceedWithBooking = await _showLocationConsentDialog();
      if (proceedWithBooking != true) {
        setState(() => _isLoading = false);
        return;
      }

      // Issue enhanced ticket
      EnhancedTicket ticket = await EnhancedTicketService.issueTicket(
        sourceName: _selectedFromStop!,
        destinationName: _selectedToStop!,
        fare: fare,
      );

      print('Enhanced ticket issued successfully: ${ticket.ticketId}');

      // Navigate to enhanced ticket screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedTicketScreen(ticket: ticket),
        ),
      );

    } catch (e) {
      String errorMessage = e.toString();
      
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

              print('✅ Enhanced ticket issued successfully with distance warning: ${ticket.ticketId}');

              // Navigate to enhanced ticket screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EnhancedTicketScreen(ticket: ticket),
                ),
              );
            } catch (innerE) {
              print('❌ Error in enhanced ticket booking after warning: $innerE');
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
        print('Error in enhanced ticket booking: $e');
        _showErrorDialog('Failed to book ticket: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showLocationConsentDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('Location Tracking Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This ticket requires location tracking for 2 hours to prevent fraud and ensure proper validation.',
              style: TextStyle(fontSize: 16),
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
                  Text('What this means:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Location must remain ON for ticket validity'),
                  Text('• Your journey will be monitored for fraud detection'),
                  Text('• Data is shared with gyro comparator system'),
                  Text('• Penalties apply for fare evasion'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Accept & Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLocationWarningDialog(double distance) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Warning'),
          ],
        ),
        content: Text(
          'You are ${(distance / 1000).toStringAsFixed(1)} km away from the source stop. '
          'Please ensure you are at the correct bus stop before starting your journey.\n\n'
          'Do you want to continue anyway?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Continue'),
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
