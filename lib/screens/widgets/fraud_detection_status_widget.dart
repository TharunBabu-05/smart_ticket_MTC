import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/enhanced_sensor_service.dart';
import '../models/enhanced_ticket_model.dart';

/// Widget to display fraud detection status and connection code
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
    
    // Update status every 2 seconds
    Stream.periodic(Duration(seconds: 2)).listen((_) {
      if (mounted) _updateStatus();
    });
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
  
  void _copyConnectionCode() {
    if (connectionCode != null) {
      Clipboard.setData(ClipboardData(text: connectionCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection code copied: $connectionCode'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.activeTicket == null || !isStreaming) {
      return SizedBox.shrink();
    }
    
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isStreaming ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      transform: Matrix4.identity()..scale(_pulseAnimation.value),
                    );
                  },
                ),
                SizedBox(width: 8),
                Text(
                  'Fraud Detection Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isStreaming ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Connection code section
            if (connectionCode != null) ...[
              Text(
                'Connection Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: _copyConnectionCode,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        connectionCode!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
            
            // Sensor data preview
            if (sensorData.isNotEmpty) ...[
              Text(
                'Sensor Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              
              Row(
                children: [
                  // Gyroscope
                  Expanded(
                    child: _buildSensorCard(
                      'Gyro',
                      Icons.rotate_right,
                      sensorData['gyroscope']?['x']?.toStringAsFixed(1) ?? '0.0',
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  
                  // Accelerometer
                  Expanded(
                    child: _buildSensorCard(
                      'Accel',
                      Icons.speed,
                      sensorData['accelerometer']?['x']?.toStringAsFixed(1) ?? '0.0',
                      Colors.purple,
                    ),
                  ),
                  SizedBox(width: 8),
                  
                  // Speed
                  Expanded(
                    child: _buildSensorCard(
                      'Speed',
                      Icons.directions_bus,
                      '${(sensorData['speed'] ?? 0.0).toStringAsFixed(0)} km/h',
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 12),
            
            // Info text
            Text(
              'This code allows bus conductor to verify your location using the Gyro Comparator app.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
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
