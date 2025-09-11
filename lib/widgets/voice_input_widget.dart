import 'package:flutter/material.dart';
import '../services/voice_multilingual_service.dart';

/// Voice Input Widget for voice-controlled interactions
class VoiceInputWidget extends StatefulWidget {
  final Function(String) onVoiceInput;
  final String? hintText;
  final bool autoListen;
  final Duration listeningTimeout;
  final VoidCallback? onListeningStart;
  final VoidCallback? onListeningStop;

  const VoiceInputWidget({
    Key? key,
    required this.onVoiceInput,
    this.hintText,
    this.autoListen = false,
    this.listeningTimeout = const Duration(seconds: 10),
    this.onListeningStart,
    this.onListeningStop,
  }) : super(key: key);

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  bool _isListening = false;
  String _currentText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.autoListen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startListening() async {
    if (!_voiceService.isAvailable) {
      _showError('Voice input not available. Please use text input.');
      return;
    }

    setState(() {
      _isListening = true;
      _currentText = '';
    });

    _pulseController.repeat(reverse: true);
    widget.onListeningStart?.call();

    try {
      final result = await _voiceService.startListening(
        timeout: widget.listeningTimeout,
        onPartialResult: (text) {
          setState(() {
            _currentText = text;
          });
        },
      );

      if (result != null && result.isNotEmpty) {
        widget.onVoiceInput(result);
      } else {
        await _voiceService.speak('Voice input is currently not available. Please use text input.');
      }
    } catch (e) {
      _showError('Voice recognition failed. Please use text input.');
    } finally {
      _stopListening();
    }
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _currentText = '';
    });
    _pulseController.stop();
    _voiceService.stopListening();
    widget.onListeningStop?.call();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice input status
            if (_isListening) ...[
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.mic,
                      size: 48,
                      color: Colors.red,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Listening...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_currentText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentText,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ] else ...[
              // Voice input button
              GestureDetector(
                onTap: _startListening,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.hintText ?? 'Tap to speak',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Stop listening button (when listening)
            if (_isListening) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _stopListening,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

/// Language Selector Widget
class LanguageSelectorWidget extends StatefulWidget {
  final Function(String) onLanguageChanged;
  final String currentLanguage;

  const LanguageSelectorWidget({
    Key? key,
    required this.onLanguageChanged,
    required this.currentLanguage,
  }) : super(key: key);

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Select Language / மொழி தேர்வு / भाषा चुनें',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Language options
            ...VoiceMultilingualService.availableLanguages.entries.map(
              (entry) => _buildLanguageOption(
                entry.key,
                entry.value['name']!,
                entry.value['flag']!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name, String flag) {
    final isSelected = widget.currentLanguage == code;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await _voiceService.setLanguage(code);
            widget.onLanguageChanged(code);
            
            // Speak welcome message in selected language
            await _voiceService.speakPhrase('welcome');
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Voice-enabled TextField
class VoiceTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final Function(String)? onVoiceInput;
  final bool enabled;

  const VoiceTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.onVoiceInput,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        suffixIcon: _voiceService.isTtsEnabled
            ? IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.speaker_notes,
                  color: _isListening ? Colors.red : Colors.blue,
                ),
                onPressed: _isListening ? null : _startVoiceHelp,
                tooltip: 'Tap for voice guidance',
              )
            : null,
      ),
    );
  }

  Future<void> _startVoiceHelp() async {
    if (!_voiceService.isTtsEnabled) return;

    setState(() => _isListening = true);

    try {
      // Provide voice guidance instead of voice input
      await _voiceService.speak(
        'Please type ${widget.labelText.toLowerCase()} in the text field. Voice input is currently not available.'
      );
    } finally {
      setState(() => _isListening = false);
    }
  }
}
