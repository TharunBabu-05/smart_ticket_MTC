import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/enhanced_sensor_service.dart';
import '../models/enhanced_ticket_model.dart';

/// Clean fraud detection status widget with improved UI
class FraudDetectionStatusWidget extends StatefulWidget {
  final EnhancedTicket? activeTicket;
  
  const FraudDetectionStatusWidget({
    Key? key,
    required this.activeTicket,
  }) : super(key: key);

  @override
  _FraudDetectionStatusWidgetState createState() => _FraudDetectionStatusWidgetState();
}

class _FraudDetectionStatusWidgetState extends State<FraudDetectionStatusWidget> 
    with TickerProviderStateMixin {
  String? connectionCode;
  Map<String, dynamic> sensorData = {};
  bool isStreaming = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Mock verification status for demo
  bool motionMatch = true;
  bool speedMatch = true;
  bool locationMatch = false; // This will be red as shown in your image
  
  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation for streaming indicator
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _updateStatus();
    
    // Update status every 3 seconds
    Stream.periodic(Duration(seconds: 3)).listen((_) {
      if (mounted) _updateStatus();
    });
    
    // Simulate verification status changes
    _simulateVerificationChanges();
  }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _updateStatus() {
    setState(() {
      connectionCode = EnhancedSensorService.getCurrentConnectionCode();
      sensorData = EnhancedSensorService.getCurrentSensorData();
      isStreaming = EnhancedSensorService.isStreaming();
      
      if (isStreaming) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    });
  }
  
  void _simulateVerificationChanges() {
    // Simulate realistic verification status changes
    Stream.periodic(Duration(seconds: 8)).listen((_) {
      if (mounted) {
        setState(() {
          motionMatch = DateTime.now().second % 3 != 0; // Mostly true
          speedMatch = DateTime.now().second % 4 != 0; // Mostly true  
          locationMatch = DateTime.now().second % 5 == 0; // Mostly false (mismatch)
        });
      }
    });
  }
  
  void _copyConnectionCode() {
    if (connectionCode != null) {
      Clipboard.setData(ClipboardData(text: connectionCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection code copied: $connectionCode'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.activeTicket == null) {
      return SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isStreaming ? Colors.green[50] : Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isStreaming ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          transform: Matrix4.identity()..scale(_pulseAnimation.value),
                        );
                      },
                    ),
                    SizedBox(width: 12),
                    Text(
                      isStreaming ? 'Connected to ticket holder' : 'Not Connected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isStreaming ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Connection code display
                if (connectionCode != null) ...[
                  Text(
                    'Connection Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: _copyConnectionCode,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            connectionCode!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              letterSpacing: 3,
                            ),
                          ),
                          Icon(
                            Icons.copy,
                            size: 20,
                            color: Colors.blue[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Sensor Data Section (if available)
          if (sensorData.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Device (Inspector)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildSensorDataCard('Accelerometer', sensorData['accelerometer']),
                  SizedBox(height: 8),
                  _buildSensorDataCard('Gyroscope', sensorData['gyroscope']),
                  SizedBox(height: 8),
                  _buildSpeedCard(sensorData['speed'] ?? 0.0),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Passenger Device (Ticket Holder)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildSensorDataCard('Accelerometer', _getMockPassengerAccel()),
                  SizedBox(height: 8),
                  _buildSensorDataCard('Gyroscope', _getMockPassengerGyro()),
                  SizedBox(height: 8),
                  _buildSpeedCard(0.0), // Passenger is stationary
                ],
              ),
            ),
          ],
          
          // Verification Status Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                _buildVerificationStatus('Motion Match', motionMatch, Icons.refresh),
                SizedBox(height: 12),
                _buildVerificationStatus('Speed Match', speedMatch, Icons.speed),
                SizedBox(height: 12),
                _buildVerificationStatus('Location Match', locationMatch, Icons.location_on),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSensorDataCard(String title, Map<String, dynamic>? data) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          if (data != null) ...[
            Text('X: ${data['x']?.toStringAsFixed(2) ?? '0.00'}', style: _sensorTextStyle()),
            Text('Y: ${data['y']?.toStringAsFixed(2) ?? '0.00'}', style: _sensorTextStyle()),
            Text('Z: ${data['z']?.toStringAsFixed(2) ?? '0.00'}', style: _sensorTextStyle()),
          ] else ...[
            Text('X: 0.00', style: _sensorTextStyle()),
            Text('Y: 0.00', style: _sensorTextStyle()),
            Text('Z: 0.00', style: _sensorTextStyle()),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSpeedCard(double speed) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${speed.toStringAsFixed(2)} km/h',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVerificationStatus(String title, bool isMatched, IconData icon) {
    Color statusColor = isMatched ? Colors.green : Colors.red;
    String statusText = isMatched ? 'Match' : 'Mismatch';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: statusColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  TextStyle _sensorTextStyle() {
    return TextStyle(
      fontSize: 13,
      color: Colors.black87,
      fontFamily: 'monospace',
    );
  }
  
  Map<String, dynamic> _getMockPassengerAccel() {
    // Mock passenger accelerometer data (similar but slightly different)
    var adminAccel = sensorData['accelerometer'];
    if (adminAccel != null) {
      return {
        'x': (adminAccel['x'] ?? 0.0) + 0.3,  // Slight variation
        'y': (adminAccel['y'] ?? 0.0) - 0.2,
        'z': (adminAccel['z'] ?? 0.0) + 0.1,
      };
    }
    return {'x': -2.65, 'y': 5.57, 'z': 7.74}; // Default from your image
  }
  
  Map<String, dynamic> _getMockPassengerGyro() {
    // Mock passenger gyroscope data
    var adminGyro = sensorData['gyroscope'];
    if (adminGyro != null) {
      return {
        'x': (adminGyro['x'] ?? 0.0) + 0.1,  // Very close values for motion match
        'y': (adminGyro['y'] ?? 0.0) - 0.05,
        'z': (adminGyro['z'] ?? 0.0) + 0.02,
      };
    }
    return {'x': -0.02, 'y': -0.02, 'z': -0.01}; // Default from your image
  }
  
  Widget _buildSensorCard(String label, IconData icon, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
