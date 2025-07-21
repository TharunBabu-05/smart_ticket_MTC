import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_data_model.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../data/bus_stops_data.dart';
import 'journey_tracking_screen.dart';

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
    print('Starting ticket booking process...');
    setState(() => _isLoading = true);

    try {
      // Get current location for verification with timeout
      LocationPoint? currentLocation;
      try {
        currentLocation = await _locationService.getCurrentLocation()
            .timeout(Duration(seconds: 10));
      } catch (e) {
        print('Location timeout or error: $e');
        // Continue without location verification for now
        currentLocation = null;
      }
      
      if (currentLocation == null) {
        // Show warning but allow booking to continue
        print('Warning: Unable to verify location, proceeding with booking');
      }

      // Find selected stops
      BusStop? sourceStop = BusStopsData.getStopByName(_selectedFromStop!);
      BusStop? destStop = BusStopsData.getStopByName(_selectedToStop!);
      
      if (sourceStop == null || destStop == null) {
        _showErrorDialog('Invalid bus stops selected.');
        return;
      }

      // Verify user is near source stop (only if location is available)
      if (currentLocation != null) {
        double distanceToSource = _locationService.calculateDistance(
          currentLocation.position,
          sourceStop.location,
        );

        if (distanceToSource > 500) { // 500 meters tolerance
          bool? proceed = await _showLocationWarningDialog(distanceToSource);
          if (proceed != true) return;
        }
      }

      // Create trip data
      String ticketId = _uuid.v4();
      TripData tripData = TripData(
        ticketId: ticketId,
        userId: 'user_123', // In production, get from authentication
        startTime: DateTime.now(),
        sourceLocation: sourceStop.location,
        destinationLocation: destStop.location,
        sourceName: sourceStop.name,
        destinationName: destStop.name,
        status: TripStatus.active,
      );

      // Save initial trip data with timeout
      try {
        await FirebaseService.saveTripData(tripData)
            .timeout(Duration(seconds: 5));
        print('Trip data saved successfully');
      } catch (e) {
        print('Warning: Failed to save trip data to Firebase: $e');
        // Continue with booking even if Firebase save fails
      }

      // Navigate to journey tracking
      print('Navigating to journey tracking screen...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JourneyTrackingScreen(tripData: tripData),
        ),
      );
      print('Navigation completed successfully');

    } catch (e) {
      print('Error in _bookTicket: $e');
      _showErrorDialog('Failed to book ticket: $e');
    } finally {
      print('Resetting loading state...');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
}
