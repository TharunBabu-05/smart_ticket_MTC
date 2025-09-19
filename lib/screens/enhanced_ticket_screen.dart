import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:async';
import '../models/enhanced_ticket_model.dart';
import '../models/trip_data_model.dart' as trip;
import '../services/enhanced_ticket_service.dart';
import '../services/fraud_detection_service_new.dart';
import '../themes/app_theme.dart';
import 'journey_tracking_screen.dart';

class EnhancedTicketScreen extends StatefulWidget {
  final EnhancedTicket ticket;

  const EnhancedTicketScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  _EnhancedTicketScreenState createState() => _EnhancedTicketScreenState();
}

class _EnhancedTicketScreenState extends State<EnhancedTicketScreen>
    with TickerProviderStateMixin {
  late EnhancedTicket _currentTicket;
  Timer? _updateTimer;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  bool _locationWarningShown = false;
  bool _userInBus = false;
  bool _isDataStreaming = false;
  StreamSubscription<bool>? _busStatusSubscription;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _startRealTimeUpdates();
    _listenToBusStatus();
    _checkLocationServices();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _busStatusSubscription?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild for real-time updates
        });

        // Check if ticket expired
        if (!_currentTicket.isValid) {
          _showTicketExpiredDialog();
          timer.cancel();
        }

        // Update progress animation
        _progressController.animateTo(_currentTicket.validityPercentage);
      }
    });
  }

  void _listenToBusStatus() {
    _busStatusSubscription = FraudDetectionService
        .getUserInBusStatus(_currentTicket.sessionId)
        .listen((inBus) {
      if (mounted) {
        setState(() {
          _userInBus = inBus;
        });
      }
    });
  }

  Future<void> _checkLocationServices() async {
    // Check location services every 30 seconds
    Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        Location location = Location();
        bool serviceEnabled = await location.serviceEnabled();
        
        if (!serviceEnabled && !_locationWarningShown) {
          _showLocationWarning();
          _locationWarningShown = true;
        } else if (serviceEnabled) {
          _locationWarningShown = false;
        }
      } catch (e) {
        print('Error checking location services: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: 'Your Ticket',
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: _showTicketInfo,
        ),
      ],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getTicketStatusColor(),
              _getTicketStatusColor().withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTicketCard(),
              SizedBox(height: 20),
              _buildValidityCard(),
              SizedBox(height: 20),
              _buildLocationStatusCard(),
              SizedBox(height: 20),
              _buildBusStatusCard(),
              SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getTicketStatusColor(),
              _getTicketStatusColor().withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Bus Ticket',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'MTC Enhanced System',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Route Information
            Row(
              children: [
                Expanded(
                  child: _buildRoutePoint(_currentTicket.sourceName, 'FROM', Icons.radio_button_checked),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRoutePoint(_currentTicket.destinationName, 'TO', Icons.location_on),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Ticket Details
            Row(
              children: [
                Expanded(
                  child: _buildTicketDetail('Ticket ID', _currentTicket.ticketId.substring(4, 12)),
                ),
                Expanded(
                  child: _buildTicketDetail('Fare', '₹${_currentTicket.fare.toStringAsFixed(2)}'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTicketDetail('Issue Time', _formatTime(_currentTicket.issueTime)),
                ),
                Expanded(
                  child: _buildTicketDetail('Valid Until', _formatTime(_currentTicket.validUntil)),
                ),
              ],
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildValidityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _currentTicket.isValid ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        _currentTicket.isValid ? Icons.check_circle : Icons.cancel,
                        color: _currentTicket.isValid ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Validity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentTicket.isValid 
                            ? 'Remaining: ${_currentTicket.formattedRemainingTime}'
                            : 'Ticket Expired',
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentTicket.isValid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _currentTicket.validityPercentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentTicket.validityPercentage > 0.3 ? Colors.green : Colors.red,
                    ),
                    minHeight: 8,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: _currentTicket.locationTrackingEnabled ? Colors.green : Colors.red,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentTicket.locationTrackingEnabled 
                        ? 'Active - Required for validation'
                        : 'Disabled - Please enable location services',
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentTicket.locationTrackingEnabled ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (!_currentTicket.locationTrackingEnabled)
              TextButton(
                onPressed: _openLocationSettings,
                child: Text('Enable'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _userInBus ? Icons.directions_bus : Icons.directions_walk,
              color: _userInBus ? Colors.blue : Colors.orange,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journey Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userInBus 
                        ? 'You are in the bus - Journey monitored'
                        : 'Waiting for bus boarding detection',
                    style: TextStyle(
                      fontSize: 14,
                      color: _userInBus ? Colors.blue : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            if (_userInBus)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'IN BUS',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_currentTicket.isValid && _userInBus) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startDetailedTracking,
              icon: Icon(Icons.gps_fixed),
              label: Text('Start Detailed Journey Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
        ],
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _completeJourney,
            icon: Icon(Icons.exit_to_app),
            label: Text('Complete Journey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.home),
            label: Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePoint(String location, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          location,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTicketDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getTicketStatusColor() {
    if (!_currentTicket.isValid) return Colors.red;
    if (_currentTicket.validityPercentage < 0.3) return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText() {
    if (!_currentTicket.isValid) return 'EXPIRED';
    if (_userInBus) return 'IN TRANSIT';
    return 'ACTIVE';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showTicketInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session ID: ${_currentTicket.sessionId}'),
            SizedBox(height: 8),
            Text('Type: ${_currentTicket.ticketType.toString().split('.').last}'),
            SizedBox(height: 8),
            Text('Cross-platform tracking: ${_isDataStreaming ? 'Active' : 'Inactive'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTicketExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Ticket Expired'),
          ],
        ),
        content: Text(
          'Your ticket has expired. The 2-hour validity period has ended. '
          'Please book a new ticket for further travel.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationWarning() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Required'),
          ],
        ),
        content: Text(
          'Location services are required for ticket validation. '
          'Please enable location services to continue. Your ticket may be flagged if location remains disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openLocationSettings();
            },
            child: Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  void _openLocationSettings() {
    // In production, use app_settings package to open location settings
    print('Opening location settings...');
  }

  void _startDetailedTracking() {
    // Convert to TripData for existing tracking screen
    trip.TripData tripData = trip.TripData(
      ticketId: _currentTicket.ticketId,
      userId: _currentTicket.userId,
      startTime: _currentTicket.issueTime,
      sourceLocation: trip.LatLng(_currentTicket.sourceLocation.latitude, _currentTicket.sourceLocation.longitude),
      destinationLocation: trip.LatLng(_currentTicket.destinationLocation.latitude, _currentTicket.destinationLocation.longitude),
      sourceName: _currentTicket.sourceName,
      destinationName: _currentTicket.destinationName,
      status: trip.TripStatus.active,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyTrackingScreen(tripData: tripData),
      ),
    );
  }

  void _completeJourney() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Journey'),
        content: Text('Are you sure you want to complete your journey? This will analyze your trip for any violations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processJourneyCompletion();
            },
            child: Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _processJourneyCompletion() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Complete the ticket
      Map<String, dynamic> result = await EnhancedTicketService.completeTicket(
        _currentTicket.ticketId,
        _currentTicket.destinationName, // In production, let user select actual exit
      );

      Navigator.pop(context); // Close loading

      // Show result
      _showCompletionResult(result);

    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing journey: $e')),
      );
    }
  }

  void _showCompletionResult(Map<String, dynamic> result) {
    bool isFraud = result['isFraud'] ?? false;
    double penalty = result['penaltyAmount']?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isFraud ? Icons.warning : Icons.check_circle,
              color: isFraud ? Colors.red : Colors.green,
            ),
            SizedBox(width: 8),
            Text(isFraud ? 'Violation Detected' : 'Journey Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFraud) ...[
              Text('A fare violation has been detected.'),
              SizedBox(height: 8),
              Text('Extra stops: ${result['extraStops'] ?? 0}'),
              Text('Penalty: ₹${penalty.toStringAsFixed(2)}'),
            ] else ...[
              Text('Your journey has been completed successfully with no violations detected.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
