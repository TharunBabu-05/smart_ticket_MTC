import 'package:flutter/material.dart';
import '../services/voice_multilingual_service.dart';

/// Widget for TTS-guided voice assistance
class VoiceGuidanceWidget extends StatefulWidget {
  final String? hint;
  final String fieldType; // 'source' or 'destination'
  final Function()? onGuidanceStart;
  final Function()? onGuidanceStop;

  const VoiceGuidanceWidget({
    Key? key,
    this.hint,
    required this.fieldType,
    this.onGuidanceStart,
    this.onGuidanceStop,
  }) : super(key: key);

  @override
  State<VoiceGuidanceWidget> createState() => _VoiceGuidanceWidgetState();
}

class _VoiceGuidanceWidgetState extends State<VoiceGuidanceWidget>
    with TickerProviderStateMixin {
  bool _isGuidanceActive = false;
  bool _isPressed = false;
  late VoiceMultilingualService _voiceService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceMultilingualService();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceGuidance() async {
    setState(() => _isGuidanceActive = true);
    _pulseController.repeat(reverse: true);
    widget.onGuidanceStart?.call();

    try {
      await _voiceService.guideStationSelection(
        fieldType: widget.fieldType,
        onStationSelected: (station) {
          // Station selection will be handled by parent widget
        },
      );
    } catch (e) {
      _showError('Voice guidance failed. Please try typing instead.');
    } finally {
      _stopGuidance();
    }
  }

  void _stopGuidance() {
    setState(() => _isGuidanceActive = false);
    _pulseController.stop();
    widget.onGuidanceStop?.call();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildVoiceButton() {
    return Material(
      shape: CircleBorder(),
      elevation: _isPressed ? 0 : 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _isGuidanceActive ? _stopGuidance : _handleVoiceGuidance,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isGuidanceActive
                  ? [Colors.orange.shade400, Colors.orange.shade600]
                  : [Colors.blue.shade400, Colors.blue.shade600],
            ),
            boxShadow: _isPressed 
              ? [] 
              : [
                  BoxShadow(
                    color: (_isGuidanceActive ? Colors.orange : Colors.blue)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
          ),
          child: _isGuidanceActive 
            ? AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              )
            : Icon(
                Icons.mic,
                color: Colors.white,
                size: 28,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice guidance status
            if (_isGuidanceActive) ...[
              Text(
                'Voice Guidance Active',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Listen to the instructions and select from the dropdown',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            
            // Voice button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVoiceButton(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isGuidanceActive 
                          ? 'Tap to stop guidance'
                          : 'Tap for voice assistance',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        widget.hint ?? 'Get spoken instructions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced text field with voice feedback
class VoiceTextField extends StatefulWidget {
  final String label;
  final String fieldType; // 'source' or 'destination'
  final TextEditingController controller;
  final List<String> suggestions;
  final Function(String) onChanged;
  final VoiceMultilingualService voiceService;

  const VoiceTextField({
    Key? key,
    required this.label,
    required this.fieldType,
    required this.controller,
    required this.suggestions,
    required this.onChanged,
    required this.voiceService,
  }) : super(key: key);

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = widget.suggestions;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty) {
      setState(() {
        _filteredSuggestions = widget.suggestions;
        _showSuggestions = false;
      });
    } else {
      setState(() {
        _filteredSuggestions = widget.suggestions
            .where((station) => station.toLowerCase().contains(text))
            .toList();
        _showSuggestions = _filteredSuggestions.isNotEmpty;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.onChanged(suggestion);
    widget.voiceService.processTextInput(suggestion, widget.fieldType);
    setState(() => _showSuggestions = false);
  }

  Future<void> _startVoiceInput() async {
    if (!widget.voiceService.isSttEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice input not available')),
      );
      return;
    }

    setState(() => _isListening = true);

    await widget.voiceService.startListening(
      onResult: (result) {
        setState(() => _isListening = false);
        if (result.isNotEmpty) {
          // Process the voice result through the smart recognition
          final processedText = widget.voiceService.processVoiceInput(result);
          widget.controller.text = processedText;
          widget.onChanged(processedText);
          
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice input: "$result"'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
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

  Widget _buildSuffixIcon() {
    final hasText = widget.controller.text.isNotEmpty;
    
    if (_isListening) {
      return Container(
        width: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }

    if (hasText) {
      return Container(
        width: 96,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.mic, color: Colors.blue),
              onPressed: _startVoiceInput,
              tooltip: 'Voice Input',
            ),
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                widget.controller.clear();
                widget.onChanged('');
                setState(() => _showSuggestions = false);
              },
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.mic, color: Colors.blue),
      onPressed: _startVoiceInput,
      tooltip: 'Voice Input',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(
              widget.fieldType == 'source' 
                ? Icons.location_on 
                : Icons.flag,
            ),
            suffixIcon: _buildSuffixIcon(),
          ),
          onChanged: widget.onChanged,
        ),
        
        // Suggestions dropdown
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                  leading: Icon(Icons.location_city, size: 16),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Language selector widget with voice support
class LanguageSelectorWidget extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;
  final VoiceMultilingualService voiceService;

  const LanguageSelectorWidget({
    Key? key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.voiceService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languages = VoiceMultilingualService.availableLanguages;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language / மொழியை தேர்ந்தெடுக்கவும் / भाषा चुनें',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: languages.entries.map((entry) {
                final isSelected = entry.key == currentLanguage;
                return ChoiceChip(
                  label: Text(entry.value['name']!),
                  selected: isSelected,
                  onSelected: (_) async {
                    await onLanguageChanged(entry.key);
                    await voiceService.speak(
                      'Language changed to ${entry.value['name']}'
                    );
                  },
                  selectedColor: Colors.blue.shade100,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
