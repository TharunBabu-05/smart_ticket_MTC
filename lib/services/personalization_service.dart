import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_preferences_model.dart';
import '../models/enhanced_ticket_model.dart';

/// Personalization Service for managing user preferences, themes, and customization
class PersonalizationService {
  static const String _prefsKey = 'user_preferences';
  static const String _currentThemeKey = 'current_theme';
  static PersonalizationService? _instance;
  
  PersonalizationService._internal();
  
  static PersonalizationService get instance {
    _instance ??= PersonalizationService._internal();
    return _instance!;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserPreferences? _currentPreferences;
  CustomTheme? _currentTheme;

  /// Initialize personalization service
  Future<void> initialize() async {
    await _loadUserPreferences();
    await _loadCurrentTheme();
  }

  /// Get current user preferences
  UserPreferences? get currentPreferences => _currentPreferences;
  CustomTheme? get currentTheme => _currentTheme;

  /// Load user preferences from local storage and Firebase
  Future<void> _loadUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Try loading from Firebase first
      try {
        final doc = await _firestore
            .collection('user_preferences')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          _currentPreferences = UserPreferences.fromJson(doc.data()!);
          await _savePreferencesLocally(_currentPreferences!);
          return;
        }
      } catch (e) {
        print('📱 Could not load preferences from Firebase: $e');
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_prefsKey);
      
      if (prefsJson != null) {
        _currentPreferences = UserPreferences.fromJson(jsonDecode(prefsJson));
      } else {
        // Create default preferences
        _currentPreferences = UserPreferences(
          userId: user.uid,
          customTheme: CustomTheme.defaultTheme,
          favoriteRoutes: [],
          personalizationSettings: PersonalizationSettings.defaultSettings,
          lastUpdated: DateTime.now(),
        );
        await saveUserPreferences(_currentPreferences!);
      }
    } catch (e) {
      print('❌ Error loading user preferences: $e');
    }
  }

  /// Load current theme
  Future<void> _loadCurrentTheme() async {
    try {
      if (_currentPreferences != null) {
        _currentTheme = _currentPreferences!.customTheme;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final themeJson = prefs.getString(_currentThemeKey);
      
      if (themeJson != null) {
        _currentTheme = CustomTheme.fromJson(jsonDecode(themeJson));
      } else {
        _currentTheme = CustomTheme.defaultTheme;
      }
    } catch (e) {
      print('❌ Error loading current theme: $e');
      _currentTheme = CustomTheme.defaultTheme;
    }
  }

  /// Save user preferences to both local and Firebase
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      _currentPreferences = preferences.copyWith(lastUpdated: DateTime.now());
      
      // Save locally first
      await _savePreferencesLocally(_currentPreferences!);
      
      // Save to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('user_preferences')
            .doc(user.uid)
            .set(_currentPreferences!.toJson());
      }
    } catch (e) {
      print('❌ Error saving user preferences: $e');
    }
  }

  /// Save preferences locally
  Future<void> _savePreferencesLocally(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(preferences.toJson()));
    } catch (e) {
      print('❌ Error saving preferences locally: $e');
    }
  }

  /// Update current theme
  Future<void> updateTheme(CustomTheme theme) async {
    try {
      _currentTheme = theme;
      
      // Save theme locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentThemeKey, jsonEncode(theme.toJson()));
      
      // Update user preferences if available
      if (_currentPreferences != null) {
        await saveUserPreferences(_currentPreferences!.copyWith(customTheme: theme));
      }
    } catch (e) {
      print('❌ Error updating theme: $e');
    }
  }

  /// Add favorite route
  Future<void> addFavoriteRoute(FavoriteRoute route) async {
    if (_currentPreferences == null) return;

    try {
      final updatedRoutes = List<FavoriteRoute>.from(_currentPreferences!.favoriteRoutes);
      
      // Check if route already exists
      final existingIndex = updatedRoutes.indexWhere(
        (r) => r.sourceStation == route.sourceStation && 
               r.destinationStation == route.destinationStation,
      );
      
      if (existingIndex != -1) {
        // Update existing route
        updatedRoutes[existingIndex] = updatedRoutes[existingIndex].copyWith(
          usageCount: updatedRoutes[existingIndex].usageCount + 1,
          lastUsed: DateTime.now(),
        );
      } else {
        // Add new route (respect max limit)
        if (updatedRoutes.length >= _currentPreferences!.personalizationSettings.maxFavoriteRoutes) {
          // Remove least recently used route
          updatedRoutes.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
          updatedRoutes.removeAt(0);
        }
        updatedRoutes.add(route);
      }
      
      final updatedPreferences = _currentPreferences!.copyWith(favoriteRoutes: updatedRoutes);
      await saveUserPreferences(updatedPreferences);
    } catch (e) {
      print('❌ Error adding favorite route: $e');
    }
  }

  /// Remove favorite route
  Future<void> removeFavoriteRoute(String routeId) async {
    if (_currentPreferences == null) return;

    try {
      final updatedRoutes = _currentPreferences!.favoriteRoutes
          .where((route) => route.id != routeId)
          .toList();
      
      final updatedPreferences = _currentPreferences!.copyWith(favoriteRoutes: updatedRoutes);
      await saveUserPreferences(updatedPreferences);
    } catch (e) {
      print('❌ Error removing favorite route: $e');
    }
  }

  /// Update personalization settings
  Future<void> updatePersonalizationSettings(PersonalizationSettings settings) async {
    if (_currentPreferences == null) return;

    try {
      final updatedPreferences = _currentPreferences!.copyWith(personalizationSettings: settings);
      await saveUserPreferences(updatedPreferences);
    } catch (e) {
      print('❌ Error updating personalization settings: $e');
    }
  }

  /// Get favorite routes sorted by usage
  List<FavoriteRoute> getFavoriteRoutes({bool sortByUsage = true}) {
    if (_currentPreferences == null) return [];

    final routes = List<FavoriteRoute>.from(_currentPreferences!.favoriteRoutes);
    
    if (sortByUsage) {
      routes.sort((a, b) {
        // Sort by usage count (descending) then by last used (descending)
        if (a.usageCount != b.usageCount) {
          return b.usageCount.compareTo(a.usageCount);
        }
        return b.lastUsed.compareTo(a.lastUsed);
      });
    }
    
    return routes;
  }

  /// Get quick access routes
  List<FavoriteRoute> getQuickAccessRoutes() {
    return getFavoriteRoutes()
        .where((route) => route.isQuickAccess)
        .take(5)
        .toList();
  }

  /// Auto-save route from ticket booking
  Future<void> autoSaveRouteFromTicket(EnhancedTicket ticket) async {
    if (_currentPreferences?.personalizationSettings.autoSaveRoutes != true) return;

    try {
      final route = FavoriteRoute(
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
        routeName: '${ticket.sourceName} → ${ticket.destinationName}',
        sourceStation: ticket.sourceName,
        destinationStation: ticket.destinationName,
        estimatedFare: ticket.fare,
        usageCount: 1,
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
        isQuickAccess: false,
      );
      
      await addFavoriteRoute(route);
    } catch (e) {
      print('❌ Error auto-saving route: $e');
    }
  }

  /// Get travel recommendations based on user history
  List<TravelRecommendation> getTravelRecommendations() {
    if (_currentPreferences?.personalizationSettings.enableRecommendations != true) {
      return [];
    }

    final recommendations = <TravelRecommendation>[];
    final favoriteRoutes = getFavoriteRoutes();

    // Recommend frequent routes
    for (final route in favoriteRoutes.take(3)) {
      recommendations.add(TravelRecommendation(
        title: 'Frequent Route',
        description: 'Book your usual route: ${route.routeName}',
        route: route,
        type: RecommendationType.frequentRoute,
        confidence: 0.9,
      ));
    }

    // Time-based recommendations
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 7 && hour <= 10) {
      recommendations.add(TravelRecommendation(
        title: 'Morning Commute',
        description: 'Start your day with a smooth journey',
        route: null,
        type: RecommendationType.timeBasedSuggestion,
        confidence: 0.7,
      ));
    } else if (hour >= 17 && hour <= 20) {
      recommendations.add(TravelRecommendation(
        title: 'Evening Return',
        description: 'Time to head home?',
        route: null,
        type: RecommendationType.timeBasedSuggestion,
        confidence: 0.7,
      ));
    }

    return recommendations.take(5).toList();
  }

  /// Reset preferences to default
  Future<void> resetToDefaults() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentPreferences = UserPreferences(
        userId: user.uid,
        customTheme: CustomTheme.defaultTheme,
        favoriteRoutes: [],
        personalizationSettings: PersonalizationSettings.defaultSettings,
        lastUpdated: DateTime.now(),
      );

      await saveUserPreferences(_currentPreferences!);
      await updateTheme(CustomTheme.defaultTheme);
    } catch (e) {
      print('❌ Error resetting preferences: $e');
    }
  }
}

/// Travel Recommendation Model
class TravelRecommendation {
  final String title;
  final String description;
  final FavoriteRoute? route;
  final RecommendationType type;
  final double confidence;

  const TravelRecommendation({
    required this.title,
    required this.description,
    this.route,
    required this.type,
    required this.confidence,
  });
}

/// Recommendation Types
enum RecommendationType {
  frequentRoute,
  timeBasedSuggestion,
  locationBasedSuggestion,
  costOptimization,
  newRoute,
}