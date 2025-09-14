import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../services/voice_multilingual_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final ChatbotService _chatbot = ChatbotService();
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _initializeChat();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() async {
    // Initialize voice service
    await _voiceService.initialize();
    
    // Welcome message
    setState(() {
      _messages.add(ChatMessage(
        text: "Hello! I'm your FareGuard assistant. How can I help you today? 😊",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    // Show quick actions
    _showQuickActions();
  }

  void _showQuickActions() {
    setState(() {
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        timestamp: DateTime.now(),
        isQuickActions: true,
      ));
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();
    _messageController.clear();

    // Get bot response
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate thinking time
    final response = await _chatbot.getResponse(text);
    
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
    
    // Speak the response if voice is enabled
    if (_voiceService.isTtsEnabled) {
      await _voiceService.speak(response);
    }
  }

  void _startVoiceInput() async {
    if (!_voiceService.isSttEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isListening = true);

    await _voiceService.startListening(
      onResult: (result) {
        setState(() => _isListening = false);
        if (result.isNotEmpty) {
          _sendMessage(result);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.smart_toy, color: colorScheme.onPrimary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FareGuard Assistant',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                Text(
                  'Always here to help!',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.normal,
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              _voiceService.isTtsEnabled ? Icons.volume_up : Icons.volume_off,
              color: colorScheme.onPrimary,
            ),
            onPressed: () {
              // Toggle TTS - implement if needed
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Typing indicator
                  return _buildTypingIndicator();
                }
                
                final message = _messages[index];
                if (message.isQuickActions) {
                  return _buildQuickActionsWidget();
                }
                
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: colorScheme.shadow.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about FareGuard...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Voice input button
                Container(
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : Colors.blue,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                    onPressed: _isListening ? null : _startVoiceInput,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUser 
            ? colorScheme.primary 
            : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser 
                  ? colorScheme.onPrimary.withOpacity(0.7) 
                  : colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _typingAnimationController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(
                      0.3 + (0.7 * (((_typingAnimationController.value + index * 0.33) % 1))),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActionsWidget() {
    final categories = _chatbot.getCategories();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Help Topics:',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              return ActionChip(
                label: Text(_chatbot.getCategoryDisplayName(category)),
                onPressed: () {
                  final questions = _chatbot.getQuestionsByCategory(category);
                  if (questions.isNotEmpty) {
                    _sendMessage(questions.first);
                  }
                },
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isQuickActions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isQuickActions = false,
  });
}
