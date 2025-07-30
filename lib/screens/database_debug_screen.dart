import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../debug/database_viewer.dart';

class DatabaseDebugScreen extends StatefulWidget {
  @override
  _DatabaseDebugScreenState createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  final TextEditingController _sessionIdController = TextEditingController();
  String _debugOutput = 'Ready to fetch session data...';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Debug Viewer'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 20),
            _buildActionsCard(),
            SizedBox(height: 20),
            _buildOutputCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Primary Firebase - Gyro Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Project: smart-ticket-mtc (Primary)'),
            Text('Path: gyro_sessions/'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'This path stores minimal session data in your primary Firebase Realtime Database for cross-platform fraud detection communication between passenger phones and bus gyroscope systems.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _viewAllSessions,
                    icon: Icon(Icons.list),
                    label: Text('View All Sessions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startRealtimeListener,
                    icon: Icon(Icons.live_tv),
                    label: Text('Live Updates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Search Specific Session:'),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sessionIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter Session ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _viewSpecificSession,
                  child: Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.terminal, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Debug Output',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: _copyOutput,
                    icon: Icon(Icons.copy),
                    tooltip: 'Copy Output',
                  ),
                  IconButton(
                    onPressed: _clearOutput,
                    icon: Icon(Icons.clear),
                    tooltip: 'Clear Output',
                  ),
                ],
              ),
              SizedBox(height: 12),
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
                      _debugOutput,
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
      ),
    );
  }

  void _viewAllSessions() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Fetching all sessions...\n';
    });

    try {
      // Capture console output
      await DatabaseViewer.viewAllSessions();
      setState(() {
        _debugOutput += '\n✅ All sessions fetched successfully!\nCheck the console for detailed output.';
      });
    } catch (e) {
      setState(() {
        _debugOutput += '\n❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _viewSpecificSession() async {
    String sessionId = _sessionIdController.text.trim();
    if (sessionId.isEmpty) {
      setState(() {
        _debugOutput += '\n❌ Please enter a Session ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _debugOutput += '\nSearching for session: $sessionId\n';
    });

    try {
      await DatabaseViewer.viewSession(sessionId);
      setState(() {
        _debugOutput += '\n✅ Session search completed!\nCheck the console for detailed output.';
      });
    } catch (e) {
      setState(() {
        _debugOutput += '\n❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startRealtimeListener() {
    setState(() {
      _debugOutput += '\n🔄 Starting real-time listener...\nCheck console for live updates.';
    });
    
    DatabaseViewer.listenToSessions();
  }

  void _copyOutput() {
    Clipboard.setData(ClipboardData(text: _debugOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Output copied to clipboard')),
    );
  }

  void _clearOutput() {
    setState(() {
      _debugOutput = 'Output cleared...';
    });
  }
}
