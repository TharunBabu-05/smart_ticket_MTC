import 'package:flutter/material.dart';
import '../services/cross_platform_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _testOutput = 'Ready to test Firebase connectivity...';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Databases',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    _buildDatabaseInfo(
                      'Primary Database',
                      'smart-ticket-mtc',
                      'https://smart-ticket-mtc-default-rtdb.firebaseio.com',
                      Colors.blue,
                    ),
                    SizedBox(height: 8),
                    _buildDatabaseInfo(
                      'Secondary Database',
                      'gyre-compare',
                      'https://gyre-compare-default-rtdb.firebaseio.com',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Test Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testSessionCreation,
                    child: Text('Test Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Test Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testOutput,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.green[300],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseInfo(String title, String project, String url, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 4),
          Text('Project: $project', style: TextStyle(fontSize: 12)),
          Text('URL: $url', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _testConnection() async {
    setState(() {
      _isLoading = true;
      _testOutput = 'Testing Firebase connection...\n';
    });

    try {
      _appendOutput('🔧 Initializing cross-platform service...');
      await CrossPlatformService.initialize();
      _appendOutput('✅ Cross-platform service initialized successfully!');
      _appendOutput('📡 Connected to Gyro-Comparator database');
      _appendOutput('🎉 Test completed successfully!');
    } catch (e) {
      _appendOutput('❌ Connection test failed: $e');
    }

    setState(() => _isLoading = false);
  }

  void _testSessionCreation() async {
    setState(() {
      _isLoading = true;
      _testOutput = 'Testing session creation...\n';
    });

    try {
      _appendOutput('🔧 Initializing service...');
      await CrossPlatformService.initialize();
      
      _appendOutput('📊 Creating test trip data...');
      // Note: You'll need to import and use TripData here
      _appendOutput('⚠️ Session creation test requires TripData model');
      _appendOutput('💡 Use the ticket booking screen to test session creation');
      
    } catch (e) {
      _appendOutput('❌ Session test failed: $e');
    }

    setState(() => _isLoading = false);
  }

  void _appendOutput(String message) {
    setState(() {
      _testOutput += '$message\n';
    });
  }
}
