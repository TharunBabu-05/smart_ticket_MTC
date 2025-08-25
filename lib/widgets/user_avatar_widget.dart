import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserAvatarWidget extends StatefulWidget {
  final double size;
  final bool showName;
  final String? customName;
  
  const UserAvatarWidget({
    Key? key,
    this.size = 40,
    this.showName = false,
    this.customName,
  }) : super(key: key);

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  String _avatarId = 'avatar_1';
  String _userName = 'User';

  // Avatar options (same as in profile screen)
  final Map<String, String> _avatarEmojis = {
    'avatar_1': '👨‍💼',
    'avatar_2': '👩‍💼',
    'avatar_3': '🧑‍🎓',
    'avatar_4': '👨‍🔬',
    'avatar_5': '👩‍🎨',
    'avatar_6': '🧑‍🏫',
    'avatar_7': '👨‍⚕️',
    'avatar_8': '👩‍🚀',
    'avatar_9': '🧑‍💻',
    'avatar_10': '👨‍🎨',
    'avatar_11': '👩‍🔧',
    'avatar_12': '🧑‍🍳',
    'avatar_13': '👨‍🎤',
    'avatar_14': '👩‍🏃',
    'avatar_15': '🧑‍🎮',
  };

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarId = prefs.getString('user_avatar') ?? 'avatar_1';
      final userName = prefs.getString('user_name') ?? 'User';
      
      if (mounted) {
        setState(() {
          _avatarId = avatarId;
          _userName = userName;
        });
      }
    } catch (e) {
      print('Error loading user avatar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = widget.customName ?? _userName;
    
    return Column(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary,
              width: widget.size > 60 ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              _avatarEmojis[_avatarId] ?? '👨‍💼',
              style: TextStyle(
                fontSize: widget.size * 0.4,
              ),
            ),
          ),
        ),
        if (widget.showName) ...[
          SizedBox(height: 8),
          Text(
            displayName,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: widget.size > 60 ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// Static method to get current user avatar for use in other widgets
class AvatarHelper {
  static const Map<String, String> avatarEmojis = {
    'avatar_1': '👨‍💼',
    'avatar_2': '👩‍💼',
    'avatar_3': '🧑‍🎓',
    'avatar_4': '👨‍🔬',
    'avatar_5': '👩‍🎨',
    'avatar_6': '🧑‍🏫',
    'avatar_7': '👨‍⚕️',
    'avatar_8': '👩‍🚀',
    'avatar_9': '🧑‍💻',
    'avatar_10': '👨‍🎨',
    'avatar_11': '👩‍🔧',
    'avatar_12': '🧑‍🍳',
    'avatar_13': '👨‍🎤',
    'avatar_14': '👩‍🏃',
    'avatar_15': '🧑‍🎮',
  };

  static Future<String> getCurrentAvatarEmoji() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarId = prefs.getString('user_avatar') ?? 'avatar_1';
      return avatarEmojis[avatarId] ?? '👨‍💼';
    } catch (e) {
      return '👨‍💼';
    }
  }

  static Future<String> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name') ?? 'User';
    } catch (e) {
      return 'User';
    }
  }
}
