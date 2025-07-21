import 'package:flutter/material.dart';
import '../models/trip_data_model.dart';
import '../models/fraud_analysis_model.dart';

class TripCompletionScreen extends StatelessWidget {
  final TripData tripData;
  final FraudAnalysis analysis;
  final bool userConfirmedExit;

  const TripCompletionScreen({
    Key? key,
    required this.tripData,
    required this.analysis,
    this.userConfirmedExit = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Completed'),
        backgroundColor: _getStatusColor(),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompletionHeader(),
            SizedBox(height: 20),
            _buildTripSummary(),
            SizedBox(height: 20),
            _buildFraudAnalysisCard(),
            SizedBox(height: 20),
            _buildJourneyStats(),
            if (analysis.detectedIssues.isNotEmpty) ...[
              SizedBox(height: 20),
              _buildIssuesCard(),
            ],
            SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(),
              size: 64,
              color: _getStatusColor(),
            ),
            SizedBox(height: 12),
            Text(
              _getStatusTitle(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _getStatusMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    Duration tripDuration = tripData.endTime!.difference(tripData.startTime);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildSummaryRow('Route', '${tripData.sourceName} → ${tripData.destinationName}'),
            _buildSummaryRow('Duration', _formatDuration(tripDuration)),
            _buildSummaryRow('Started', _formatDateTime(tripData.startTime)),
            _buildSummaryRow('Ended', _formatDateTime(tripData.endTime!)),
            _buildSummaryRow('Exit Confirmed', userConfirmedExit ? 'Yes' : 'Auto-detected'),
          ],
        ),
      ),
    );
  }

  Widget _buildFraudAnalysisCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Fraud Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildAnalysisRow('Risk Level', analysis.fraudRiskLevel, _getRiskColor()),
            _buildAnalysisRow('Confidence Score', '${(analysis.fraudConfidence * 100).toInt()}%', _getRiskColor()),
            _buildAnalysisRow('Transport Mode', _getTransportModeDisplay(analysis.detectedTransportMode), null),
            _buildAnalysisRow('Speed Analysis', analysis.speedAnalysis ? 'Passed' : 'Failed', analysis.speedAnalysis ? Colors.green : Colors.orange),
            _buildAnalysisRow('Stop Analysis', analysis.stopAnalysis ? 'Passed' : 'Failed', analysis.stopAnalysis ? Colors.green : Colors.orange),
            _buildAnalysisRow('Route Deviation', '${analysis.routeDeviation.toInt()}m', analysis.routeDeviation > 200 ? Colors.orange : Colors.green),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRiskColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRiskColor().withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(analysis.recommendationDescription),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyStats() {
    double totalDistance = 0.0;
    double avgSpeed = 0.0;
    int gpsPoints = tripData.gpsTrail.length;
    int sensorReadings = tripData.sensorData.length;

    if (tripData.gpsTrail.isNotEmpty) {
      // Calculate total distance
      for (int i = 1; i < tripData.gpsTrail.length; i++) {
        totalDistance += _calculateDistance(
          tripData.gpsTrail[i - 1].position,
          tripData.gpsTrail[i].position,
        );
      }

      // Calculate average speed
      avgSpeed = tripData.gpsTrail
          .map((point) => point.speed)
          .reduce((a, b) => a + b) / tripData.gpsTrail.length;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Distance',
                    '${(totalDistance / 1000).toStringAsFixed(2)} km',
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Avg Speed',
                    '${avgSpeed.toStringAsFixed(1)} km/h',
                    Icons.speed,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'GPS Points',
                    '$gpsPoints',
                    Icons.gps_fixed,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Sensor Data',
                    '$sensorReadings',
                    Icons.sensors,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Detected Issues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...analysis.detectedIssues.map((issue) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text(issue)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Back to Home', style: TextStyle(fontSize: 16)),
          ),
        ),
        if (analysis.fraudConfidence > 0.4) ...[
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showAppealDialog(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Appeal Decision', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showAppealDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appeal Decision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('If you believe this fraud detection is incorrect, you can appeal the decision.'),
            SizedBox(height: 8),
            Text('Your case will be reviewed by a conductor who can override the system decision.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitAppeal(context);
            },
            child: Text('Submit Appeal'),
          ),
        ],
      ),
    );
  }

  void _submitAppeal(BuildContext context) {
    // In a real app, this would submit an appeal to the backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appeal submitted successfully. You will be notified of the decision.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getStatusColor() {
    if (analysis.fraudConfidence < 0.3) return Colors.green;
    if (analysis.fraudConfidence < 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (analysis.fraudConfidence < 0.3) return Icons.check_circle;
    if (analysis.fraudConfidence < 0.6) return Icons.warning;
    return Icons.error;
  }

  String _getStatusTitle() {
    if (analysis.fraudConfidence < 0.3) return 'Trip Verified';
    if (analysis.fraudConfidence < 0.6) return 'Trip Flagged';
    return 'Fraud Detected';
  }

  String _getStatusMessage() {
    if (analysis.fraudConfidence < 0.3) {
      return 'Your journey appears legitimate. Thank you for using our service!';
    } else if (analysis.fraudConfidence < 0.6) {
      return 'Some irregularities detected. This will be reviewed.';
    } else {
      return 'Significant fraud indicators detected. This case requires investigation.';
    }
  }

  Color _getRiskColor() {
    if (analysis.fraudConfidence < 0.3) return Colors.green;
    if (analysis.fraudConfidence < 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getTransportModeDisplay(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.bike:
        return 'Bike';
      case TransportMode.car:
        return 'Car';
      case TransportMode.walking:
        return 'Walking';
      case TransportMode.unknown:
        return 'Unknown';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '${hours}h ${minutes}m';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simplified distance calculation
    double dx = point1.latitude - point2.latitude;
    double dy = point1.longitude - point2.longitude;
    return (dx * dx + dy * dy) * 111000; // Rough conversion to meters
  }
}
