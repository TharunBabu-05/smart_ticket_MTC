import 'package:flutter/material.dart';
import '../services/voice_multilingual_service.dart';

/// Simple TTS-only voice widget
class VoiceTTSWidget extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;

  const VoiceTTSWidget({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon = Icons.volume_up,
    this.color,
  }) : super(key: key);

  @override
  State<VoiceTTSWidget> createState() => _VoiceTTSWidgetState();
}

class _VoiceTTSWidgetState extends State<VoiceTTSWidget>
    with SingleTickerProviderStateMixin {
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  bool _isPlaying = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);
    _animationController.forward();

    try {
      await _voiceService.speak(widget.text);
      widget.onPressed?.call();
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      _animationController.reverse();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.volume_up : widget.icon,
              color: widget.color ?? Theme.of(context).primaryColor,
            ),
            onPressed: _isPlaying ? null : _handlePress,
          ),
        );
      },
    );
  }
}

/// Language selector widget
class LanguageSelectorWidget extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelectorWidget({
    Key? key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'ta', 'name': 'தமிழ்', 'flag': '🇮🇳'},
      {'code': 'hi', 'name': 'हिंदी', 'flag': '🇮🇳'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguage,
          icon: const Icon(Icons.language),
          items: languages.map((lang) {
            return DropdownMenuItem<String>(
              value: lang['code'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang['flag']!),
                  const SizedBox(width: 8),
                  Text(lang['name']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onLanguageChanged(value);
            }
          },
        ),
      ),
    );
  }
}

/// Voice guidance card widget
class VoiceGuidanceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  const VoiceGuidanceCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              VoiceTTSWidget(text: '$title. $description'),
            ],
          ),
        ),
      ),
    );
  }
}
