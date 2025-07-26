import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _accentColorKey = 'app_accent_color';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  Color _accentColor = const Color(0xFF1DB584);
  
  AppThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  
  /// Initialize theme service
  static Future<ThemeService> initialize() async {
    final service = ThemeService();
    await service._loadThemePreferences();
    return service;
  }
  
  /// Load theme preferences from storage
  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final String? themeModeString = prefs.getString(_themeKey);
      if (themeModeString != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => AppThemeMode.system,
        );
      }
      
      // Load accent color
      final int? colorValue = prefs.getInt(_accentColorKey);
      if (colorValue != null) {
        _accentColor = Color(colorValue);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading theme preferences: $e');
    }
  }
  
  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  /// Set accent color
  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;
    
    _accentColor = color;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, color.value);
    } catch (e) {
      print('Error saving accent color: $e');
    }
  }
  
  /// Get current theme data based on brightness
  ThemeData getThemeData(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: _getColorScheme(isDark),
      appBarTheme: _getAppBarTheme(isDark),
      elevatedButtonTheme: _getElevatedButtonTheme(isDark),
      outlinedButtonTheme: _getOutlinedButtonTheme(isDark),
      textButtonTheme: _getTextButtonTheme(isDark),
      cardTheme: _getCardTheme(isDark),
      bottomNavigationBarTheme: _getBottomNavigationBarTheme(isDark),
      floatingActionButtonTheme: _getFloatingActionButtonTheme(isDark),
      inputDecorationTheme: _getInputDecorationTheme(isDark),
      dividerTheme: _getDividerTheme(isDark),
      chipTheme: _getChipTheme(isDark),
      snackBarTheme: _getSnackBarTheme(isDark),
      dialogTheme: _getDialogTheme(isDark),
      textTheme: _getTextTheme(isDark),
    );
  }
  
  /// Get color scheme
  ColorScheme _getColorScheme(bool isDark) {
    if (isDark) {
      return ColorScheme.dark(
        primary: _accentColor,
        secondary: _accentColor.withOpacity(0.8),
        surface: const Color(0xFF121212),
        background: const Color(0xFF000000),
        error: const Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.black,
      );
    } else {
      return ColorScheme.light(
        primary: _accentColor,
        secondary: _accentColor.withOpacity(0.8),
        surface: Colors.white,
        background: const Color(0xFFF5F5F5),
        error: const Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      );
    }
  }
  
  /// Get app bar theme
  AppBarTheme _getAppBarTheme(bool isDark) {
    return AppBarTheme(
      backgroundColor: _accentColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: _accentColor.withOpacity(0.8),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
  
  /// Get elevated button theme
  ElevatedButtonThemeData _getElevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Get outlined button theme
  OutlinedButtonThemeData _getOutlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _accentColor,
        side: BorderSide(color: _accentColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Get text button theme
  TextButtonThemeData _getTextButtonTheme(bool isDark) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Get card theme
  CardThemeData _getCardTheme(bool isDark) {
    return CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.5)
          : Colors.grey.withOpacity(0.2),
    );
  }
  
  /// Get bottom navigation bar theme
  BottomNavigationBarThemeData _getBottomNavigationBarTheme(bool isDark) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      selectedItemColor: _accentColor,
      unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    );
  }
  
  /// Get floating action button theme
  FloatingActionButtonThemeData _getFloatingActionButtonTheme(bool isDark) {
    return FloatingActionButtonThemeData(
      backgroundColor: _accentColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
  
  /// Get input decoration theme
  InputDecorationTheme _getInputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: isDark 
          ? Colors.grey[800]!.withOpacity(0.3)
          : Colors.grey[50],
    );
  }
  
  /// Get divider theme
  DividerThemeData _getDividerTheme(bool isDark) {
    return DividerThemeData(
      color: isDark ? Colors.grey[700] : Colors.grey[300],
      thickness: 1,
      space: 1,
    );
  }
  
  /// Get chip theme
  ChipThemeData _getChipTheme(bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      selectedColor: _accentColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
  
  /// Get snack bar theme
  SnackBarThemeData _getSnackBarTheme(bool isDark) {
    return SnackBarThemeData(
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[900],
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }
  
  /// Get dialog theme
  DialogThemeData _getDialogTheme(bool isDark) {
    return DialogThemeData(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
    );
  }
  
  /// Get text theme
  TextTheme _getTextTheme(bool isDark) {
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtitleColor = isDark ? Colors.grey[300]! : Colors.grey[600]!;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: subtitleColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: subtitleColor,
      ),
    );
  }
  
  /// Predefined accent colors
  static const List<Color> accentColors = [
    Color(0xFF1DB584), // Default green
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFF009688), // Teal
    Color(0xFFE91E63), // Pink
  ];
  
  /// Get theme mode display name
  String getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}