import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/accessibility_service.dart';
import '../services/enhanced_auth_service.dart';
import '../services/performance_service.dart';
import '../services/offline_storage_service.dart';
import 'accessibility_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with PerformanceMonitoringMixin {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  int _securityScore = 0;
  Map<String, int> _storageStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = EnhancedAuthService.currentUser;
      if (user != null) {
        final biometricEnabled = await EnhancedAuthService.isBiometricEnabled(user.uid);
        final securityScore = await EnhancedAuthService.getUserSecurityScore();
        final storageStats = await OfflineStorageService.getStorageStats();
        
        setState(() {
          _biometricEnabled = biometricEnabled;
          _securityScore = securityScore;
          _storageStats = storageStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      recordPerformanceMetric(PerformanceMetric.errorCount, 1.0, 
          metadata: {'error_type': 'settings_load_error', 'error': e.toString()});
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Appearance', Icons.palette),
                  _buildAppearanceSection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Accessibility', Icons.accessibility),
                  _buildAccessibilitySection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Security', Icons.security),
                  _buildSecuritySection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Notifications', Icons.notifications),
                  _buildNotificationsSection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Privacy', Icons.privacy_tip),
                  _buildPrivacySection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Storage', Icons.storage),
                  _buildStorageSection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Enhanced Features', Icons.new_releases),
                  _buildEnhancedFeaturesSection(),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('About', Icons.info),
                  _buildAboutSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Theme'),
                subtitle: Text(themeService.getThemeModeDisplayName(themeService.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(themeService),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Accent Color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeService.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                onTap: () => _showColorDialog(themeService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessibilitySection() {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.accessibility),
                title: const Text('Accessibility Settings'),
                subtitle: Text(accessibilityService.screenReaderEnabled 
                  ? 'Screen reader active' 
                  : 'Configure accessibility options'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccessibilitySettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.contrast),
                title: const Text('High Contrast'),
                subtitle: const Text('Improve visibility with high contrast'),
                value: accessibilityService.highContrastEnabled,
                onChanged: (_) => accessibilityService.toggleHighContrast(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('Font Size'),
                subtitle: Text('${(accessibilityService.fontScaleFactor * 100).round()}% of normal size'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: accessibilityService.fontScaleFactor > 0.8
                        ? () => accessibilityService.setFontScaleFactor(
                            (accessibilityService.fontScaleFactor - 0.1).clamp(0.8, 2.0))
                        : null,
                      tooltip: 'Decrease font size',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: accessibilityService.fontScaleFactor < 2.0
                        ? () => accessibilityService.setFontScaleFactor(
                            (accessibilityService.fontScaleFactor + 0.1).clamp(0.8, 2.0))
                        : null,
                      tooltip: 'Increase font size',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: Text(_biometricEnabled ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.security,
              color: _getSecurityScoreColor(),
            ),
            title: const Text('Security Score'),
            subtitle: Text('$_securityScore/100 - ${_getSecurityScoreText()}'),
            trailing: CircularProgressIndicator(
              value: _securityScore / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getSecurityScoreColor()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive trip updates and alerts'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('Location Services'),
            subtitle: const Text('Required for trip tracking'),
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Data Usage'),
            subtitle: const Text('Manage data collection preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to data usage settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Offline Storage'),
            subtitle: Text('${_storageStats['offline_tickets'] ?? 0} tickets cached'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Status'),
            subtitle: Text('${_storageStats['pending_sync'] ?? 0} items pending'),
            trailing: _storageStats['pending_sync'] != null && _storageStats['pending_sync']! > 0
                ? const Icon(Icons.sync_problem, color: Colors.orange)
                : const Icon(Icons.sync, color: Colors.green),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showClearCacheDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFeaturesSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Enhanced Tickets'),
            subtitle: const Text('2-hour validation with fraud detection'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: const Text('Cross-Platform Sync'),
            subtitle: const Text('Real-time data sharing with gyro comparator'),
            trailing: _storageStats['cross_platform_sessions'] != null 
                ? Text('${_storageStats['cross_platform_sessions']} sessions')
                : const Text('Ready'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Fraud Detection'),
            subtitle: const Text('AI-powered violation detection'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Penalty System'),
            subtitle: const Text('Automatic fare violation penalties'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPenaltyInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0+1'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/support');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to terms of service
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(themeService.getThemeModeDisplayName(mode)),
              value: mode,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showColorDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: ThemeService.accentColors.length,
            itemBuilder: (context, index) {
              final color = ThemeService.accentColors[index];
              final isSelected = color == themeService.accentColor;
              
              return GestureDetector(
                onTap: () {
                  themeService.setAccentColor(color);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final user = EnhancedAuthService.currentUser;
      if (user != null) {
        final success = await EnhancedAuthService.enableBiometricAuth(user.uid);
        setState(() {
          _biometricEnabled = success;
        });
        
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to enable biometric authentication'),
            ),
          );
        }
      }
    } else {
      setState(() {
        _biometricEnabled = false;
      });
    }
  }

  void _showChangePasswordDialog() {
    // Implementation for change password dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await EnhancedAuthService.deleteAccount();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/auth',
                    (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete account: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached data including offline tickets. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await OfflineStorageService.cleanupOldData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
                _loadSettings(); // Refresh storage stats
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear cache: $e')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showPenaltyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Penalty System'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How penalties work:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('• Tickets are valid for 2 hours with location tracking'),
            const SizedBox(height: 8),
            Text('• Traveling beyond paid destination incurs penalties'),
            const SizedBox(height: 8),
            Text('• ₹5 penalty per extra stop traveled'),
            const SizedBox(height: 8),
            Text('• AI analyzes GPS and sensor data for violations'),
            const SizedBox(height: 8),
            Text('• Cross-platform verification with bus systems'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep location services ON during your journey to avoid false penalties',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getSecurityScoreColor() {
    if (_securityScore >= 80) return Colors.green;
    if (_securityScore >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getSecurityScoreText() {
    if (_securityScore >= 80) return 'Excellent';
    if (_securityScore >= 60) return 'Good';
    if (_securityScore >= 40) return 'Fair';
    return 'Poor';
  }
}