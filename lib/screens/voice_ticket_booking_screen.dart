import 'package:flutter/material.dart';
import '../services/voice_multilingual_service.dart';
import '../widgets/voice_tts_widget.dart';

/// Simple Voice-Enabled Ticket Booking Screen
class VoiceTicketBookingScreen extends StatefulWidget {
  @override
  _VoiceTicketBookingScreenState createState() => _VoiceTicketBookingScreenState();
}

class _VoiceTicketBookingScreenState extends State<VoiceTicketBookingScreen> {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  String _currentLanguage = 'en';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Ticket Booking'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _voiceService.speakPhrase('welcome'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 20),
              Text(
                'Voice Booking Coming Soon',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'This feature is under development. Please use the simple voice booking option from the home screen.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              VoiceGuidanceCard(
                title: 'Voice Assistance Available',
                description: 'Tap to hear this message',
                icon: Icons.mic,
                onTap: () {
                  _voiceService.speak('Voice booking feature is coming soon. Please try the simple voice booking from the home screen.');
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
