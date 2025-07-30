import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/enhanced_ticket_model.dart';
import '../models/trip_data_model.dart';
import '../services/cross_platform_service.dart';

class FraudDemoScreen extends StatefulWidget {
  final EnhancedTicket ticket;
  final String sessionId;
  final TripData tripData;

  const FraudDemoScreen({
    Key? key,
    required this.ticket,
    required this.sessionId,
    required this.tripData,
  }) : super(key: key);

  @override
  _FraudDemoScreenState createState() => _FraudDemoScreenState();
}

class _FraudDemoScreenState extends State<FraudDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _syncController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _syncAnimation;

  Timer? _demoTimer;
  bool _userInBus = false;
  bool _isStreaming = false;
  int _currentStop = 0;
  int _plannedExitStop = 6;
  Map<String, dynamic> _sensorData = {};
  Map<String, dynamic> _fraudAnalysis = {};
  String _demoPhase = 'boarding'; // boarding, traveling, exit_detection, fraud_analysis

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startDemo();
    _extractPlannedExit();
  }

  void _extractPlannedExit() {
    // Extract stop number from destination name
    String destination = widget.ticket.destinationName;
    RegExp regex = RegExp(r'\d+');
    Match? match = regex.firstMatch(destination);
    if (match != null) {
      _plannedExitStop = int.parse(match.group(0)!);
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _syncController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _syncAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _syncController, curve: Curves.linear),
    );
  }

  void _startDemo() {
    setState(() {
      _isStreaming = true;
      _userInBus = true;
      _demoPhase = 'boarding';
    });

    // Simulate demo phases
    _demoTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        switch (_demoPhase) {
          case 'boarding':
            _demoPhase = 'traveling';
            _currentStop = 1;
            break;
          case 'traveling':
            _currentStop++;
            if (_currentStop >= _plannedExitStop) {
              _demoPhase = 'exit_detection';
            }
            break;
          case 'exit_detection':
            _currentStop++;
            if (_currentStop >= 12) {
              _demoPhase = 'fraud_analysis';
              _performFraudAnalysis();
              timer.cancel();
            }
            break;
        }
        _updateSensorData();
      });
    });
  }

  void _updateSensorData() {
    Random random = Random();
    setState(() {
      _sensorData = {
        'accelerometer': {
          'x': (random.nextDouble() - 0.5) * 2,
          'y': (random.nextDouble() - 0.5) * 2,
          'z': 9.8 + (random.nextDouble() - 0.5),
        },
        'gyroscope': {
          'x': (random.nextDouble() - 0.5) * 0.1,
          'y': (random.nextDouble() - 0.5) * 0.1,
          'z': (random.nextDouble() - 0.5) * 0.1,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'speed': _userInBus ? 25 + random.nextInt(15) : 0,
      };
    });
  }

  void _performFraudAnalysis() async {
    try {
      // Simulate fraud analysis
      Map<String, dynamic> analysisResult = await CrossPlatformService.analyzeFraudAtExit(
        widget.sessionId,
        'Stop $_currentStop',
        'Stop $_plannedExitStop',
      );

      setState(() {
        _fraudAnalysis = analysisResult;
        _userInBus = false;
        _isStreaming = false;
      });

      // Show fraud detection result
      _showFraudResult(analysisResult);
    } catch (e) {
      print('Error in fraud analysis: $e');
    }
  }

  void _showFraudResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result['isFraud'] ? Icons.warning : Icons.check_circle,
              color: result['isFraud'] ? Colors.red : Colors.green,
            ),
            SizedBox(width: 8),
            Text(result['isFraud'] ? 'Fraud Detected' : 'Journey Verified'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result['isFraud']) ...[
              Text(
                'Fare evasion detected!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 12),
              Text('Planned exit: Stop $_plannedExitStop'),
              Text('Actual exit: Stop $_currentStop'),
              Text('Extra stops: ${result['extraStops']}'),
              Text(
                'Penalty: ₹${result['penaltyAmount']}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ] else ...[
              Text(
                'Journey completed within paid limits.',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ],
        ),
        actions: [
          if (result['isFraud'])
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showPaymentDialog(result['penaltyAmount']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Pay Penalty', style: TextStyle(color: Colors.white)),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to home
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Penalty Payment'),
        content: Text(
          'You are required to pay ₹${amount.toStringAsFixed(2)} as penalty for fare evasion.\n\n'
          'This amount will be automatically deducted from your digital wallet.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Penalty payment processed: ₹${amount.toStringAsFixed(2)}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Pay Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Fraud Detection Demo'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTicketHeader(),
            SizedBox(height: 20),
            _buildSyncStatus(),
            SizedBox(height: 20),
            _buildJourneyProgress(),
            SizedBox(height: 20),
            _buildSensorData(),
            SizedBox(height: 20),
            _buildFraudMonitoring(),
            if (_fraudAnalysis.isNotEmpty) ...[
              SizedBox(height: 20),
              _buildFraudResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Card(
      elevation: 8,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fraud Detection Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Session: ${widget.sessionId.substring(0, 12)}...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${widget.ticket.sourceName}', style: TextStyle(color: Colors.white)),
                Icon(Icons.arrow_forward, color: Colors.white),
                Text('${widget.ticket.destinationName}', style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _syncAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _syncAnimation.value * 2 * pi,
                      child: Icon(Icons.sync, color: Colors.blue),
                    );
                  },
                ),
                SizedBox(width: 8),
                Text(
                  'Cross-Platform Sync',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gyro-Comparator DB:'),
                Text(
                  _isStreaming ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _isStreaming ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Data Streaming:'),
                Text(
                  _isStreaming ? 'Active' : 'Stopped',
                  style: TextStyle(
                    color: _isStreaming ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('User in Bus:'),
                Text(
                  _userInBus ? 'Yes' : 'No',
                  style: TextStyle(
                    color: _userInBus ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyProgress() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: _currentStop / 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentStop <= _plannedExitStop ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Stop: $_currentStop'),
                Text('Planned Exit: $_plannedExitStop'),
              ],
            ),
            if (_currentStop > _plannedExitStop)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'FRAUD ALERT: Exceeded planned exit by ${_currentStop - _plannedExitStop} stops',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorData() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Sensor Data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            if (_sensorData.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSensorCard(
                      'Accelerometer',
                      '${_sensorData['accelerometer']['x'].toStringAsFixed(2)}',
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSensorCard(
                      'Gyroscope',
                      '${_sensorData['gyroscope']['x'].toStringAsFixed(3)}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSensorCard(
                      'Speed',
                      '${_sensorData['speed']} km/h',
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSensorCard(
                      'Status',
                      _userInBus ? 'In Bus' : 'Walking',
                      _userInBus ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudMonitoring() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(Icons.radar, color: Colors.red),
                    );
                  },
                ),
                SizedBox(width: 8),
                Text(
                  'Fraud Monitoring',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Demo Phase: ${_demoPhase.replaceAll('_', ' ').toUpperCase()}'),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: _getPhaseProgress(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFraudResults() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _fraudAnalysis['isFraud'] ? Icons.warning : Icons.check_circle,
                  color: _fraudAnalysis['isFraud'] ? Colors.red : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Analysis Results',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...(_fraudAnalysis.entries.map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${entry.key}:'),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: entry.key == 'penaltyAmount' && entry.value > 0
                          ? Colors.red
                          : null,
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  double _getPhaseProgress() {
    switch (_demoPhase) {
      case 'boarding':
        return 0.25;
      case 'traveling':
        return 0.5;
      case 'exit_detection':
        return 0.75;
      case 'fraud_analysis':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _syncController.dispose();
    _demoTimer?.cancel();
    CrossPlatformService.stopDataStreaming();
    super.dispose();
  }
}
