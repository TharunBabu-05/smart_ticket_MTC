import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_widgets.dart';

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
          
          const Divider(),
          
          // Preview of current contrast
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: service.highContrastEnabled 
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: service.highContrastEnabled 
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Semantics(
              label: 'Contrast preview',
              hint: 'Shows current contrast level',
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: service.highContrastEnabled 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                      : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      service.highContrastEnabled 
                        ? 'High contrast active - better visibility'
                        : 'Normal contrast - standard visibility',
                      style: TextStyle(
                        color: service.highContrastEnabled 
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSettingsSection(AccessibilityService service) {
    return AccessibleCard(
      semanticLabel: 'Text and font settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text & Font Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Font Scale Slider
          AccessibleSlider(
            value: service.fontScaleFactor,
            onChanged: service.setFontScaleFactor,
            min: 0.8,
            max: 2.0,
            divisions: 12,
            label: 'Font Size',
            semanticLabel: 'Font size adjustment',
          ),
          
          const SizedBox(height: 16),
          
          // Font Scale Quick Actions
          Semantics(
            label: 'Font size quick adjustment buttons',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFontScaleButton(service, 0.8, 'Small', context),
                _buildFontScaleButton(service, 1.0, 'Normal', context),
                _buildFontScaleButton(service, 1.3, 'Large', context),
                _buildFontScaleButton(service, 1.6, 'Extra Large', context),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Preview Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Semantics(
              label: 'Font size preview text',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview Text',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is how text will appear with current font size settings.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontScaleButton(AccessibilityService service, double scale, String label, BuildContext context) {
    final isSelected = (service.fontScaleFactor - scale).abs() < 0.05;
    
    return AccessibleElevatedButton(
      text: label,
      semanticLabel: '$label font size',
      semanticHint: isSelected ? 'Currently selected' : 'Tap to select $label font size',
      onPressed: () => service.setFontScaleFactor(scale),
    );
  }

  Widget _buildColorSettingsSection(AccessibilityService service) {
    return AccessibleCard(
      semanticLabel: 'Color and vision settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color & Vision Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Color Blind Support',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          // Color Blind Mode Options
          ...ColorBlindMode.values.map((mode) {
            return AccessibleListTile(
              leading: Radio<ColorBlindMode>(
                value: mode,
                groupValue: service.colorBlindMode,
                onChanged: (value) => service.setColorBlindMode(value!),
              ),
              title: Text(mode.displayName),
              onTap: () => service.setColorBlindMode(mode),
              semanticLabel: '${mode.displayName} color mode',
              semanticHint: service.colorBlindMode == mode 
                ? 'Currently selected' 
                : 'Tap to select ${mode.displayName}',
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          // Color Preview
          if (service.colorBlindMode != ColorBlindMode.none)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Semantics(
                label: 'Color adjustment preview',
                child: Column(
                  children: [
                    Text('Color Adjustment Preview'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildColorCircle(Theme.of(context).colorScheme.primary, 'Primary'),
                        _buildColorCircle(Theme.of(context).colorScheme.secondary, 'Secondary'),
                        _buildColorCircle(Theme.of(context).colorScheme.error, 'Error'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color, String label) {
    return Semantics(
      label: '$label color',
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNavigationSettingsSection(AccessibilityService service) {
    return AccessibleCard(
      semanticLabel: 'Navigation settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navigation Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          AccessibleSwitch(
            value: service.gestureNavigationEnabled,
            onChanged: (_) => service.toggleGestureNavigation(),
            label: 'Enhanced Gesture Navigation',
            semanticLabel: 'Enhanced gesture navigation toggle',
          ),
          
          if (service.gestureNavigationEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Semantics(
                label: 'Gesture navigation help',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gesture Shortcuts:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('• Swipe right: Go back'),
                    const Text('• Double tap with two fingers: Home'),
                    const Text('• Long press: Context menu'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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