import 'package:flutter/material.dart';
import '../models/user_preferences_model.dart';
import '../services/personalization_service.dart';
import '../services/voice_multilingual_service.dart';
import '../screens/custom_theme_creation_screen.dart';
import '../screens/favorite_routes_screen.dart';
import '../screens/usage_analytics_dashboard_screen.dart';
import '../screens/personalized_recommendations_screen.dart';
import '../screens/weather_based_recommendations_screen.dart';

/// Comprehensive Personalization Settings Screen
class PersonalizationSettingsScreen extends StatefulWidget {
  @override
  _PersonalizationSettingsScreenState createState() => _PersonalizationSettingsScreenState();
}

class _PersonalizationSettingsScreenState extends State<PersonalizationSettingsScreen> {
  final PersonalizationService _personalizationService = PersonalizationService.instance;
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  
  UserPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _voiceService.initialize();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      _preferences = _personalizationService.currentPreferences;
      if (_preferences == null) {
        await _personalizationService.initialize();
        _preferences = _personalizationService.currentPreferences;
      }
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;
    
    setState(() => _isSaving = true);
    try {
      await _personalizationService.saveUserPreferences(_preferences!);
      await _voiceService.speak('Preferences saved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Colors.blue.shade600),
                SizedBox(width: 12),
                Text(
                  'Theme & Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Current Theme Display
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _preferences?.customTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _preferences?.customTheme.primaryColor.withOpacity(0.3) ?? Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _preferences?.customTheme.primaryColor ?? Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _preferences?.customTheme.themeName ?? 'Default Theme',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _preferences?.customTheme.isDarkMode == true ? 'Dark Mode' : 'Light Mode',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToThemeCreation(),
                    icon: Icon(Icons.edit),
                    label: Text('Edit Theme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showThemePresets(),
                    icon: Icon(Icons.color_lens),
                    label: Text('Presets'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteRoutesSection() {
    final routeCount = _preferences?.favoriteRoutes.length ?? 0;
    final quickAccessCount = _preferences?.favoriteRoutes
            .where((route) => route.isQuickAccess)
            .length ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red.shade600),
                SizedBox(width: 12),
                Text(
                  'Favorite Routes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatContainer(
                    'Total Routes',
                    routeCount.toString(),
                    Icons.route,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatContainer(
                    'Quick Access',
                    quickAccessCount.toString(),
                    Icons.flash_on,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () => _navigateToFavoriteRoutes(),
              icon: Icon(Icons.settings),
              label: Text('Manage Favorite Routes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationSettings() {
    if (_preferences == null) return Container();
    
    final settings = _preferences!.personalizationSettings;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.green.shade600),
                SizedBox(width: 12),
                Text(
                  'Personalization Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            SwitchListTile(
              title: Text('Enable Recommendations'),
              subtitle: Text('Get personalized travel suggestions'),
              value: settings.enableRecommendations,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    personalizationSettings: settings.copyWith(
                      enableRecommendations: value,
                    ),
                  );
                });
              },
            ),
            
            SwitchListTile(
              title: Text('Usage Analytics'),
              subtitle: Text('Track your travel patterns and expenses'),
              value: settings.enableAnalytics,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    personalizationSettings: settings.copyWith(
                      enableAnalytics: value,
                    ),
                  );
                });
              },
            ),
            
            SwitchListTile(
              title: Text('Quick Booking'),
              subtitle: Text('Enable one-tap booking for favorite routes'),
              value: settings.enableQuickBooking,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    personalizationSettings: settings.copyWith(
                      enableQuickBooking: value,
                    ),
                  );
                });
              },
            ),
            
            SwitchListTile(
              title: Text('Auto-Save Routes'),
              subtitle: Text('Automatically save frequently used routes'),
              value: settings.autoSaveRoutes,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    personalizationSettings: settings.copyWith(
                      autoSaveRoutes: value,
                    ),
                  );
                });
              },
            ),
            
            SwitchListTile(
              title: Text('Voice Assistance'),
              subtitle: Text('Enable voice guidance and commands'),
              value: settings.enableVoiceAssistance,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    personalizationSettings: settings.copyWith(
                      enableVoiceAssistance: value,
                    ),
                  );
                });
              },
            ),
            
            ListTile(
              title: Text('Max Favorite Routes'),
              subtitle: Text('Maximum number of routes to save'),
              trailing: DropdownButton<int>(
                value: settings.maxFavoriteRoutes,
                items: [5, 10, 15, 20]
                    .map((count) => DropdownMenuItem(
                          value: count,
                          child: Text(count.toString()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        personalizationSettings: settings.copyWith(
                          maxFavoriteRoutes: value,
                        ),
                      );
                    });
                  }
                },
              ),
            ),
            
            ListTile(
              title: Text('Preferred Language'),
              subtitle: Text('Default language for voice assistance'),
              trailing: DropdownButton<String>(
                value: settings.preferredLanguage,
                items: [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                  DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        personalizationSettings: settings.copyWith(
                          preferredLanguage: value,
                        ),
                      );
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.purple.shade600),
                SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildQuickActionCard(
                  'Weather Routes',
                  Icons.wb_sunny,
                  Colors.orange,
                  () => _navigateToWeatherRecommendations(),
                ),
                _buildQuickActionCard(
                  'Analytics',
                  Icons.analytics,
                  Colors.blue,
                  () => _navigateToAnalytics(),
                ),
                _buildQuickActionCard(
                  'Recommendations',
                  Icons.recommend,
                  Colors.green,
                  () => _navigateToRecommendations(),
                ),
                _buildQuickActionCard(
                  'Reset Settings',
                  Icons.restore,
                  Colors.red,
                  () => _resetToDefaults(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatContainer(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToThemeCreation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomThemeCreationScreen(
          initialTheme: _preferences?.customTheme,
        ),
      ),
    );

    if (result is CustomTheme) {
      setState(() {
        _preferences = _preferences?.copyWith(customTheme: result);
      });
    }
  }

  Future<void> _showThemePresets() async {
    final presets = [
      CustomTheme.defaultTheme,
      CustomTheme.darkTheme,
      CustomTheme.greenTheme,
    ];

    final selectedTheme = await showDialog<CustomTheme>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Theme Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: presets.map((theme) {
            return ListTile(
              leading: CircleAvatar(backgroundColor: theme.primaryColor),
              title: Text(theme.themeName),
              subtitle: Text(theme.isDarkMode ? 'Dark Mode' : 'Light Mode'),
              onTap: () => Navigator.of(context).pop(theme),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedTheme != null) {
      await _personalizationService.updateTheme(selectedTheme);
      setState(() {
        _preferences = _preferences?.copyWith(customTheme: selectedTheme);
      });
    }
  }

  void _navigateToFavoriteRoutes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FavoriteRoutesScreen()),
    );
  }

  void _navigateToAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => UsageAnalyticsDashboardScreen()),
    );
  }

  void _navigateToRecommendations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PersonalizedRecommendationsScreen()),
    );
  }

  void _navigateToWeatherRecommendations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => WeatherBasedRecommendationsScreen()),
    );
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset to Defaults'),
        content: Text(
          'This will reset all personalization settings to default values. '
          'Your favorite routes and themes will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _personalizationService.resetToDefaults();
      await _voiceService.speak('Settings reset to defaults');
      await _loadPreferences();
    }
  }

  Future<void> _exportUserData() async {
    await _voiceService.speak('Export feature coming soon');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personalization'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _voiceService.speak('Personalization settings'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildThemeSection(),
                  SizedBox(height: 16),
                  _buildFavoriteRoutesSection(),
                  SizedBox(height: 16),
                  _buildPersonalizationSettings(),
                  SizedBox(height: 16),
                  _buildQuickActionsSection(),
                  SizedBox(height: 100), // Space for save button
                ],
              ),
            ),
      floatingActionButton: _preferences != null
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _savePreferences,
              icon: _isSaving 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}