import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_widgets.dart';
import '../widgets/high_contrast_widgets.dart';
import '../widgets/font_size_widgets.dart';
import '../widgets/color_blind_widgets.dart';
import '../widgets/gesture_navigation_widgets.dart';
import 'high_contrast_demo_screen.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Accessibility Settings'),
            leading: AccessibleIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Back to settings',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ScreenReaderAnnouncer(
            message: 'Accessibility settings screen opened',
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Screen Reader Status
                _buildStatusCard(accessibilityService),
                const SizedBox(height: 16),
                
                // Visual Accessibility
                _buildVisualAccessibilitySection(accessibilityService),
                const SizedBox(height: 16),
                
                // Text & Font Settings
                _buildTextSettingsSection(accessibilityService),
                const SizedBox(height: 16),
                
                // Color Settings
                _buildColorSettingsSection(accessibilityService),
                const SizedBox(height: 16),
                
                // Navigation Settings
                _buildNavigationSettingsSection(accessibilityService),
                const SizedBox(height: 16),
                
                // Quick Actions
                _buildQuickActionsSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(AccessibilityService service) {
    return AccessibleCard(
      semanticLabel: 'Accessibility status information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.accessibility,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accessibility Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      service.screenReaderEnabled 
                        ? 'Screen reader is active'
                        : 'Screen reader not detected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: service.screenReaderEnabled 
                          ? Colors.green 
                          : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (service.screenReaderEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Screen reader detected. All accessibility features are optimized.',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualAccessibilitySection(AccessibilityService service) {
    return AccessibleCard(
      semanticLabel: 'Visual accessibility settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual Accessibility',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // High Contrast Toggle
          AccessibleSwitch(
            value: service.highContrastEnabled,
            onChanged: (_) => service.toggleHighContrast(),
            label: 'High Contrast Mode',
            semanticLabel: 'High contrast mode toggle',
          ),
          
          const SizedBox(height: 16),
          
          // Preview of current contrast
          const HighContrastPreview(),
          
          const SizedBox(height: 16),
          
          // Demo navigation button
          AccessibleTextButton(
            text: 'View High Contrast Demo',
            semanticLabel: 'Open high contrast demonstration screen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HighContrastDemoScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextSettingsSection(AccessibilityService service) {
    return Column(
      children: [
        // Font Size Adjustment Widget
        const FontSizeAdjustmentWidget(),
        
        const SizedBox(height: 16),
        
        // Demo Navigation
        AccessibleCard(
          semanticLabel: 'Font size demonstration',
          child: Column(
            children: [
              AccessibleTextButton(
                text: 'View Font Size Demo',
                semanticLabel: 'Open font size demonstration screen',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FontSizeDemoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSettingsSection(AccessibilityService service) {
    return Column(
      children: [
        // Color Blind Settings Widget
        const ColorBlindSettingsWidget(),
        
        const SizedBox(height: 16),
        
        // Demo Navigation
        AccessibleCard(
          semanticLabel: 'Color vision test and demonstration',
          child: Column(
            children: [
              AccessibleTextButton(
                text: 'Take Color Vision Test',
                semanticLabel: 'Open color vision test and demonstration screen',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ColorBlindTestScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSettingsSection(AccessibilityService service) {
    return Column(
      children: [
        // Gesture Navigation Widget
        const GestureNavigationWidget(),
        
        const SizedBox(height: 16),
        
        // Demo Navigation
        AccessibleCard(
          semanticLabel: 'Gesture navigation demonstration',
          child: Column(
            children: [
              AccessibleTextButton(
                text: 'Try Gesture Navigation Demo',
                semanticLabel: 'Open gesture navigation demonstration screen',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestureNavigationDemoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return AccessibleCard(
      semanticLabel: 'Quick accessibility actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: AccessibleElevatedButton(
                  text: 'Reset All',
                  semanticLabel: 'Reset all accessibility settings',
                  semanticHint: 'Resets all settings to default values',
                  icon: Icons.refresh,
                  onPressed: () => _showResetDialog(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AccessibleElevatedButton(
                  text: 'Help',
                  semanticLabel: 'Accessibility help',
                  semanticHint: 'Opens accessibility help guide',
                  icon: Icons.help_outline,
                  onPressed: () => _showHelpDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AccessibleDialog(
        semanticLabel: 'Reset accessibility settings confirmation',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reset Accessibility Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Are you sure you want to reset all accessibility settings to default values?'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AccessibleElevatedButton(
                  text: 'Cancel',
                  semanticLabel: 'Cancel reset',
                  onPressed: () => Navigator.pop(context),
                ),
                AccessibleElevatedButton(
                  text: 'Reset',
                  semanticLabel: 'Confirm reset',
                  onPressed: () {
                    // TODO: Implement reset functionality
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AccessibleDialog(
        semanticLabel: 'Accessibility help information',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility Help',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('FareGuard supports various accessibility features:'),
            const SizedBox(height: 12),
            const Text('• Screen reader compatibility'),
            const Text('• High contrast mode for better visibility'),
            const Text('• Adjustable font sizes'),
            const Text('• Color blind friendly themes'),
            const Text('• Enhanced gesture navigation'),
            const SizedBox(height: 16),
            const Text('For more help, contact our accessibility support team.'),
            const SizedBox(height: 24),
            AccessibleElevatedButton(
              text: 'Close',
              semanticLabel: 'Close help dialog',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}