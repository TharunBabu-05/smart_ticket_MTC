import 'package:flutter/material.dart';
import 'dart:async';
import '../models/trip_data_model.dart';
import '../services/firebase_service.dart';
import '../services/cross_platform_service.dart';
import 'simple_ticket_screen.dart';

class ActiveTripsScreen extends StatefulWidget {
  @override
  _ActiveTripsScreenState createState() => _ActiveTripsScreenState();
}

class _ActiveTripsScreenState extends State<ActiveTripsScreen> {
  List<TripData> _activeTrips = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveTrips();
    // Refresh active trips every 30 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadActiveTrips();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveTrips() async {
    try {
      // In production, get actual user ID from authentication
      String userId = 'user_123';
      List<TripData> trips = await FirebaseService.getUserActiveTrips(userId);
      
      if (mounted) {
        setState(() {
          _activeTrips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading active trips: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshTrips() async {
    setState(() {
      _isLoading = true;
    });
    await _loadActiveTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Trips'),
        backgroundColor: Color(0xFF1DB584),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshTrips,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB584)),
                  ),
                  SizedBox(height: 16),
                  Text('Loading active trips...'),
                ],
              ),
            )
          : _activeTrips.isEmpty
              ? _buildEmptyState()
              : _buildTripsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Active Trips',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your active bus tickets will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.add),
            label: Text('Book a Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1DB584),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _activeTrips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(_activeTrips[index]);
        },
      ),
    );
  }

  Widget _buildTripCard(TripData trip) {
    Duration timeSinceStart = DateTime.now().difference(trip.startTime);
    Duration remainingTime = Duration(hours: 2) - timeSinceStart;
    bool isExpired = remainingTime.inSeconds <= 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleTicketScreen(tripData: trip),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        color: isExpired ? Colors.red : Color(0xFF1DB584),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Bus Ticket',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isExpired ? 'EXPIRED' : 'ACTIVE',
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
              _buildTripInfo('From', trip.sourceName ?? 'Unknown'),
              SizedBox(height: 4),
              _buildTripInfo('To', trip.destinationName ?? 'Unknown'),
              SizedBox(height: 4),
              _buildTripInfo('Ticket ID', trip.ticketId.substring(0, 8)),
              SizedBox(height: 4),
              _buildTripInfo('Started', _formatTime(trip.startTime)),
              SizedBox(height: 12),
              // Streaming status indicator
              if (!isExpired) _buildStreamingStatus(trip),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.timer_off : Icons.timer,
                      color: isExpired ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isExpired 
                          ? 'Ticket has expired'
                          : 'Valid for ${_formatDuration(remainingTime)}',
                      style: TextStyle(
                        color: isExpired ? Colors.red.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Auto-expire ticket if time is up
              if (isExpired && FirebaseService.currentStreamingTicket == trip.ticketId)
                FutureBuilder(
                  future: _expireTicketIfNeeded(trip.ticketId),
                  builder: (context, snapshot) => SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStreamingStatus(TripData trip) {
    bool isCurrentlyStreaming = CrossPlatformService.isStreaming && 
        CrossPlatformService.getCurrentSessionId() == trip.ticketId;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentlyStreaming ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentlyStreaming ? Colors.blue.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (isCurrentlyStreaming) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Streaming sensors...',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ] else ...[
            Icon(
              Icons.sensors_off,
              color: Colors.orange.shade700,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Sensor streaming stopped',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _expireTicketIfNeeded(String ticketId) async {
    try {
      await FirebaseService.expireTicket(ticketId);
      // Refresh the trips list to reflect the change
      if (mounted) {
        _loadActiveTrips();
      }
    } catch (e) {
      print('Error expiring ticket: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
