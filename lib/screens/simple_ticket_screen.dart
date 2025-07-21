import 'package:flutter/material.dart';
import '../models/trip_data_model.dart';

class SimpleTicketScreen extends StatefulWidget {
  final TripData tripData;
  
  const SimpleTicketScreen({Key? key, required this.tripData}) : super(key: key);
  
  @override
  _SimpleTicketScreenState createState() => _SimpleTicketScreenState();
}

class _SimpleTicketScreenState extends State<SimpleTicketScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Ticket'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTicketCard(),
            SizedBox(height: 20),
            _buildStatusCard(),
            SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard() {
    return Card(
      elevation: 8,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'Bus Ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildTicketRow('From:', widget.tripData.sourceName ?? 'Unknown'),
            SizedBox(height: 8),
            _buildTicketRow('To:', widget.tripData.destinationName ?? 'Unknown'),
            SizedBox(height: 8),
            _buildTicketRow('Ticket ID:', widget.tripData.ticketId.substring(0, 8)),
            SizedBox(height: 8),
            _buildTicketRow('Time:', _formatTime(widget.tripData.startTime)),
            SizedBox(height: 8),
            _buildTicketRow('Status:', widget.tripData.status.toString().split('.').last.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Journey Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Your ticket has been generated successfully!',
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            SizedBox(height: 8),
            Text(
              'Please show this ticket to the conductor when requested.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to full journey tracking
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => _buildJourneyTrackingLoader(),
                ),
              );
            },
            icon: Icon(Icons.gps_fixed),
            label: Text('Start GPS Tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.home),
            label: Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyTrackingLoader() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Starting Journey Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Initializing GPS and sensors...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'This may take a few moments',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
