import 'package:flutter/material.dart';
import '../models/trip_data_model.dart';
import '../models/fraud_analysis_model.dart';
import '../services/firebase_service.dart';

class ConductorVerificationScreen extends StatefulWidget {
  @override
  _ConductorVerificationScreenState createState() => _ConductorVerificationScreenState();
}

class _ConductorVerificationScreenState extends State<ConductorVerificationScreen> {
  List<FraudAlert> _pendingAlerts = [];
  List<TripData> _activeTrips = [];
  bool _isLoading = true;
  String _selectedTab = 'alerts';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load fraud alerts and active trips
      FirebaseService.getFraudAlertsStream().listen((alerts) {
        setState(() {
          _pendingAlerts = alerts;
        });
      });
      
      FirebaseService.getActiveTripStream().listen((trips) {
        setState(() {
          _activeTrips = trips;
        });
      });
      
    } catch (e) {
      _showErrorDialog('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conductor Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _selectedTab == 'alerts'
                    ? _buildFraudAlertsTab()
                    : _buildActiveTripsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Fraud Alerts',
              'alerts',
              _pendingAlerts.length,
              Icons.warning,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Active Trips',
              'trips',
              _activeTrips.length,
              Icons.directions_bus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, String tabId, int count, IconData icon) {
    bool isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFraudAlertsTab() {
    if (_pendingAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Pending Fraud Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'All trips are currently verified',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _pendingAlerts.length,
      itemBuilder: (context, index) {
        return _buildFraudAlertCard(_pendingAlerts[index]);
      },
    );
  }

  Widget _buildFraudAlertCard(FraudAlert alert) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getFraudConfidenceColor(alert.fraudConfidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(alert.fraudConfidence * 100).toInt()}% Risk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  _formatTime(alert.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Trip ID: ${alert.tripId.substring(0, 8)}...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'User ID: ${alert.userId}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Detected Issues:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            ...alert.detectedIssues.map((issue) => Padding(
              padding: EdgeInsets.only(left: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(child: Text(issue, style: TextStyle(fontSize: 14))),
                ],
              ),
            )).toList(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolveAlert(alert, FraudAlertStatus.falsePositive),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green),
                    ),
                    child: Text('Mark as False Positive'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _resolveAlert(alert, FraudAlertStatus.resolved),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Confirm Fraud'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripsTab() {
    if (_activeTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_filled, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Active Trips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'No passengers are currently traveling',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _activeTrips.length,
      itemBuilder: (context, index) {
        return _buildActiveTripCard(_activeTrips[index]);
      },
    );
  }

  Widget _buildActiveTripCard(TripData trip) {
    Duration tripDuration = DateTime.now().difference(trip.startTime);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Trip ${trip.ticketId.substring(0, 8)}...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildTripDetailRow('Route', '${trip.sourceName} → ${trip.destinationName}'),
            _buildTripDetailRow('User ID', trip.userId),
            _buildTripDetailRow('Started', _formatTime(trip.startTime)),
            _buildTripDetailRow('Duration', _formatDuration(tripDuration)),
            _buildTripDetailRow('GPS Points', '${trip.gpsTrail.length}'),
            if (trip.fraudConfidence != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Text('Fraud Risk: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getFraudConfidenceColor(trip.fraudConfidence!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(trip.fraudConfidence! * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _verifyTrip(trip),
                child: Text('Manual Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label + ':',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveAlert(FraudAlert alert, FraudAlertStatus status) async {
    try {
      String resolution = status == FraudAlertStatus.falsePositive
          ? 'Marked as false positive by conductor'
          : 'Confirmed as fraud by conductor';
      
      await FirebaseService.updateFraudAlert(
        alert.alertId,
        status,
        resolvedBy: 'conductor_123', // In production, get from authentication
        resolution: resolution,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert resolved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      _showErrorDialog('Failed to resolve alert: $e');
    }
  }

  Future<void> _verifyTrip(TripData trip) async {
    bool? shouldVerify = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Verification'),
        content: Text(
          'Are you sure you want to manually verify this trip as legitimate?\n\n'
          'This will override any fraud detection results.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Verify'),
          ),
        ],
      ),
    );
    
    if (shouldVerify == true) {
      try {
        await FirebaseService.updateTripStatus(trip.ticketId, TripStatus.verified);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
      } catch (e) {
        _showErrorDialog('Failed to verify trip: $e');
      }
    }
  }

  Color _getFraudConfidenceColor(double confidence) {
    if (confidence < 0.3) return Colors.green;
    if (confidence < 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '${hours}h ${minutes}m';
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
