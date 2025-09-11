import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/enhanced_ticket_model.dart';
import '../models/trip_data_model.dart';
import '../services/voice_multilingual_service.dart';
import '../services/enhanced_ticket_service.dart';
import '../widgets/voice_guidance_widget.dart';
import 'ticket_display_screen.dart';

/// Simple Voice-Guided Ticket Booking with TTS Assistance
class SimpleVoiceBookingScreen extends StatefulWidget {
  @override
  _SimpleVoiceBookingScreenState createState() => _SimpleVoiceBookingScreenState();
}

class _SimpleVoiceBookingScreenState extends State<SimpleVoiceBookingScreen> {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final Uuid _uuid = Uuid();
  
  String _currentLanguage = 'en';
  String? _selectedSource;
  String? _selectedDestination;
  double _estimatedFare = 0.0;
  bool _isLoading = false;
  
  // Popular Chennai bus stops
  final List<String> _popularStations = [
    'Chennai Egmore',
    'Chennai Central', 
    'T Nagar',
    'Park Town',
    'Guindy',
    'Adyar',
    'Velachery',
    'Anna Nagar',
    'Vadapalani',
    'Koyambedu',
    'Tambaram',
    'Marina Beach',
    'Airport',
    'Mylapore',
    'Besant Nagar',
  ];

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _voiceService.initialize();
    await _voiceService.speakPhrase('welcome');
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onSourceChanged(String value) {
    setState(() {
      _selectedSource = value;
      _sourceController.text = value;
    });
    _calculateFare();
    _voiceService.processTextInput(value, 'source');
  }

  void _onDestinationChanged(String value) {
    setState(() {
      _selectedDestination = value;
      _destinationController.text = value;
    });
    _calculateFare();
    _voiceService.processTextInput(value, 'destination');
  }

  void _calculateFare() {
    if (_selectedSource != null && _selectedDestination != null) {
      // Simple fare calculation based on distance estimate
      final random = math.Random();
      setState(() {
        _estimatedFare = 15.0 + (random.nextDouble() * 25.0);
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await _voiceService.setLanguage(languageCode);
    setState(() => _currentLanguage = languageCode);
  }

  Future<void> _bookTicket() async {
    if (_selectedSource == null || _selectedDestination == null) {
      await _voiceService.speak('Please select both source and destination');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Use the proper ticket service method
      final ticket = await EnhancedTicketService.issueTicket(
        sourceName: _selectedSource!,
        destinationName: _selectedDestination!,
        fare: _estimatedFare,
      );

      await _voiceService.speak('Ticket booked successfully!');

      // Navigate to ticket display
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: ticket.sessionId,
            tripData: TripData(
              ticketId: ticket.ticketId,
              userId: ticket.userId,
              startTime: ticket.issueTime,
              sourceLocation: LatLng(ticket.sourceLocation.latitude, ticket.sourceLocation.longitude),
              destinationLocation: LatLng(ticket.destinationLocation.latitude, ticket.destinationLocation.longitude),
              sourceName: ticket.sourceName,
              destinationName: ticket.destinationName,
              status: TripStatus.active,
            ),
          ),
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();
      print('❌ Error in voice ticket booking: $errorMessage');
      
      // Check if this is a distance warning
      if (errorMessage.contains('DISTANCE_WARNING:')) {
        String warningMessage = errorMessage.replaceFirst('Exception: DISTANCE_WARNING:', '');
        
        await _voiceService.speak('Distance warning detected. Please check the message.');
        
        // Show warning dialog with option to continue
        _showWarningDialog(
          '$warningMessage\n\nWould you like to proceed with booking the ticket?',
          () async {
            // User chose to continue despite distance warning
            print('✅ User confirmed to continue despite distance warning');
            await _proceedWithBooking();
          },
        );
      } else {
        // This is a real error
        await _voiceService.speak('Booking failed. Please try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _proceedWithBooking() async {
    setState(() => _isLoading = true);

    try {
      // Force booking without location check (distance override)
      final ticket = await EnhancedTicketService.issueTicketWithoutLocationCheck(
        sourceName: _selectedSource!,
        destinationName: _selectedDestination!,
        fare: _estimatedFare,
      );

      await _voiceService.speak('Ticket booked successfully despite distance warning!');

      // Navigate to ticket display
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: ticket.sessionId,
            tripData: TripData(
              ticketId: ticket.ticketId,
              userId: ticket.userId,
              startTime: ticket.issueTime,
              sourceLocation: LatLng(ticket.sourceLocation.latitude, ticket.sourceLocation.longitude),
              destinationLocation: LatLng(ticket.destinationLocation.latitude, ticket.destinationLocation.longitude),
              sourceName: ticket.sourceName,
              destinationName: ticket.destinationName,
              status: TripStatus.active,
            ),
          ),
        ),
      );
    } catch (e) {
      await _voiceService.speak('Booking still failed. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Guided Booking'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _voiceService.speakPhrase('welcome'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selector
            LanguageSelectorWidget(
              currentLanguage: _currentLanguage,
              onLanguageChanged: _changeLanguage,
              voiceService: _voiceService,
            ),
            
            SizedBox(height: 20),
            
            // Source Station Section
            _buildStationSection(
              title: 'From Station',
              controller: _sourceController,
              fieldType: 'source',
              onChanged: _onSourceChanged,
            ),
            
            SizedBox(height: 20),
            
            // Destination Station Section  
            _buildStationSection(
              title: 'To Station',
              controller: _destinationController,
              fieldType: 'destination',
              onChanged: _onDestinationChanged,
            ),
            
            SizedBox(height: 20),
            
            // Popular Stations Quick Select
            _buildPopularStations(),
            
            SizedBox(height: 20),
            
            // Fare Display
            if (_estimatedFare > 0) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Fare:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₹${_estimatedFare.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
            
            // Book Ticket Button
            ElevatedButton(
              onPressed: _isLoading ? null : _bookTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Book Ticket',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSection({
    required String title,
    required TextEditingController controller,
    required String fieldType,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8),
        
        // Voice Guidance Widget
        VoiceGuidanceWidget(
          fieldType: fieldType,
          hint: 'Get voice guidance for $title',
        ),
        
        SizedBox(height: 12),
        
        // Enhanced Text Field
        VoiceTextField(
          label: title,
          fieldType: fieldType,
          controller: controller,
          suggestions: _popularStations,
          onChanged: onChanged,
          voiceService: _voiceService,
        ),
      ],
    );
  }

  Widget _buildPopularStations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Popular Stations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () => _voiceService.announcePopularStations(_popularStations),
                  child: Text('🔊 Listen'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularStations.map((station) {
                return ActionChip(
                  label: Text(
                    station,
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    if (_sourceController.text.isEmpty) {
                      _onSourceChanged(station);
                    } else if (_destinationController.text.isEmpty) {
                      _onDestinationChanged(station);
                    } else {
                      // Show dialog to choose which field to fill
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Select Field'),
                          content: Text('Which field would you like to update with "$station"?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _onSourceChanged(station);
                              },
                              child: Text('From'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _onDestinationChanged(station);
                              },
                              child: Text('To'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarningDialog(String message, VoidCallback onContinue) {
    print('🚨 Showing distance warning dialog: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Distance Warning'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ User cancelled voice ticket booking');
              Navigator.of(context).pop();
              _voiceService.speak('Booking cancelled');
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              print('✅ User chose to book anyway despite distance warning');
              Navigator.of(context).pop();
              _voiceService.speak('Proceeding with booking despite distance warning');
              onContinue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Book Anyway'),
          ),
        ],
      ),
    );
  }
}
