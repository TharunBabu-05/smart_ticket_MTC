import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility Service for FareGuard
/// Provides screen reader compatibility, high contrast, font scaling, and more
class AccessibilityService extends ChangeNotifier {
  static const String _highContrastKey = 'high_contrast_mode';
  static const String _fontScaleKey = 'font_scale_factor';
  static const String _colorBlindModeKey = 'color_blind_mode';
  static const String _gestureNavigationKey = 'gesture_navigation_enabled';

  // Accessibility states
  bool _highContrastEnabled = false;
  double _fontScaleFactor = 1.0;
  ColorBlindMode _colorBlindMode = ColorBlindMode.none;
  bool _gestureNavigationEnabled = false;
  bool _screenReaderEnabled = false;

  // Getters
  bool get highContrastEnabled => _highContrastEnabled;
  double get fontScaleFactor => _fontScaleFactor;
  ColorBlindMode get colorBlindMode => _colorBlindMode;
  bool get gestureNavigationEnabled => _gestureNavigationEnabled;
  bool get screenReaderEnabled => _screenReaderEnabled;

  /// Initialize accessibility service
  static Future<AccessibilityService> initialize() async {
    final service = AccessibilityService();
    await service._loadAccessibilitySettings();
    await service._checkScreenReaderStatus();
    return service;
  }

  /// Load accessibility settings from storage
  Future<void> _loadAccessibilitySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _highContrastEnabled = prefs.getBool(_highContrastKey) ?? false;
      _fontScaleFactor = prefs.getDouble(_fontScaleKey) ?? 1.0;
      _gestureNavigationEnabled = prefs.getBool(_gestureNavigationKey) ?? false;
      
      final colorBlindIndex = prefs.getInt(_colorBlindModeKey) ?? 0;
      _colorBlindMode = ColorBlindMode.values[colorBlindIndex];
      
      debugPrint('Accessibility settings loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading accessibility settings: $e');
    }
  }

  /// Check if screen reader is active
  Future<void> _checkScreenReaderStatus() async {
    try {
      // Check if TalkBack/VoiceOver is enabled
      final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
      _screenReaderEnabled = data.accessibleNavigation;
      
      if (_screenReaderEnabled) {
        debugPrint('Screen reader detected');
        // Announce app launch
        SemanticsService.announce(
          'FareGuard accessibility mode activated. Double tap to interact with elements.',
          TextDirection.ltr,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking screen reader status: $e');
    }
  }

  /// Toggle high contrast mode
  Future<void> toggleHighContrast() async {
    _highContrastEnabled = !_highContrastEnabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_highContrastKey, _highContrastEnabled);
      
      // Announce change
      if (_screenReaderEnabled) {
        SemanticsService.announce(
          'High contrast mode ${_highContrastEnabled ? 'enabled' : 'disabled'}',
          TextDirection.ltr,
        );
      }
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error saving high contrast setting: $e');
    }
  }

  /// Set font scale factor
  Future<void> setFontScaleFactor(double scale) async {
    if (scale < 0.8 || scale > 2.0) return;
    
    _fontScaleFactor = scale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontScaleKey, scale);
      
      // Announce change
      if (_screenReaderEnabled) {
        final percentage = (scale * 100).round();
        SemanticsService.announce(
          'Font size set to $percentage percent',
          TextDirection.ltr,
        );
      }
      
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error saving font scale setting: $e');
    }
  }

  /// Set color blind mode
  Future<void> setColorBlindMode(ColorBlindMode mode) async {
    _colorBlindMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_colorBlindModeKey, mode.index);
      
      // Announce change
      if (_screenReaderEnabled) {
        SemanticsService.announce(
          'Color blind mode: ${mode.displayName}',
          TextDirection.ltr,
        );
      }
      
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error saving color blind mode: $e');
    }
  }

  /// Toggle gesture navigation
  Future<void> toggleGestureNavigation() async {
    _gestureNavigationEnabled = !_gestureNavigationEnabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_gestureNavigationKey, _gestureNavigationEnabled);
      
      // Announce change
      if (_screenReaderEnabled) {
        SemanticsService.announce(
          'Gesture navigation ${_gestureNavigationEnabled ? 'enabled' : 'disabled'}',
          TextDirection.ltr,
        );
      }
      
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error saving gesture navigation setting: $e');
    }
  }

  /// Announce text for screen readers
  void announceText(String text, {TextDirection direction = TextDirection.ltr}) {
    if (_screenReaderEnabled) {
      SemanticsService.announce(text, direction);
    }
  }

  /// Get accessible theme data
  ThemeData getAccessibleThemeData(ThemeData baseTheme) {
    var theme = baseTheme;
    
    // Apply high contrast if enabled
    if (_highContrastEnabled) {
      theme = _applyHighContrast(theme);
    }
    
    // Apply color blind adjustments
    if (_colorBlindMode != ColorBlindMode.none) {
      theme = _applyColorBlindAdjustments(theme);
    }
    
    // Apply font scaling
    theme = theme.copyWith(
      textTheme: _scaleTextTheme(theme.textTheme, _fontScaleFactor),
      primaryTextTheme: _scaleTextTheme(theme.primaryTextTheme, _fontScaleFactor),
    );
    
    return theme;
  }

  ThemeData _applyHighContrast(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    if (isDark) {
      // Dark high contrast theme
      return theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          background: Colors.black,
          surface: const Color(0xFF111111),
          surfaceVariant: const Color(0xFF222222),
          primary: Colors.white,
          primaryContainer: const Color(0xFF333333),
          secondary: const Color(0xFFFFFFFF),
          secondaryContainer: const Color(0xFF444444),
          onBackground: Colors.white,
          onSurface: Colors.white,
          onSurfaceVariant: Colors.white,
          onPrimary: Colors.black,
          onPrimaryContainer: Colors.white,
          onSecondary: Colors.black,
          onSecondaryContainer: Colors.white,
          outline: Colors.white,
          outlineVariant: const Color(0xFF666666),
          error: const Color(0xFFFF6B6B),
          onError: Colors.black,
          tertiary: const Color(0xFFFFD700),
          onTertiary: Colors.black,
        ),
        // Enhanced contrast for cards
        cardTheme: CardThemeData(
          color: const Color(0xFF111111),
          shadowColor: Colors.white.withOpacity(0.3),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 1),
          ),
        ),
        // Enhanced contrast for app bar
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shadowColor: Colors.white.withOpacity(0.3),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Enhanced contrast for buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.white, width: 2),
            elevation: 4,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        // Enhanced contrast for input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222222),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        // Enhanced dividers
        dividerTheme: const DividerThemeData(
          color: Colors.white,
          thickness: 1,
        ),
      );
    } else {
      // Light high contrast theme
      return theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          background: Colors.white,
          surface: const Color(0xFFFAFAFA),
          surfaceVariant: const Color(0xFFF0F0F0),
          primary: Colors.black,
          primaryContainer: const Color(0xFFE0E0E0),
          secondary: const Color(0xFF000000),
          secondaryContainer: const Color(0xFFDDDDDD),
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Colors.black,
          onPrimary: Colors.white,
          onPrimaryContainer: Colors.black,
          onSecondary: Colors.white,
          onSecondaryContainer: Colors.black,
          outline: Colors.black,
          outlineVariant: const Color(0xFF666666),
          error: const Color(0xFFB71C1C),
          onError: Colors.white,
          tertiary: const Color(0xFF1565C0),
          onTertiary: Colors.white,
        ),
        // Enhanced contrast for cards
        cardTheme: CardThemeData(
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.3),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        // Enhanced contrast for app bar
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shadowColor: Colors.black.withOpacity(0.3),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Enhanced contrast for buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.black, width: 2),
            elevation: 4,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        // Enhanced contrast for input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(color: Colors.black),
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
        ),
        // Enhanced dividers
        dividerTheme: const DividerThemeData(
          color: Colors.black,
          thickness: 1,
        ),
      );
    }
  }

  ThemeData _applyColorBlindAdjustments(ThemeData theme) {
    // Implement color blind friendly adjustments
    switch (_colorBlindMode) {
      case ColorBlindMode.protanopia:
        return theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: Colors.blue[700],
            secondary: Colors.orange[700],
            error: Colors.orange[900],
          ),
        );
      case ColorBlindMode.deuteranopia:
        return theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: Colors.blue[600],
            secondary: Colors.yellow[700],
            error: Colors.red[900],
          ),
        );
      case ColorBlindMode.tritanopia:
        return theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: Colors.red[600],
            secondary: Colors.green[700],
            error: Colors.red[800],
          ),
        );
      case ColorBlindMode.none:
        return theme;
    }
  }

  TextTheme _scaleTextTheme(TextTheme textTheme, double scaleFactor) {
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontSize: (textTheme.displayLarge?.fontSize ?? 57) * scaleFactor),
      displayMedium: textTheme.displayMedium?.copyWith(fontSize: (textTheme.displayMedium?.fontSize ?? 45) * scaleFactor),
      displaySmall: textTheme.displaySmall?.copyWith(fontSize: (textTheme.displaySmall?.fontSize ?? 36) * scaleFactor),
      headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: (textTheme.headlineLarge?.fontSize ?? 32) * scaleFactor),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: (textTheme.headlineMedium?.fontSize ?? 28) * scaleFactor),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: (textTheme.headlineSmall?.fontSize ?? 24) * scaleFactor),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: (textTheme.titleLarge?.fontSize ?? 22) * scaleFactor),
      titleMedium: textTheme.titleMedium?.copyWith(fontSize: (textTheme.titleMedium?.fontSize ?? 16) * scaleFactor),
      titleSmall: textTheme.titleSmall?.copyWith(fontSize: (textTheme.titleSmall?.fontSize ?? 14) * scaleFactor),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: (textTheme.bodyLarge?.fontSize ?? 16) * scaleFactor),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: (textTheme.bodyMedium?.fontSize ?? 14) * scaleFactor),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: (textTheme.bodySmall?.fontSize ?? 12) * scaleFactor),
      labelLarge: textTheme.labelLarge?.copyWith(fontSize: (textTheme.labelLarge?.fontSize ?? 14) * scaleFactor),
      labelMedium: textTheme.labelMedium?.copyWith(fontSize: (textTheme.labelMedium?.fontSize ?? 12) * scaleFactor),
      labelSmall: textTheme.labelSmall?.copyWith(fontSize: (textTheme.labelSmall?.fontSize ?? 11) * scaleFactor),
    );
  }
}

enum ColorBlindMode {
  none('Normal Vision'),
  protanopia('Protanopia (Red-blind)'),
  deuteranopia('Deuteranopia (Green-blind)'),
  tritanopia('Tritanopia (Blue-blind)');

  const ColorBlindMode(this.displayName);
  final String displayName;
}