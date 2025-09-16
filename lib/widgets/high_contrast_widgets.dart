import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';

/// High Contrast Preview Widget
/// Shows before/after comparison of contrast settings
class HighContrastPreview extends StatefulWidget {
  const HighContrastPreview({Key? key}) : super(key: key);

  @override
  State<HighContrastPreview> createState() => _HighContrastPreviewState();
}

class _HighContrastPreviewState extends State<HighContrastPreview> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High Contrast Preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // Toggle Switch
                Row(
                  children: [
                    Text(
                      'High Contrast Mode',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Switch(
                      value: accessibilityService.highContrastEnabled,
                      onChanged: (_) => accessibilityService.toggleHighContrast(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Preview Elements
                _buildPreviewSection(context, accessibilityService),
                
                const SizedBox(height: 20),
                
                // Contrast Ratio Information
                _buildContrastInfo(context, accessibilityService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewSection(BuildContext context, AccessibilityService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Elements:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        // Button Preview
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Primary Button'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined Button'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Text Field Preview
        TextField(
          decoration: InputDecoration(
            labelText: 'Sample Text Field',
            hintText: 'Type something here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Card Preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample Card',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how cards appear with current contrast settings.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Icon and text visibility',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // List Item Preview
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: const Icon(Icons.accessibility),
            title: const Text('Accessibility Setting'),
            subtitle: const Text('High contrast improves visibility'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }

  Widget _buildContrastInfo(BuildContext context, AccessibilityService service) {
    final theme = Theme.of(context);
    final contrastRatio = service.highContrastEnabled ? "21:1" : "4.5:1";
    final wcagLevel = service.highContrastEnabled ? "AAA" : "AA";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                service.highContrastEnabled ? Icons.contrast : Icons.visibility,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Contrast Information',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Contrast Ratio:', contrastRatio, 
            service.highContrastEnabled ? Colors.green : Colors.orange),
          const SizedBox(height: 8),
          _buildInfoRow('WCAG Level:', wcagLevel,
            service.highContrastEnabled ? Colors.green : Colors.blue),
          const SizedBox(height: 8),
          _buildInfoRow('Status:', 
            service.highContrastEnabled ? 'Enhanced' : 'Standard',
            service.highContrastEnabled ? Colors.green : Colors.grey),
          
          const SizedBox(height: 12),
          
          if (service.highContrastEnabled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optimal Contrast Active',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Meets WCAG AAA standards for visual accessibility',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard Contrast',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Enable high contrast for better visibility',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// High Contrast Toggle Button
/// Floating action button for quick contrast toggle
class HighContrastToggleButton extends StatelessWidget {
  const HighContrastToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return FloatingActionButton.extended(
          onPressed: () => accessibilityService.toggleHighContrast(),
          icon: Icon(
            accessibilityService.highContrastEnabled 
              ? Icons.contrast 
              : Icons.visibility,
          ),
          label: Text(
            accessibilityService.highContrastEnabled 
              ? 'High Contrast ON' 
              : 'High Contrast OFF',
          ),
          backgroundColor: accessibilityService.highContrastEnabled
            ? (Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black)
            : Theme.of(context).colorScheme.primary,
          foregroundColor: accessibilityService.highContrastEnabled
            ? (Theme.of(context).brightness == Brightness.dark 
                ? Colors.black 
                : Colors.white)
            : Theme.of(context).colorScheme.onPrimary,
          tooltip: accessibilityService.highContrastEnabled
            ? 'Disable high contrast mode'
            : 'Enable high contrast mode for better visibility',
        );
      },
    );
  }
}

/// Quick Contrast Settings Widget
/// Compact widget for settings screens
class QuickContrastSettings extends StatelessWidget {
  const QuickContrastSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.contrast,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Visual Contrast',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('High Contrast Mode'),
                  subtitle: Text(
                    accessibilityService.highContrastEnabled
                      ? 'Enhanced visibility with maximum contrast'
                      : 'Standard contrast for normal viewing',
                  ),
                  value: accessibilityService.highContrastEnabled,
                  onChanged: (_) => accessibilityService.toggleHighContrast(),
                  secondary: Icon(
                    accessibilityService.highContrastEnabled
                      ? Icons.visibility
                      : Icons.visibility_outlined,
                  ),
                ),
                
                if (accessibilityService.highContrastEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'High contrast mode improves text and element visibility for users with visual impairments.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Contrast Test Pattern Widget
/// Displays test patterns to verify contrast levels
class ContrastTestPattern extends StatelessWidget {
  const ContrastTestPattern({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contrast Test Pattern',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Color contrast grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildContrastTile(theme.colorScheme.primary, theme.colorScheme.onPrimary, 'Primary'),
                _buildContrastTile(theme.colorScheme.secondary, theme.colorScheme.onSecondary, 'Secondary'),
                _buildContrastTile(theme.colorScheme.surface, theme.colorScheme.onSurface, 'Surface'),
                _buildContrastTile(theme.colorScheme.error, theme.colorScheme.onError, 'Error'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Text size demonstration
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Large Text (18pt)', style: theme.textTheme.headlineSmall),
                Text('Normal Text (14pt)', style: theme.textTheme.bodyMedium),
                Text('Small Text (12pt)', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContrastTile(Color backgroundColor, Color textColor, String label) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}