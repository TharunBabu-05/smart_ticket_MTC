import 'dart:async';
import 'dart:math';

/// Enhanced Chatbot Service for FareGuard
/// Supports comprehensive Q&A, smart matching, and contextual responses
class ChatbotService {
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  // Comprehensive FAQ with categories
  final Map<String, Map<String, String>> _categorizedFaq = {
    'ticket_booking': {
      'how to book a ticket': 'To book a ticket:\n1. Select your source station\n2. Choose your destination\n3. Select ticket type (Single/Return)\n4. Choose payment method\n5. Confirm booking\n\nYou can also use voice guidance by tapping the microphone icon!',
      'how to book return ticket': 'For return tickets:\n1. Select "Return Journey" option\n2. Choose both departure and return times\n3. The fare will be calculated for both directions\n4. Complete payment for the round trip',
      'ticket types available': 'Available ticket types:\n• Single Journey - One-way travel\n• Return Journey - Round trip\n• Student Discount - With valid ID\n• Senior Citizen - Age 60+ discount',
      'booking failed': 'If booking fails:\n1. Check your internet connection\n2. Verify payment details\n3. Ensure you\'re within booking distance\n4. Try refreshing the app\n5. Contact support if issue persists',
    },
    'voice_features': {
      'how to use voice guidance': 'Voice Features:\n🎤 **Voice Input**: Tap microphone icons to speak station names\n🔊 **Voice Output**: App speaks confirmations and guidance\n🌐 **Multilingual**: Works in English, Tamil, and Hindi\n\n**Quick Start**: Just say "Chennai Central to Egmore" and I\'ll guide you!',
      'voice not working': 'Voice Troubleshooting:\n1. ✅ Check microphone permission\n2. 🌐 Ensure internet connection\n3. 🔊 Test device audio\n4. 🔄 Restart the app\n5. 📱 Check device storage space\n\nFor best results, speak clearly and avoid background noise.',
      'change language for voice': 'To change voice language:\n1. Go to Settings ⚙️\n2. Select "Language Preferences"\n3. Choose: English, தமிழ் (Tamil), or हिंदी (Hindi)\n4. Voice guidance will adapt automatically',
      'voice commands': 'Useful voice commands:\n• "Book ticket from [source] to [destination]"\n• "Show me popular stations"\n• "Check my ticket history"\n• "Help with payment"\n• "Change language to Tamil/Hindi"',
    },
    'payments': {
      'how to pay': 'Payment Options:\n💳 **Credit/Debit Cards**: Visa, MasterCard, RuPay\n📱 **UPI**: Google Pay, PhonePe, Paytm, etc.\n🏦 **Net Banking**: All major banks\n💰 **Wallets**: Razorpay Wallet, Paytm Wallet\n\n**Secure**: All payments are encrypted and PCI compliant.',
      'payment failed': 'If payment fails:\n1. Check card/account balance\n2. Verify card details\n3. Try different payment method\n4. Check bank SMS/notifications\n5. Wait 5 minutes and retry\n6. Contact your bank if needed',
      'refund policy': 'Refund Policy:\n• ✅ Cancellation before 30 minutes: Full refund\n• ⚠️ Cancellation 15-30 minutes: 80% refund\n• ❌ No refund after departure time\n• 🕐 Refunds processed in 3-5 business days',
      'transaction failed': 'For transaction issues:\n1. Check your bank statement\n2. If amount deducted but no ticket, wait 24 hours\n3. Auto-refund will be initiated\n4. Contact support with transaction ID',
    },
    'app_usage': {
      'getting started': '🎉 **Welcome to FareGuard!**\n\n**Quick Setup:**\n1. 📍 Enable location services\n2. 🎤 Grant microphone permission\n3. 🌐 Choose your preferred language\n4. 🎯 You\'re ready to book!\n\n**First Booking**: Try our voice guidance - just tap the mic and speak!',
      'app features': '✨ **FareGuard Features:**\n\n🎤 **Voice Booking**: Speak to book tickets\n🌍 **Multilingual**: English, Tamil, Hindi\n📍 **Smart Location**: Auto-detect nearby stations\n🔒 **Fraud Detection**: Advanced security\n📊 **Fare Calculation**: Real-time pricing\n🎫 **Digital Tickets**: QR code based\n📱 **Offline Support**: Limited offline functionality',
      'how to navigate app': 'App Navigation:\n🏠 **Home**: Quick booking and popular stations\n🎫 **My Tickets**: View active and past tickets\n🎤 **Voice Booking**: Hands-free ticket booking\n⚙️ **Settings**: Preferences and account\n❓ **Help**: Chatbot and user manual\n🗺️ **Route Map**: View bus routes and stops',
      'permissions needed': 'Required Permissions:\n📍 **Location**: Find nearby stations\n🎤 **Microphone**: Voice commands\n🔔 **Notifications**: Ticket updates\n📷 **Camera**: QR code scanning (optional)\n💾 **Storage**: Offline maps (optional)',
    },
    'troubleshooting': {
      'app not working': 'App Troubleshooting:\n1. 🔄 Force close and restart app\n2. 📶 Check internet connection\n3. 🆕 Update to latest version\n4. 📱 Restart your device\n5. 💾 Clear app cache\n6. 🗑️ Reinstall if needed',
      'location not working': 'Location Issues:\n1. ✅ Enable location permission\n2. 🛰️ Turn on GPS/Location services\n3. 🏢 Move away from buildings if indoors\n4. 🔄 Refresh the app\n5. 📍 Manually select your station',
      'ticket not showing': 'If ticket doesn\'t appear:\n1. 📶 Check internet connection\n2. 🔄 Pull down to refresh\n3. 📧 Check email for confirmation\n4. 💳 Verify payment status\n5. 📞 Contact support with booking ID',
      'app crashing': 'App Crashes:\n1. 🔄 Restart the app\n2. 📱 Restart your device\n3. 💾 Free up device storage\n4. 🆕 Update the app\n5. 📧 Report crash with details',
    }
  };

  final List<String> _greetings = [
    'Hello! I\'m your FareGuard assistant. How can I help you today? 😊',
    'Hi there! I\'m here to help with all your FareGuard questions! 🚌',
    'Welcome! Ask me anything about ticket booking, voice features, or app usage! 👋',
    'Greetings! I can help you with bookings, payments, troubleshooting, and more! 🎫',
  ];

  final List<String> _farewells = [
    'Happy to help! Safe travels with FareGuard! 🚌✨',
    'You\'re welcome! Enjoy your journey! 🎫😊',
    'Glad I could assist! Have a great trip! 👋',
    'Anytime! FareGuard is here for all your travel needs! 🌟',
  ];

  // Context tracking for better conversations
  String _lastCategory = '';
  List<String> _conversationHistory = [];

  Future<String> getResponse(String userInput) async {
    final input = userInput.trim().toLowerCase();
    _conversationHistory.add(input);
    
    // Handle greetings
    if (_isGreeting(input)) {
      return _getRandomGreeting();
    }
    
    // Handle farewells
    if (_isFarewell(input)) {
      return _getRandomFarewell();
    }
    
    // Search through all categories for best match
    String bestMatch = '';
    String bestResponse = '';
    int highestScore = 0;
    
    for (final category in _categorizedFaq.keys) {
      for (final question in _categorizedFaq[category]!.keys) {
        final score = _calculateMatchScore(input, question);
        if (score > highestScore) {
          highestScore = score;
          bestMatch = question;
          bestResponse = _categorizedFaq[category]![question]!;
          _lastCategory = category;
        }
      }
    }
    
    // If good match found (score > 60%), return it
    if (highestScore > 60) {
      return bestResponse;
    }
    
    // Try keyword matching
    final keywordResponse = _getKeywordResponse(input);
    if (keywordResponse.isNotEmpty) {
      return keywordResponse;
    }
    
    // Default response with suggestions
    return _getDefaultResponse();
  }

  int _calculateMatchScore(String input, String question) {
    final inputWords = input.split(' ');
    final questionWords = question.split(' ');
    int matches = 0;
    
    for (final inputWord in inputWords) {
      for (final questionWord in questionWords) {
        if (_isSimilar(inputWord, questionWord)) {
          matches++;
          break;
        }
      }
    }
    
    return ((matches / inputWords.length) * 100).round();
  }

  bool _isSimilar(String word1, String word2) {
    if (word1 == word2) return true;
    if (word1.contains(word2) || word2.contains(word1)) return true;
    
    // Check for common typos and variations
    final synonyms = {
      'book': ['booking', 'reserve', 'buy', 'purchase'],
      'ticket': ['tkt', 'tkts', 'tickets'],
      'voice': ['speech', 'audio', 'mic', 'microphone'],
      'pay': ['payment', 'paying', 'money'],
      'help': ['support', 'assist', 'guide'],
      'problem': ['issue', 'error', 'trouble', 'fail', 'not working'],
    };
    
    for (final key in synonyms.keys) {
      if ((word1 == key && synonyms[key]!.contains(word2)) ||
          (word2 == key && synonyms[key]!.contains(word1))) {
        return true;
      }
    }
    
    return false;
  }

  String _getKeywordResponse(String input) {
    final keywordResponses = {
      'station': 'Popular stations include Chennai Central, Egmore, T Nagar, Guindy, Velachery, and Airport. You can speak station names or type them.',
      'fare': 'Fares are calculated based on distance. Base fare starts at ₹5. Use the fare calculator in the app for exact pricing.',
      'time': 'Bus timings vary by route. The app shows real-time schedules and estimated arrival times.',
      'route': 'View available routes on the map screen. All major Chennai bus routes are covered.',
      'student': 'Student discounts available with valid ID. Select "Student" ticket type during booking.',
      'senior': 'Senior citizen discounts for 60+ age. Show valid ID during travel.',
    };
    
    for (final keyword in keywordResponses.keys) {
      if (input.contains(keyword)) {
        return keywordResponses[keyword]!;
      }
    }
    
    return '';
  }

  bool _isGreeting(String input) {
    final greetings = ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'];
    return greetings.any((greeting) => input.contains(greeting));
  }

  bool _isFarewell(String input) {
    final farewells = ['bye', 'goodbye', 'thanks', 'thank you', 'thx'];
    return farewells.any((farewell) => input.contains(farewell));
  }

  String _getRandomGreeting() {
    return _greetings[Random().nextInt(_greetings.length)];
  }

  String _getRandomFarewell() {
    return _farewells[Random().nextInt(_farewells.length)];
  }

  String _getDefaultResponse() {
    return '''I'm not sure about that specific question. Here are some things I can help with:

🎫 **Ticket Booking**: "How to book a ticket"
🎤 **Voice Features**: "How to use voice guidance" 
💳 **Payments**: "How to pay"
🛠️ **Troubleshooting**: "App not working"
🚀 **Getting Started**: "App features"

Or try asking in different words! I'm always learning. 😊''';
  }

  List<String> getSuggestedQuestions() {
    final suggestions = <String>[];
    for (final category in _categorizedFaq.values) {
      suggestions.addAll(category.keys.take(2));
    }
    return suggestions;
  }

  List<String> getQuestionsByCategory(String category) {
    return _categorizedFaq[category]?.keys.toList() ?? [];
  }

  List<String> getCategories() {
    return _categorizedFaq.keys.toList();
  }

  String getCategoryDisplayName(String category) {
    final displayNames = {
      'ticket_booking': '🎫 Ticket Booking',
      'voice_features': '🎤 Voice Features',
      'payments': '💳 Payments',
      'app_usage': '📱 App Usage',
      'troubleshooting': '🛠️ Troubleshooting',
    };
    return displayNames[category] ?? category;
  }
}
