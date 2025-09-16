import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import 'accessible_widgets.dart';

class FontSizeAdjustmentWidget extends StatelessWidget {
  const FontSizeAdjustmentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return AccessibleCard(
          semanticLabel: 'Font size adjustment controls',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Font Size',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Adjust text size for better readability',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Font size preview
              FontSizePreview(scaleFactor: service.fontScaleFactor),
              
              const SizedBox(height: 16),
              
              // Font size slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Size: ${(service.fontScaleFactor * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      AccessibleTextButton(
                        text: 'Reset',
                        semanticLabel: 'Reset font size to default',
                        onPressed: () => service.setFontScaleFactor(1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: service.fontScaleFactor,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    label: '${(service.fontScaleFactor * 100).round()}%',
                    onChanged: (value) => service.setFontScaleFactor(value),
                  ),
                  
                  // Size labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Small\n80%', 
                           textAlign: TextAlign.center,
                           style: Theme.of(context).textTheme.bodySmall),
                      Text('Default\n100%', 
                           textAlign: TextAlign.center,
                           style: Theme.of(context).textTheme.bodySmall),
                      Text('Large\n200%', 
                           textAlign: TextAlign.center,
                           style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Quick size buttons
              QuickFontSizeButtons(),
            ],
          ),
        );
      },
    );
  }
}

class FontSizePreview extends StatelessWidget {
  final double scaleFactor;
  
  const FontSizePreview({
    Key? key,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Sample text at different sizes
          Text(
            'Heading Text',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Regular body text that shows how your content will appear with the selected font size.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Small caption text',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          
          const SizedBox(height: 12),
          
          // Scale factor indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Scale: ${(scaleFactor * 100).round()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickFontSizeButtons extends StatelessWidget {
  const QuickFontSizeButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Sizes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickSizeButton(
                  label: 'Small',
                  scale: 0.8,
                  isSelected: service.fontScaleFactor == 0.8,
                  onPressed: () => service.setFontScaleFactor(0.8),
                ),
                _QuickSizeButton(
                  label: 'Default',
                  scale: 1.0,
                  isSelected: service.fontScaleFactor == 1.0,
                  onPressed: () => service.setFontScaleFactor(1.0),
                ),
                _QuickSizeButton(
                  label: 'Large',
                  scale: 1.3,
                  isSelected: service.fontScaleFactor == 1.3,
                  onPressed: () => service.setFontScaleFactor(1.3),
                ),
                _QuickSizeButton(
                  label: 'Extra Large',
                  scale: 1.6,
                  isSelected: service.fontScaleFactor == 1.6,
                  onPressed: () => service.setFontScaleFactor(1.6),
                ),
                _QuickSizeButton(
                  label: 'Maximum',
                  scale: 2.0,
                  isSelected: service.fontScaleFactor == 2.0,
                  onPressed: () => service.setFontScaleFactor(2.0),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuickSizeButton extends StatelessWidget {
  final String label;
  final double scale;
  final bool isSelected;
  final VoidCallback onPressed;

  const _QuickSizeButton({
    required this.label,
    required this.scale,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
          ? theme.colorScheme.primary
          : theme.colorScheme.surface,
        foregroundColor: isSelected
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface,
        side: BorderSide(
          color: isSelected 
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${(scale * 100).round()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected
                ? theme.colorScheme.onPrimary.withOpacity(0.8)
                : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class FontSizeDemoScreen extends StatelessWidget {
  const FontSizeDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Font Size Demo'),
            leading: AccessibleIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Back to accessibility settings',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current scale display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Font Size',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${(service.fontScaleFactor * 100).round()}%',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Text samples
                _buildTextSamples(context),
                
                const SizedBox(height: 24),
                
                // UI element samples
                _buildUISamples(context),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => service.setFontScaleFactor(1.0),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Size'),
          ),
        );
      },
    );
  }

  Widget _buildTextSamples(BuildContext context) {
    return AccessibleCard(
      semanticLabel: 'Text size samples',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Samples',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Display Large',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Headline Medium',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Title Large',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Body Large - This is regular body text that you would typically see in paragraphs throughout the application. It should be comfortable to read at any size.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Body Medium - This is slightly smaller text that might be used for secondary information or descriptions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Body Small - This is small text used for captions, labels, and fine print.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildUISamples(BuildContext context) {
    return AccessibleCard(
      semanticLabel: 'UI element size samples',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UI Elements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Buttons
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
          
          const SizedBox(height: 16),
          
          // Text field
          const TextField(
            decoration: InputDecoration(
              labelText: 'Sample Text Field',
              hintText: 'Type something here...',
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List items
          ...List.generate(3, (index) {
            return ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text('List Item ${index + 1}'),
              subtitle: Text('Subtitle text for item ${index + 1}'),
              trailing: const Icon(Icons.chevron_right),
            );
          }),
        ],
      ),
    );
  }
}