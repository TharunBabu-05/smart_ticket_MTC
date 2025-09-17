import 'package:flutter/material.dart';

/// User Preferences Model for Personalization
class UserPreferences {
  final String userId;
  final CustomTheme customTheme;
  final List<FavoriteRoute> favoriteRoutes;
  final PersonalizationSettings personalizationSettings;
  final DateTime lastUpdated;

  const UserPreferences({
    required this.userId,
    required this.customTheme,
    required this.favoriteRoutes,
    required this.personalizationSettings,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'customTheme': customTheme.toJson(),
      'favoriteRoutes': favoriteRoutes.map((route) => route.toJson()).toList(),
      'personalizationSettings': personalizationSettings.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] ?? '',
      customTheme: CustomTheme.fromJson(json['customTheme'] ?? {}),
      favoriteRoutes: (json['favoriteRoutes'] as List<dynamic>? ?? [])
          .map((route) => FavoriteRoute.fromJson(route))
          .toList(),
      personalizationSettings: PersonalizationSettings.fromJson(
          json['personalizationSettings'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  UserPreferences copyWith({
    String? userId,
    CustomTheme? customTheme,
    List<FavoriteRoute>? favoriteRoutes,
    PersonalizationSettings? personalizationSettings,
    DateTime? lastUpdated,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      customTheme: customTheme ?? this.customTheme,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      personalizationSettings: personalizationSettings ?? this.personalizationSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Custom Theme Model
class CustomTheme {
  final String themeName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color cardColor;
  final bool isDarkMode;
  final DateTime createdAt;

  const CustomTheme({
    required this.themeName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.cardColor,
    required this.isDarkMode,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'themeName': themeName,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'backgroundColor': backgroundColor.value,
      'surfaceColor': surfaceColor.value,
      'textColor': textColor.value,
      'cardColor': cardColor.value,
      'isDarkMode': isDarkMode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomTheme.fromJson(Map<String, dynamic> json) {
    return CustomTheme(
      themeName: json['themeName'] ?? 'Default Theme',
      primaryColor: Color(json['primaryColor'] ?? Colors.blue.value),
      secondaryColor: Color(json['secondaryColor'] ?? Colors.blueAccent.value),
      backgroundColor: Color(json['backgroundColor'] ?? Colors.white.value),
      surfaceColor: Color(json['surfaceColor'] ?? Colors.grey.shade100.value),
      textColor: Color(json['textColor'] ?? Colors.black.value),
      cardColor: Color(json['cardColor'] ?? Colors.white.value),
      isDarkMode: json['isDarkMode'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to Flutter ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        onPrimary: isDarkMode ? Colors.white : Colors.black,
        onSecondary: isDarkMode ? Colors.white : Colors.black,
        onBackground: textColor,
        onSurface: textColor,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  CustomTheme copyWith({
    String? themeName,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textColor,
    Color? cardColor,
    bool? isDarkMode,
    DateTime? createdAt,
  }) {
    return CustomTheme(
      themeName: themeName ?? this.themeName,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      cardColor: cardColor ?? this.cardColor,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Predefined themes
  static CustomTheme get defaultTheme => CustomTheme(
    themeName: 'Smart Ticket Blue',
    primaryColor: Colors.blue,
    secondaryColor: Colors.blueAccent,
    backgroundColor: Colors.white,
    surfaceColor: Colors.grey.shade100,
    textColor: Colors.black87,
    cardColor: Colors.white,
    isDarkMode: false,
    createdAt: DateTime.now(),
  );

  static CustomTheme get darkTheme => CustomTheme(
    themeName: 'Dark Mode',
    primaryColor: Colors.blueGrey,
    secondaryColor: Colors.cyan,
    backgroundColor: Colors.grey.shade900,
    surfaceColor: Colors.grey.shade800,
    textColor: Colors.white,
    cardColor: Colors.grey.shade800,
    isDarkMode: true,
    createdAt: DateTime.now(),
  );

  static CustomTheme get greenTheme => CustomTheme(
    themeName: 'Nature Green',
    primaryColor: Colors.green,
    secondaryColor: Colors.lightGreen,
    backgroundColor: Colors.white,
    surfaceColor: Colors.green.shade50,
    textColor: Colors.black87,
    cardColor: Colors.white,
    isDarkMode: false,
    createdAt: DateTime.now(),
  );
}

/// Favorite Route Model
class FavoriteRoute {
  final String id;
  final String routeName;
  final String sourceStation;
  final String destinationStation;
  final double estimatedFare;
  final int usageCount;
  final DateTime lastUsed;
  final DateTime createdAt;
  final bool isQuickAccess;

  const FavoriteRoute({
    required this.id,
    required this.routeName,
    required this.sourceStation,
    required this.destinationStation,
    required this.estimatedFare,
    required this.usageCount,
    required this.lastUsed,
    required this.createdAt,
    required this.isQuickAccess,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeName': routeName,
      'sourceStation': sourceStation,
      'destinationStation': destinationStation,
      'estimatedFare': estimatedFare,
      'usageCount': usageCount,
      'lastUsed': lastUsed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isQuickAccess': isQuickAccess,
    };
  }

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      id: json['id'] ?? '',
      routeName: json['routeName'] ?? '',
      sourceStation: json['sourceStation'] ?? '',
      destinationStation: json['destinationStation'] ?? '',
      estimatedFare: (json['estimatedFare'] ?? 0.0).toDouble(),
      usageCount: json['usageCount'] ?? 0,
      lastUsed: DateTime.parse(json['lastUsed'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isQuickAccess: json['isQuickAccess'] ?? false,
    );
  }

  FavoriteRoute copyWith({
    String? id,
    String? routeName,
    String? sourceStation,
    String? destinationStation,
    double? estimatedFare,
    int? usageCount,
    DateTime? lastUsed,
    DateTime? createdAt,
    bool? isQuickAccess,
  }) {
    return FavoriteRoute(
      id: id ?? this.id,
      routeName: routeName ?? this.routeName,
      sourceStation: sourceStation ?? this.sourceStation,
      destinationStation: destinationStation ?? this.destinationStation,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
      isQuickAccess: isQuickAccess ?? this.isQuickAccess,
    );
  }
}

/// Personalization Settings Model
class PersonalizationSettings {
  final bool enableRecommendations;
  final bool enableAnalytics;
  final bool enableQuickBooking;
  final String preferredLanguage;
  final bool enableVoiceAssistance;
  final bool enableNotifications;
  final int maxFavoriteRoutes;
  final bool autoSaveRoutes;

  const PersonalizationSettings({
    required this.enableRecommendations,
    required this.enableAnalytics,
    required this.enableQuickBooking,
    required this.preferredLanguage,
    required this.enableVoiceAssistance,
    required this.enableNotifications,
    required this.maxFavoriteRoutes,
    required this.autoSaveRoutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableRecommendations': enableRecommendations,
      'enableAnalytics': enableAnalytics,
      'enableQuickBooking': enableQuickBooking,
      'preferredLanguage': preferredLanguage,
      'enableVoiceAssistance': enableVoiceAssistance,
      'enableNotifications': enableNotifications,
      'maxFavoriteRoutes': maxFavoriteRoutes,
      'autoSaveRoutes': autoSaveRoutes,
    };
  }

  factory PersonalizationSettings.fromJson(Map<String, dynamic> json) {
    return PersonalizationSettings(
      enableRecommendations: json['enableRecommendations'] ?? true,
      enableAnalytics: json['enableAnalytics'] ?? true,
      enableQuickBooking: json['enableQuickBooking'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      enableVoiceAssistance: json['enableVoiceAssistance'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      maxFavoriteRoutes: json['maxFavoriteRoutes'] ?? 10,
      autoSaveRoutes: json['autoSaveRoutes'] ?? true,
    );
  }

  PersonalizationSettings copyWith({
    bool? enableRecommendations,
    bool? enableAnalytics,
    bool? enableQuickBooking,
    String? preferredLanguage,
    bool? enableVoiceAssistance,
    bool? enableNotifications,
    int? maxFavoriteRoutes,
    bool? autoSaveRoutes,
  }) {
    return PersonalizationSettings(
      enableRecommendations: enableRecommendations ?? this.enableRecommendations,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableQuickBooking: enableQuickBooking ?? this.enableQuickBooking,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      enableVoiceAssistance: enableVoiceAssistance ?? this.enableVoiceAssistance,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      maxFavoriteRoutes: maxFavoriteRoutes ?? this.maxFavoriteRoutes,
      autoSaveRoutes: autoSaveRoutes ?? this.autoSaveRoutes,
    );
  }

  /// Default settings
  static PersonalizationSettings get defaultSettings => PersonalizationSettings(
    enableRecommendations: true,
    enableAnalytics: true,
    enableQuickBooking: true,
    preferredLanguage: 'en',
    enableVoiceAssistance: true,
    enableNotifications: true,
    maxFavoriteRoutes: 10,
    autoSaveRoutes: true,
  );
}