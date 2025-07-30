import 'package:flutter/material.dart';
import '../services/fraud_detection_service_new.dart';
import '../services/enhanced_ticket_service.dart';
import '../models/enhanced_ticket_model.dart';

class DemoTestScreen extends StatefulWidget {
  @override
  _DemoTestScreenState createState() => _DemoTestScreenState();
}

class _DemoTestScreenState extends State<DemoTestScreen> {
  String _sessionId = '';
  bool _isStreaming = false;
  bool _userInBus = false;
  Map<String, dynamic> _testResults = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo Test - Cross Platform'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Ticket Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            _buildInfoCard(),
            SizedBox(height: 20),
            
            _buildTestButtons(),
            SizedBox(height: 20),
            
            _buildStatusCards(),
            SizedBox(height: 20),
            
            _buildTestResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('Demo Information', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            Text('• This app acts as the user/passenger device'),
            Text('• Gyro Comparator app acts as the bus device'),
            Text('• Data is synced via Firebase Realtime Database'),
            Text('• URL: https://gyre-compare-default-rtdb.firebaseio.com/'),
            SizedBox(height: 8),
            Text('Session ID: $_sessionId', style: TextStyle(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isStreaming ? null : _startDemo,
            icon: Icon(Icons.play_arrow),
            label: Text('Start Demo Session'),
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
          child: ElevatedButton.icon(
            onPressed: !_isStreaming ? null : _stopDemo,
            icon: Icon(Icons.stop),
            label: Text('Stop Demo Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _simulateFraud,
            icon: Icon(Icons.warning),
            label: Text('Simulate Fraud Detection'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: _isStreaming ? Colors.green.shade50 : Colors.grey.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _isStreaming ? Icons.stream : Icons.stream_outlined,
                    color: _isStreaming ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Data Streaming',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _isStreaming ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _isStreaming ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Card(
            color: _userInBus ? Colors.blue.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _userInBus ? Icons.directions_bus : Icons.directions_walk,
                    color: _userInBus ? Colors.blue : Colors.orange,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bus Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _userInBus ? 'In Bus' : 'Walking',
                    style: TextStyle(
                      color: _userInBus ? Colors.blue : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestResults() {
    if (_testResults.isEmpty) {
      return Container();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ..._testResults.entries.map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _startDemo() async {
    try {
      setState(() {
        _isStreaming = true;
      });

      // Create a demo ticket
      EnhancedTicket demoTicket = await EnhancedTicketService.issueTicket(
        sourceName: 'Central Station',
        destinationName: 'Marina Beach',
        fare: 25.0,
      );

      setState(() {
        _sessionId = demoTicket.sessionId;
      });

      // Listen for bus status updates
      FraudDetectionService.getUserInBusStatus(_sessionId).listen((inBus) {
        setState(() {
          _userInBus = inBus;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo started! Session: $_sessionId'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() {
        _isStreaming = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo start failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopDemo() async {
    try {
      await FraudDetectionService.stopDataStreaming();
      
      setState(() {
        _isStreaming = false;
        _userInBus = false;
        _sessionId = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo stopped successfully'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo stop failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _simulateFraud() async {
    if (_sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start demo session first')),
      );
      return;
    }

    try {
      // Simulate fraud analysis
      Map<String, dynamic> fraudResult = await FraudDetectionService.analyzeFraudAtExit(
        _sessionId,
        'ticket_123', // ticket ID
        'user_123',   // user ID
      );

      setState(() {
        _testResults = fraudResult;
      });

      bool isFraud = fraudResult['isFraud'] ?? false;
      
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
              Text(isFraud ? 'Fraud Detected!' : 'No Fraud'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFraud) ...[
                Text('Penalty: ₹${fraudResult['penaltyAmount']?.toStringAsFixed(2) ?? '0'}'),
                Text('Extra stops: ${fraudResult['extraStops'] ?? 0}'),
              ] else ...[
                Text('Journey completed legitimately'),
              ],
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

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fraud simulation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
