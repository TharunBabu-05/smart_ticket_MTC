import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice and Multilingual Support Service for FareGuard
/// Complete TTS + STT implementation with smart voice guidance
class VoiceMultilingualService {
  static final VoiceMultilingualService _instance = VoiceMultilingualService._internal();
  factory VoiceMultilingualService() => _instance;
  VoiceMultilingualService._internal();

  // Text to Speech
  late FlutterTts _flutterTts;
  bool _ttsEnabled = false;
  
  // Speech to Text
  late stt.SpeechToText _speechToText;
  bool _sttEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  
  // Translator
  final GoogleTranslator _translator = GoogleTranslator();
  
  // Current language settings
  String _currentLanguage = 'en'; // Default to English
  String _currentLocale = 'en-US';
  
  // Voice guidance state
  bool _isGuiding = false;
  
  // Language configurations
  static const Map<String, Map<String, String>> _languages = {
    'en': {
      'name': 'English',
      'locale': 'en-US',
      'ttsCode': 'en-US',
      'flag': '🇺🇸',
    },
    'ta': {
      'name': 'தமிழ்',
      'locale': 'ta-IN',
      'ttsCode': 'ta-IN',
      'flag': '🇮🇳',
    },
    'hi': {
      'name': 'हिंदी',
      'locale': 'hi-IN',
      'ttsCode': 'hi-IN',
      'flag': '🇮🇳',
    },
  };

  // Pre-defined phrases for bus ticketing
  static const Map<String, Map<String, String>> _phrases = {
    'welcome': {
      'en': 'Welcome to FareGuard! How can I help you today?',
      'ta': 'ஃபேர்கார்டில் வரவேற்கிறோம்! இன்று நான் உங்களுக்கு எப்படி உதவ முடியும்?',
      'hi': 'फेयरगार्ड में आपका स्वागत है! आज मैं आपकी कैसे मदद कर सकता हूं?',
    },
    'book_ticket': {
      'en': 'Let me help you book a ticket. Please say your destination.',
      'ta': 'டிக்கெட் முன்பதிவு செய்ய உதவுகிறேன். உங்கள் இலக்கை சொல்லுங்கள்.',
      'hi': 'मैं आपको टिकट बुक करने में मदद करूंगा। कृपया अपना गंतव्य बताएं।',
    },
    'ask_source': {
      'en': 'Where would you like to start your journey from?',
      'ta': 'நீங்கள் எங்கிருந்து பயணத்தைத் தொடங்க விரும்புகிறீர்கள்?',
      'hi': 'आप अपनी यात्रा कहाँ से शुरू करना चाहते हैं?',
    },
    'ask_destination': {
      'en': 'Where would you like to go?',
      'ta': 'நீங்கள் எங்கு செல்ல விரும்புகிறீர்கள்?',
      'hi': 'आप कहाँ जाना चाहते हैं?',
    },
    'listening': {
      'en': 'Listening... Please speak now',
      'ta': 'கேட்டுக்கொண்டிருக்கிறேன்... தயவுசெய்து பேசுங்கள்',
      'hi': 'सुन रहा हूं... कृपया अब बोलें',
    },
    'not_understood': {
      'en': 'Sorry, I didn\'t understand. Please try again.',
      'ta': 'மன்னிக்கவும், புரியவில்லை. மீண்டும் முயற்சி செய்யுங்கள்.',
      'hi': 'क्षमा करें, मैं समझ नहीं पाया। कृपया फिर से कोशिश करें।',
    },
    'ticket_booked': {
      'en': 'Your ticket has been booked successfully!',
      'ta': 'உங்கள் டிக்கெட் வெற்றிகரமாக முன்பதிவு செய்யப்பட்டது!',
      'hi': 'आपका टिकट सफलतापूर्वक बुक हो गया है!',
    },
    'select_language': {
      'en': 'Please select your preferred language',
      'ta': 'உங்கள் விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
      'hi': 'कृपया अपनी पसंदीदा भाषा चुनें',
    },
  };

  // Bus stop name mappings for voice recognition - Enhanced for Chennai
  static const Map<String, List<String>> _busStopMappings = {
    'Chennai Central': ['chennai central', 'central station', 'central', 'மத்திய நிலையம்', 'चेन्नई सेंट्रल', 'sentral'],
    'Egmore': ['egmore', 'egmore station', 'எக்மோர்', 'एगमोर'],
    'T Nagar': ['t nagar', 'tee nagar', 'pondy bazaar', 'டி நகர்', 'टी नगर', 'tnagar', 'nagar'],
    'Marina Beach': ['marina beach', 'marina', 'மெரினா கடற்கரை', 'मरीना बीच', 'beach'],
    'Airport': ['airport', 'chennai airport', 'விமான நிலையம்', 'हवाई अड्डा', 'international airport'],
    'Guindy': ['guindy', 'guindy station', 'கிண்டி', 'गिंडी'],
    'Adyar': ['adyar', 'adyar depot', 'அடையாறு', 'अड्यार'],
    'Velachery': ['velachery', 'velachery bus stand', 'வேளச்சேரி', 'वेलाचेरी'],
    'Tambaram': ['tambaram', 'tambaram station', 'தாம்பரம்', 'तांबरम'],
    'Anna Nagar': ['anna nagar', 'அண்ணா நகர்', 'अन्ना नगर', 'annanagar'],
    'Vadapalani': ['vadapalani', 'வடபழனி', 'वडापलानी'],
    'Koyambedu': ['koyambedu', 'koyambedu bus terminus', 'கோயம்பேடு', 'कोयंबेडु'],
    'Mylapore': ['mylapore', 'மயிலாப்பூர்', 'मैलापुर'],
    'Thiruvanmiyur': ['thiruvanmiyur', 'திருவான்மியூர்', 'तिरुवनमियूर'],
    'Sholinganallur': ['sholinganallur', 'OMR', 'शोलिंगनल्लूर', 'சோழிங்கநல்லூர்'],
    'Perambur': ['perambur', 'பெரம்பூர்', 'परंबुर'],
    'Avadi': ['avadi', 'அவடி', 'अवडी'],
    'Chromepet': ['chromepet', 'குரோம்பேட்', 'क्रोमपेट'],
    'Pallavaram': ['pallavaram', 'பல்லாவரம்', 'पल्लावरम'],
  };

  /// Initialize the voice and multilingual service
  Future<bool> initialize() async {
    try {
      // Initialize Text to Speech
      _flutterTts = FlutterTts();
      _ttsEnabled = true;
      
      await _configureTts();
      
      // Initialize Speech to Text
      _speechToText = stt.SpeechToText();
      _sttEnabled = await _speechToText.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
      
      debugPrint('Voice and Multilingual Service initialized successfully');
      debugPrint('TTS enabled: $_ttsEnabled');
      debugPrint('STT enabled: $_sttEnabled');
      
      return _ttsEnabled && _sttEnabled;
    } catch (e) {
      debugPrint('Error initializing Voice service: $e');
      return false;
    }
  }

  /// Configure TTS settings
  Future<void> _configureTts() async {
    if (!_ttsEnabled) return;

    await _flutterTts.setLanguage(_languages[_currentLanguage]!['ttsCode']!);
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    if (Platform.isAndroid) {
      await _flutterTts.setEngine('com.google.android.tts');
    }
  }

  /// Change language setting
  Future<void> setLanguage(String languageCode) async {
    if (!_languages.containsKey(languageCode)) return;
    
    _currentLanguage = languageCode;
    _currentLocale = _languages[languageCode]!['locale']!;
    
    await _configureTts();
    
    debugPrint('Language changed to: ${_languages[languageCode]!['name']}');
  }

  /// Get current language
  String get currentLanguage => _currentLanguage;
  
  /// Get available languages
  static Map<String, Map<String, String>> get availableLanguages => _languages;

  /// Speak text in current language
  Future<void> speak(String text) async {
    if (!_ttsEnabled || text.isEmpty) return;
    
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  /// Speak predefined phrase
  Future<void> speakPhrase(String phraseKey) async {
    if (_phrases.containsKey(phraseKey) && 
        _phrases[phraseKey]!.containsKey(_currentLanguage)) {
      await speak(_phrases[phraseKey]![_currentLanguage]!);
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_ttsEnabled) {
      await _flutterTts.stop();
    }
  }

  // Speech-to-Text methods
  
  /// Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_sttEnabled || _isListening) {
      onError?.call('Speech recognition not available or already listening');
      return;
    }

    try {
      await speakPhrase('listening');
      await Future.delayed(const Duration(milliseconds: 1500));

      _isListening = true;
      bool started = await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            onResult(_lastWords);
            debugPrint('Voice input recognized: $_lastWords');
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        onSoundLevelChange: (level) => debugPrint('Sound level: $level'),
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        localeId: _languages[_currentLanguage]!['locale']!,
      );

      if (!started) {
        _isListening = false;
        onError?.call('Failed to start speech recognition');
      }
    } catch (e) {
      _isListening = false;
      onError?.call('Speech recognition error: $e');
      debugPrint('STT Error: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_sttEnabled && _isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if speech-to-text is available
  bool get isSttEnabled => _sttEnabled;

  /// Get available locales for speech recognition
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (_sttEnabled) {
      return await _speechToText.locales();
    }
    return [];
  }

  /// Smart voice guidance for station selection
  Future<void> guideStationSelection({
    required String fieldType, // 'source' or 'destination'
    required Function(String) onStationSelected,
  }) async {
    if (!_ttsEnabled) return;
    
    _isGuiding = true;
    
    try {
      // Ask for station
      if (fieldType == 'source') {
        await speakPhrase('ask_source');
      } else {
        await speakPhrase('ask_destination');
      }
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Offer popular suggestions
      await speak(_getPopularStationsPrompt());
      
    } catch (e) {
      debugPrint('Voice guidance error: $e');
    } finally {
      _isGuiding = false;
    }
  }

  /// Announce popular stations for selection
  Future<void> announcePopularStations(List<String> stations) async {
    if (!_ttsEnabled || stations.isEmpty) return;
    
    final stationsText = stations.join(', ');
    await speak('${_getAvailableStationsText()}: $stationsText');
  }

  /// Smart text input with voice feedback
  Future<void> processTextInput(String input, String fieldType) async {
    if (!_ttsEnabled) return;
    
    final station = processBusStopVoiceInput(input);
    if (station != null) {
      if (fieldType == 'source') {
        await speak('${_getFromConfirmation()}: $station');
      } else {
        await speak('${_getToConfirmation()}: $station');
      }
    }
  }

  String _getPopularStationsPrompt() {
    switch (_currentLanguage) {
      case 'ta':
        return 'பிரபலமான இடங்கள்: சென்னை எம்.ஜி.ஆர். சென்ட்ரல், எக்மோர், டி.நகர், பார்க் டவுன், கிண்டி';
      case 'hi':
        return 'लोकप्रिय स्थान: चेन्नई एमजीआर सेंट्रल, एग्मोर, टी-नगर, पार्क टाउन, गिंडी';
      default:
        return 'Popular stations: Chennai Egmore, T-Nagar, Park Town, Guindy, Vadapalani';
    }
  }

  String _getAvailableStationsText() {
    switch (_currentLanguage) {
      case 'ta':
        return 'கிடைக்கும் நிலையங்கள்';
      case 'hi':
        return 'उपलब्ध स्टेशन';
      default:
        return 'Available stations';
    }
  }

  String _getFromConfirmation() {
    switch (_currentLanguage) {
      case 'ta':
        return 'புறப்படும் இடம்';
      case 'hi':
        return 'चलने का स्थान';
      default:
        return 'Departure from';
    }
  }

  String _getToConfirmation() {
    switch (_currentLanguage) {
      case 'ta':
        return 'செல்லும் இடம்';
      case 'hi':
        return 'जाने का स्थान';
      default:
        return 'Going to';
    }
  }

  /// Translate text to current language
  Future<String> translateText(String text, {String? targetLanguage}) async {
    try {
      final target = targetLanguage ?? _currentLanguage;
      if (target == 'en') return text; // No translation needed for English
      
      final translation = await _translator.translate(text, to: target);
      return translation.text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  /// Process voice input for bus stop recognition with improved fuzzy matching
  String? processBusStopVoiceInput(String voiceInput) {
    final input = voiceInput.toLowerCase().trim();
    debugPrint('Processing voice input: "$input"');
    
    // Direct matches first
    for (final stop in _busStopMappings.entries) {
      for (final variant in stop.value) {
        if (input.contains(variant.toLowerCase())) {
          debugPrint('Found direct match: ${stop.key}');
          return stop.key;
        }
      }
    }
    
    // Fuzzy matching for common speech recognition variations
    final cleanInput = input.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
    
    // Common variations and corrections
    final corrections = {
      'central': 'Chennai Central',
      'airport': 'Airport',
      'marina': 'Marina Beach',
      'nagar': 'T Nagar',
      'tnagar': 'T Nagar',
      'egmore': 'Egmore',
      'guindy': 'Guindy',
      'adyar': 'Adyar',
      'velachery': 'Velachery',
      'tambaram': 'Tambaram',
      'anna nagar': 'Anna Nagar',
      'vadapalani': 'Vadapalani',
      'koyambedu': 'Koyambedu',
    };
    
    for (final correction in corrections.entries) {
      if (cleanInput.contains(correction.key)) {
        debugPrint('Found fuzzy match: ${correction.value}');
        return correction.value;
      }
    }
    
    debugPrint('No match found for: "$input"');
    return null;
  }

  /// Voice-guided ticket booking flow (legacy method for TTS guidance)
  Future<Map<String, String?>> voiceGuidedBooking() async {
    final Map<String, String?> bookingData = {
      'source': null,
      'destination': null,
    };

    try {
      // Welcome message
      await speakPhrase('welcome');
      await Future.delayed(const Duration(seconds: 2));
      
      // Provide guidance for manual selection
      await speak('Please use the voice guidance buttons to get help selecting your stations');
      
      return bookingData;
    } catch (e) {
      debugPrint('Voice booking error: $e');
      await speakPhrase('not_understood');
      return bookingData;
    }
  }

  /// Process voice input and return cleaned/processed text
  String processVoiceInput(String voiceInput) {
    // Clean and normalize the voice input
    String processed = voiceInput.toLowerCase().trim();
    
    // Remove common filler words and phrases
    final fillerWords = ['uh', 'um', 'like', 'you know', 'well', 'so'];
    for (final filler in fillerWords) {
      processed = processed.replaceAll(RegExp('\\b$filler\\b'), '');
    }
    
    // Clean up multiple spaces
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    debugPrint('Processed voice input: "$processed"');
    return processed;
  }

  /// Check if services are available
  bool get isTtsEnabled => _ttsEnabled;
  bool get isGuiding => _isGuiding;
  bool get isAvailable => _ttsEnabled;

  /// Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}
