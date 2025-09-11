import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';

/// Voice and Multilingual Support Service for FareGuard
/// Supports Tamil, Hindi, and English for accessibility
/// Note: Speech-to-text temporarily disabled due to compatibility issues
class VoiceMultilingualService {
  static final VoiceMultilingualService _instance = VoiceMultilingualService._internal();
  factory VoiceMultilingualService() => _instance;
  VoiceMultilingualService._internal();

  // Speech to Text - temporarily disabled
  bool _speechEnabled = false;
  
  // Text to Speech
  late FlutterTts _flutterTts;
  bool _ttsEnabled = false;
  
  // Translator
  final GoogleTranslator _translator = GoogleTranslator();
  
  // Current language settings
  String _currentLanguage = 'en'; // Default to English
  String _currentLocale = 'en-US';
  
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

  // Bus stop name mappings for voice recognition
  static const Map<String, List<String>> _busStopMappings = {
    'Chennai Central': ['chennai central', 'central station', 'மத்திய நிலையம்', 'चेन्नई सेंट्रल'],
    'Egmore': ['egmore', 'egmore station', 'எக்மோர்', 'एगमोर'],
    'T Nagar': ['t nagar', 'tee nagar', 'pondy bazaar', 'டி நகர்', 'टी नगर'],
    'Marina Beach': ['marina beach', 'marina', 'மெரினா கடற்கரை', 'मरीना बीच'],
    'Airport': ['airport', 'chennai airport', 'விமான நிலையம்', 'हवाई अड्डा'],
    'Guindy': ['guindy', 'guindy station', 'கிண்டி', 'गिंडी'],
    'Adyar': ['adyar', 'adyar depot', 'அடையாறு', 'अड्यार'],
    'Velachery': ['velachery', 'velachery bus stand', 'வேளச்சேரி', 'वेलाचेरी'],
  };

  /// Initialize the voice and multilingual service
  Future<bool> initialize() async {
    try {
      // Speech to Text temporarily disabled due to compatibility issues
      _speechEnabled = false;
      debugPrint('Speech recognition temporarily disabled');

      // Initialize Text to Speech
      _flutterTts = FlutterTts();
      _ttsEnabled = true;
      
      await _configureTts();
      
      debugPrint('Voice and Multilingual Service initialized successfully');
      debugPrint('Speech enabled: $_speechEnabled, TTS enabled: $_ttsEnabled');
      
      return _ttsEnabled; // Return true if TTS is working
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

  /// Start listening for voice input
  /// Note: Currently disabled due to compatibility issues
  Future<String?> startListening({
    Duration timeout = const Duration(seconds: 10),
    Function(String)? onPartialResult,
  }) async {
    debugPrint('Voice input temporarily disabled');
    await speak('Voice input is currently not available. Please use the text input instead.');
    return null;
  }

  /// Stop listening
  Future<void> stopListening() async {
    // No-op since speech recognition is disabled
    debugPrint('Stop listening called (no-op)');
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

  /// Process voice input for bus stop recognition
  String? processBusStopVoiceInput(String voiceInput) {
    final input = voiceInput.toLowerCase().trim();
    
    for (final stop in _busStopMappings.entries) {
      for (final variant in stop.value) {
        if (input.contains(variant.toLowerCase())) {
          return stop.key;
        }
      }
    }
    
    return null;
  }

  /// Voice-guided ticket booking flow
  /// Note: Currently uses TTS only due to speech recognition compatibility issues
  Future<Map<String, String?>> voiceGuidedBooking() async {
    final Map<String, String?> bookingData = {
      'source': null,
      'destination': null,
    };

    try {
      // Welcome message
      await speakPhrase('welcome');
      await Future.delayed(const Duration(seconds: 2));
      
      // Inform user to use text input
      await speak('Please use the text input fields or tap the bus stop suggestions to select your journey.');
      
      return bookingData;
    } catch (e) {
      debugPrint('Voice booking error: $e');
      await speakPhrase('not_understood');
      return bookingData;
    }
  }

  /// Check if services are available
  bool get isVoiceEnabled => false; // Temporarily disabled
  bool get isTtsEnabled => _ttsEnabled;
  bool get isAvailable => _ttsEnabled; // Only TTS is available

  /// Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}

/// Extension for easy phrase access
extension VoicePhrases on VoiceMultilingualService {
  static const Map<String, Map<String, String>> phrases = VoiceMultilingualService._phrases;
}
