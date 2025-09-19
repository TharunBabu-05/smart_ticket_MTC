import 'package:flutter/material.dart';

class AppTheme {
  // Get the background gradient based on theme
  static BoxDecoration getBackgroundDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark ? [
          // Dark theme: Black to dark blue
          const Color(0xFF000000), // Black
          const Color(0xFF0D1421), // Very dark blue
          const Color(0xFF1A1F2E), // Dark blue
          const Color(0xFF1E3A8A), // Deep blue
        ] : [
          // Light theme: White to light blue
          const Color(0xFFFFFFFF), // Pure white
          const Color(0xFFF8FAFF), // Very light blue tint
          const Color(0xFFE3F2FD), // Light blue
          const Color(0xFFBBDEFB), // Lighter blue
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  // Get primary text color based on theme
  static Color getPrimaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }

  // Get secondary text color based on theme
  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : Colors.black54;
  }

  // Get tertiary text color based on theme
  static Color getTertiaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white60 : Colors.black45;
  }

  // Get card background for glassmorphism effect
  static Color getCardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
  }

  // Get card border color
  static Color getCardBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.1);
  }

  // Get shadow color for cards
  static Color getShadowColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
  }

  // Create themed AppBar
  static AppBar createThemedAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: getPrimaryTextColor(context),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      iconTheme: IconThemeData(
        color: getPrimaryTextColor(context),
      ),
      actions: actions,
      leading: leading,
      flexibleSpace: Container(
        decoration: getBackgroundDecoration(context),
      ),
    );
  }

  // Create themed card decoration
  static BoxDecoration createCardDecoration(BuildContext context, {Color? customColor}) {
    return BoxDecoration(
      color: customColor ?? getCardBackground(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: getCardBorderColor(context),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: getShadowColor(context),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Text styles for consistency
  static TextStyle get titleLarge => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// Base themed scaffold that all screens can extend
class ThemedScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final Widget? leading;

  const ThemedScaffold({
    Key? key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title != null 
          ? AppTheme.createThemedAppBar(
              context: context,
              title: title!,
              actions: actions,
              leading: leading,
            )
          : null,
      body: Container(
        decoration: AppTheme.getBackgroundDecoration(context),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}