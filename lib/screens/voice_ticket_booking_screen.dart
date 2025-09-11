import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:math' as math;
import '../models/enhanced_ticket_model.dart';
import '../models/trip_data_model.dart';
import '../models/bus_stop_model.dart';
import '../services/voice_multilingual_service.dart';
import '../services/enhanced_ticket_service.dart';
import '../services/razorpay_service.dart';
import '../widgets/voice_input_widget.dart';
import '../data/bus_stops_data.dart';
import 'ticket_display_screen.dart';

// Booking flow state enum (moved outside class)
enum BookingStep { languageSelection, routeSelection, confirmation, payment }

/// Voice-Enabled Ticket Booking Screen with Multilingual Support
class VoiceTicketBookingScreen extends StatefulWidget {
  @override
  _VoiceTicketBookingScreenState createState() => _VoiceTicketBookingScreenState();
}

class _VoiceTicketBookingScreenState extends State<VoiceTicketBookingScreen> {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final Uuid _uuid = Uuid();
  
  String? _selectedFromStop;
  String? _selectedToStop;
  double _estimatedFare = 0.0;
  bool _isLoading = false;
  bool _isVoiceMode = false;
  String _currentLanguage = 'en';
  
  // Booking flow state
  BookingStep _currentStep = BookingStep.languageSelection;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    final initialized = await _voiceService.initialize();
    if (initialized) {
      setState(() {});
      // Welcome message
      await _voiceService.speakPhrase('welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Voice mode toggle
          IconButton(
            icon: Icon(_isVoiceMode ? Icons.record_voice_over : Icons.voice_over_off),
            onPressed: () {
              setState(() {
                _isVoiceMode = !_isVoiceMode;
              });
              if (_isVoiceMode) {
                _voiceService.speakPhrase('welcome');
              }
            },
          ),
          // Language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (context) {
              return VoiceMultilingualService.availableLanguages.entries
                  .map((entry) => PopupMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Text(entry.value['flag']!),
                            const SizedBox(width: 8),
                            Text(entry.value['name']!),
                          ],
                        ),
                      ))
                  .toList();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _isVoiceMode ? _buildVoiceActionButton() : null,
    );
  }

  String _getTitle() {
    switch (_currentLanguage) {
      case 'ta':
        return 'வாய்ஸ் டிக்கெட் முன்பதிவு';
      case 'hi':
        return 'वॉयस टिकट बुकिंग';
      default:
        return 'Voice Ticket Booking';
    }
  }

  Widget _buildBody() {
    if (_isVoiceMode) {
      return _buildVoiceInterface();
    } else {
      return _buildTraditionalInterface();
    }
  }

  Widget _buildVoiceInterface() {
    switch (_currentStep) {
      case BookingStep.languageSelection:
        return _buildLanguageSelectionStep();
      case BookingStep.routeSelection:
        return _buildVoiceRouteSelection();
      case BookingStep.confirmation:
        return _buildVoiceConfirmation();
      case BookingStep.payment:
        return _buildPaymentStep();
      default:
        return _buildLanguageSelectionStep();
    }
  }

  Widget _buildLanguageSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.language,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          LanguageSelectorWidget(
            currentLanguage: _currentLanguage,
            onLanguageChanged: (language) {
              _changeLanguage(language);
              setState(() {
                _currentStep = BookingStep.routeSelection;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = BookingStep.routeSelection;
              });
            },
            child: Text(_getSkipLanguageText()),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRouteSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Voice guidance text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.record_voice_over,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getVoiceInstructionText(),
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTextInputPrompt(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // From field with voice guidance
          VoiceTextField(
            controller: _fromController,
            labelText: _getFromText(),
            hintText: _getFromHintText(),
            onVoiceInput: (text) {
              final stop = _voiceService.processBusStopVoiceInput(text);
              if (stop != null) {
                setState(() {
                  _selectedFromStop = stop;
                  _fromController.text = stop;
                });
                _calculateFare();
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // To field with voice guidance
          VoiceTextField(
            controller: _toController,
            labelText: _getToText(),
            hintText: _getToHintText(),
            onVoiceInput: (text) {
              final stop = _voiceService.processBusStopVoiceInput(text);
              if (stop != null) {
                setState(() {
                  _selectedToStop = stop;
                  _toController.text = stop;
                });
                _calculateFare();
              }
            },
          ),
          
          const SizedBox(height: 20),
          
          // Quick selection buttons for popular destinations
          _buildQuickSelectionButtons(),
          
          const SizedBox(height: 20),
          
          // Current selections display
          if (_selectedFromStop != null || _selectedToStop != null)
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_selectedFromStop != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.my_location, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('${_getFromText()}: $_selectedFromStop'),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_selectedToStop != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('${_getToText()}: $_selectedToStop'),
                        ],
                      ),
                    ],
                    if (_estimatedFare > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('${_getFareText()}: ₹${_estimatedFare.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_selectedFromStop != null && _selectedToStop != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = BookingStep.confirmation;
                    });
                  },
                  icon: const Icon(Icons.check),
                  label: Text(_getConfirmText()),
                ),
              ElevatedButton.icon(
                onPressed: _clearSelections,
                icon: const Icon(Icons.clear),
                label: Text(_getClearText()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceConfirmation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getConfirmationText(),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Journey details
                  _buildJourneyDetails(),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _proceedToPayment,
                        icon: const Icon(Icons.payment),
                        label: Text(_getPayText()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentStep = BookingStep.routeSelection;
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: Text(_getEditText()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionalInterface() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Language selector at top
          LanguageSelectorWidget(
            currentLanguage: _currentLanguage,
            onLanguageChanged: _changeLanguage,
          ),
          
          const SizedBox(height: 20),
          
          // Route selection with voice input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRouteSelectionText(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // From field with voice input
                  VoiceTextField(
                    controller: _fromController,
                    labelText: _getFromText(),
                    hintText: _getFromHintText(),
                    onVoiceInput: (text) {
                      final stop = _voiceService.processBusStopVoiceInput(text);
                      if (stop != null) {
                        setState(() {
                          _selectedFromStop = stop;
                          _fromController.text = stop;
                        });
                        _calculateFare();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // To field with voice input
                  VoiceTextField(
                    controller: _toController,
                    labelText: _getToText(),
                    hintText: _getToHintText(),
                    onVoiceInput: (text) {
                      final stop = _voiceService.processBusStopVoiceInput(text);
                      if (stop != null) {
                        setState(() {
                          _selectedToStop = stop;
                          _toController.text = stop;
                        });
                        _calculateFare();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Fare display
          if (_estimatedFare > 0) _buildFareCard(),
          
          const SizedBox(height: 20),
          
          // Book ticket button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canBookTicket() ? _proceedToPayment : null,
              icon: const Icon(Icons.confirmation_number),
              label: Text(_getBookTicketText()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildJourneyRow(Icons.my_location, _getFromText(), _selectedFromStop!, Colors.green),
          const SizedBox(height: 8),
          const Icon(Icons.arrow_downward, color: Colors.grey),
          const SizedBox(height: 8),
          _buildJourneyRow(Icons.location_on, _getToText(), _selectedToStop!, Colors.red),
          const Divider(height: 20),
          _buildJourneyRow(Icons.currency_rupee, _getFareText(), '₹${_estimatedFare.toStringAsFixed(2)}', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildJourneyRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text('$label: '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFareCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getFareText(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '₹${_estimatedFare.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _getProcessingPaymentText(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceActionButton() {
    return FloatingActionButton.extended(
      onPressed: _startVoiceGuidedBooking,
      icon: const Icon(Icons.record_voice_over),
      label: Text(_getVoiceBookingText()),
      backgroundColor: Colors.red,
    );
  }

  // Voice processing methods
  void _processVoiceInput(String input) {
    final busStop = _voiceService.processBusStopVoiceInput(input);
    
    if (busStop != null) {
      if (_selectedFromStop == null) {
        setState(() {
          _selectedFromStop = busStop;
        });
        _voiceService.speak('${_getFromText()}: $busStop. ${_getToDestinationPrompt()}');
      } else if (_selectedToStop == null && busStop != _selectedFromStop) {
        setState(() {
          _selectedToStop = busStop;
        });
        _calculateFare();
        _voiceService.speak('${_getToText()}: $busStop. ${_getFareText()}: ₹${_estimatedFare.toStringAsFixed(2)}');
      } else {
        _voiceService.speakPhrase('not_understood');
      }
    } else {
      _voiceService.speakPhrase('not_understood');
    }
  }

  Future<void> _startVoiceGuidedBooking() async {
    final bookingData = await _voiceService.voiceGuidedBooking();
    
    if (bookingData['source'] != null) {
      setState(() {
        _selectedFromStop = bookingData['source'];
        _fromController.text = bookingData['source']!;
      });
    }
    
    if (bookingData['destination'] != null) {
      setState(() {
        _selectedToStop = bookingData['destination'];
        _toController.text = bookingData['destination']!;
      });
    }
    
    if (_selectedFromStop != null && _selectedToStop != null) {
      _calculateFare();
      setState(() {
        _currentStep = BookingStep.confirmation;
      });
    }
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });
    _voiceService.setLanguage(languageCode);
  }

  void _calculateFare() {
    if (_selectedFromStop != null && _selectedToStop != null) {
      // Simple fare calculation - you can enhance this
      setState(() {
        _estimatedFare = 15.0 + (math.Random().nextDouble() * 25);
      });
    }
  }

  bool _canBookTicket() {
    return _selectedFromStop != null && 
           _selectedToStop != null && 
           _selectedFromStop != _selectedToStop &&
           !_isLoading;
  }

  void _clearSelections() {
    setState(() {
      _selectedFromStop = null;
      _selectedToStop = null;
      _estimatedFare = 0.0;
      _fromController.clear();
      _toController.clear();
    });
    _voiceService.speak(_getClearedText());
  }

  Future<void> _proceedToPayment() async {
    if (!_canBookTicket()) return;
    
    setState(() {
      _isLoading = true;
      _currentStep = BookingStep.payment;
    });
    
    try {
      await _voiceService.speak(_getProcessingPaymentText());
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Create ticket (integrate with your existing ticket service)
      final sessionId = _uuid.v4();
      final ticket = EnhancedTicket(
        ticketId: _uuid.v4(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        sessionId: sessionId,
        issueTime: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(hours: 24)),
        sourceName: _selectedFromStop!,
        destinationName: _selectedToStop!,
        sourceLocation: const gmaps.LatLng(13.0827, 80.2707), // Default Chennai coordinates
        destinationLocation: const gmaps.LatLng(13.0827, 80.2707),
        fare: _estimatedFare,
        qrCode: _uuid.v4(),
      );
      
      // Create trip data for the display screen
      final tripData = TripData(
        ticketId: ticket.ticketId,
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        startTime: DateTime.now(),
        sourceLocation: const LatLng(13.0827, 80.2707),
        destinationLocation: const LatLng(13.0827, 80.2707),
        sourceName: _selectedFromStop!,
        destinationName: _selectedToStop!,
        status: TripStatus.active,
      );
      
      await _voiceService.speakPhrase('ticket_booked');
      
      // Navigate to ticket display
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticket: ticket,
            sessionId: sessionId,
            tripData: tripData,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = BookingStep.confirmation;
      });
      _voiceService.speak(_getPaymentErrorText());
    }
  }

  // Localized text methods
  String _getVoiceInstructionText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பல்மொழி ஆதரவுடன் உங்கள் பயணத்தைத் திட்டமிடுங்கள்';
      case 'hi':
        return 'बहुभाषी समर्थन के साथ अपनी यात्रा की योजना बनाएं';
      default:
        return 'Plan your journey with multilingual support';
    }
  }

  String _getTextInputPrompt() {
    switch (_currentLanguage) {
      case 'ta':
        return 'தொடக்கம் மற்றும் இலக்கு நிலையங்களை உள்ளிடவும்';
      case 'hi':
        return 'प्रारंभिक और गंतव्य स्टेशन दर्ज करें';
      default:
        return 'Enter your starting and destination stations';
    }
  }

  Widget _buildQuickSelectionButtons() {
    final popularStops = ['Chennai Central', 'Egmore', 'T Nagar', 'Marina Beach', 'Airport'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getQuickSelectText(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: popularStops.map((stop) => _buildStopChip(stop)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopChip(String stopName) {
    return ActionChip(
      label: Text(stopName),
      onPressed: () {
        if (_selectedFromStop == null) {
          setState(() {
            _selectedFromStop = stopName;
            _fromController.text = stopName;
          });
          _voiceService.speak('${_getFromText()}: $stopName');
        } else if (_selectedToStop == null && stopName != _selectedFromStop) {
          setState(() {
            _selectedToStop = stopName;
            _toController.text = stopName;
          });
          _calculateFare();
          _voiceService.speak('${_getToText()}: $stopName');
        }
      },
    );
  }

  String _getQuickSelectText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பிரபலமான நிலையங்கள்';
      case 'hi':
        return 'लोकप्रिय स्टेशन';
      default:
        return 'Popular Stations';
    }
  }

  String _getVoiceHintText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பேசுவதற்கு தொடுங்கள்';
      case 'hi':
        return 'बोलने के लिए टैप करें';
      default:
        return 'Tap to speak';
    }
  }

  String _getFromText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'இருந்து';
      case 'hi':
        return 'से';
      default:
        return 'From';
    }
  }

  String _getToText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'வரை';
      case 'hi':
        return 'तक';
      default:
        return 'To';
    }
  }

  String _getFareText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'கட்டணம்';
      case 'hi':
        return 'किराया';
      default:
        return 'Fare';
    }
  }

  String _getConfirmText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'உறுதிப்படுத்து';
      case 'hi':
        return 'पुष्टि करें';
      default:
        return 'Confirm';
    }
  }

  String _getClearText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'அழि';
      case 'hi':
        return 'साफ़ करें';
      default:
        return 'Clear';
    }
  }

  String _getBookTicketText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'டிக்கெட் முன்பதிவு';
      case 'hi':
        return 'टिकट बुक करें';
      default:
        return 'Book Ticket';
    }
  }

  String _getVoiceBookingText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'வாய்ஸ் முன்பதிவு';
      case 'hi':
        return 'वॉयस बुकिंग';
      default:
        return 'Voice Booking';
    }
  }

  String _getSkipLanguageText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'தவிர்';
      case 'hi':
        return 'छोड़ें';
      default:
        return 'Skip';
    }
  }

  String _getRouteSelectionText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பாதை தேர்வு';
      case 'hi':
        return 'रूट चयन';
      default:
        return 'Route Selection';
    }
  }

  String _getFromHintText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'தொடக்க நிலையம்';
      case 'hi':
        return 'प्रारंभिक स्टेशन';
      default:
        return 'Starting station';
    }
  }

  String _getToHintText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'இலக்கு நிலையம்';
      case 'hi':
        return 'गंतव्य स्टेशन';
      default:
        return 'Destination station';
    }
  }

  String _getConfirmationText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'உங்கள் பயண விவரங்களை உறுதிப்படுத்தவும்';
      case 'hi':
        return 'अपनी यात्रा के विवरण की पुष्टि करें';
      default:
        return 'Confirm your journey details';
    }
  }

  String _getPayText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பணம் செலுத்து';
      case 'hi':
        return 'भुगतान करें';
      default:
        return 'Pay Now';
    }
  }

  String _getEditText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'திருத்து';
      case 'hi':
        return 'संपादित करें';
      default:
        return 'Edit';
    }
  }

  String _getProcessingPaymentText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பணம் செலுத்தல் செயலாக்கப்படுகிறது...';
      case 'hi':
        return 'भुगतान प्रोसेसिंग...';
      default:
        return 'Processing payment...';
    }
  }

  String _getPaymentErrorText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பணம் செலுத்துவதில் பிழை. மீண்டும் முயற்சி செய்யுங்கள்.';
      case 'hi':
        return 'भुगतान में त्रुटि। कृपया पुनः प्रयास करें।';
      default:
        return 'Payment error. Please try again.';
    }
  }

  String _getClearedText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'தேர்வுகள் அழிக்கப்பட்டன';
      case 'hi':
        return 'चयन साफ़ कर दिए गए';
      default:
        return 'Selections cleared';
    }
  }

  String _getToDestinationPrompt() {
    switch (_currentLanguage) {
      case 'ta':
        return 'இப்போது உங்கள் இலக்கைச் சொல்லுங்கள்';
      case 'hi':
        return 'अब अपना गंतव्य बताएं';
      default:
        return 'Now tell me your destination';
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}
