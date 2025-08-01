mport 'package:flutter/material.dart';
import '../debug/firebase_debug_helper.dart';
import '../services/enhanced_ticket_service.dart';
import '../models/enhanced_ticket_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketDebugScreen extends StatefulWidget {
  const TicketDebugScreen({super.key});

  @override
  _TicketDebugScreenState createState() => _TicketDebugScreenState();
}

class _TicketDebugScreenState extends State<TicketDebugScreen> {
  List<EnhancedTicket> _tickets = [];
  bool _isLoading = false;
  String _debugOutput = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Debug Screen'),
        backgroundColor: Color(0xFF1DB584),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _debugPrintAllTickets,
                    child: Text('Debug Print All'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadActiveTickets,
                    child: Text('Load Active Tickets'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearExpiredTickets,
                    child: Text('Clear Expired'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearDebugOutput,
                    child: Text('Clear Output'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Active Tickets: ${_tickets.length}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Tickets list
                        if (_tickets.isNotEmpty) ...[
                          Text('Found Tickets:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ..._tickets.map((ticket) => Card(
                            child: ListTile(
                              title: Text(ticket.ticketId),
                              subtitle: Text('${ticket.sourceName} → ${ticket.destinationName}'),
                              trailing: Text(ticket.isValid ? 'VALID' : 'EXPIRED'),
                            ),
                          )),
                        ],
                        SizedBox(height: 16),
                        // Debug output
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                _debugOutput.isEmpty ? 'Debug output will appear here...' : _debugOutput,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _debugPrintAllTickets() async {
    setState(() {
      _isLoading = true;
      _debugOutput += '\n🔍 Starting debug print all tickets...\n';
    });

    try {
      await FirebaseDebugHelper.debugPrintAllTickets();
      setState(() {
        _debugOutput += '✅ Debug print completed. Check console for details.\n';
      });
    } catch (e) {
      setState(() {
        _debugOutput += '❌ Debug print failed: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadActiveTickets() async {
    setState(() {
      _isLoading = true;
      _debugOutput += '\n🎫 Loading active tickets...\n';
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _debugOutput += '🚫 No authenticated user\n';
        });
        return;
      }

      List<EnhancedTicket> tickets = await EnhancedTicketService.getUserActiveTickets(user.uid);
      
      setState(() {
        _tickets = tickets;
        _debugOutput += '✅ Loaded ${tickets.length} active tickets\n';
        
        for (var ticket in tickets) {
          _debugOutput += '  - ${ticket.ticketId}: ${ticket.sourceName} → ${ticket.destinationName} (${ticket.isValid ? 'VALID' : 'EXPIRED'})\n';
        }
      });
    } catch (e) {
      setState(() {
        _debugOutput += '❌ Failed to load tickets: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearExpiredTickets() async {
    setState(() {
      _isLoading = true;
      _debugOutput += '\n🧹 Clearing expired tickets...\n';
    });

    try {
      await FirebaseDebugHelper.debugClearExpiredTickets();
      setState(() {
        _debugOutput += '✅ Expired tickets cleared\n';
      });
      
      // Reload tickets
      _loadActiveTickets();
    } catch (e) {
      setState(() {
        _debugOutput += '❌ Failed to clear expired tickets: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearDebugOutput() {
    setState(() {
      _debugOutput = '';
    });
  }
}
