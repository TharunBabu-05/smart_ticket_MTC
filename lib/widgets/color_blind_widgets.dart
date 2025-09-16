import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import 'accessible_widgets.dart';

class ColorBlindSettingsWidget extends StatelessWidget {
  const ColorBlindSettingsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return AccessibleCard(
          semanticLabel: 'Color blind friendly settings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color Vision Support',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Adjust colors for different types of color vision',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Current selection display
              ColorBlindStatusCard(currentMode: service.colorBlindMode),
              
              const SizedBox(height: 16),
              
              // Color mode options
              ...ColorBlindMode.values.map((mode) {
                return ColorBlindModeOption(
                  mode: mode,
                  isSelected: service.colorBlindMode == mode,
                  onChanged: () => service.setColorBlindMode(mode),
                );
              }),
              
              const SizedBox(height: 16),
              
              // Color preview
              if (service.colorBlindMode != ColorBlindMode.none)
                ColorBlindPreview(mode: service.colorBlindMode),
            ],
          ),
        );
      },
    );
  }
}

class ColorBlindStatusCard extends StatelessWidget {
  final ColorBlindMode currentMode;
  
  const ColorBlindStatusCard({
    Key? key,
    required this.currentMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = currentMode != ColorBlindMode.none;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: isActive 
          ? Border.all(color: Theme.of(context).colorScheme.primary)
          : null,
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.palette : Icons.palette_outlined,
            color: isActive 
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Color Adjustment Active' : 'Standard Colors',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isActive
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  currentMode.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive
                      ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

class ColorBlindModeOption extends StatelessWidget {
  final ColorBlindMode mode;
  final bool isSelected;
  final VoidCallback onChanged;
  
  const ColorBlindModeOption({
    Key? key,
    required this.mode,
    required this.isSelected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<ColorBlindMode>(
                value: mode,
                groupValue: isSelected ? mode : null,
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (mode != ColorBlindMode.none) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getModeDescription(mode),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (mode != ColorBlindMode.none)
                _buildColorSample(context, mode),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeDescription(ColorBlindMode mode) {
    switch (mode) {
      case ColorBlindMode.protanopia:
        return 'Difficulty distinguishing red and green colors';
      case ColorBlindMode.deuteranopia:
        return 'Most common form of color blindness';
      case ColorBlindMode.tritanopia:
        return 'Difficulty distinguishing blue and yellow colors';
      case ColorBlindMode.none:
        return '';
    }
  }

  Widget _buildColorSample(BuildContext context, ColorBlindMode mode) {
    List<Color> colors = [];
    switch (mode) {
      case ColorBlindMode.protanopia:
        colors = [Colors.blue[700]!, Colors.orange[700]!];
        break;
      case ColorBlindMode.deuteranopia:
        colors = [Colors.blue[600]!, Colors.yellow[700]!];
        break;
      case ColorBlindMode.tritanopia:
        colors = [Colors.red[600]!, Colors.green[700]!];
        break;
      case ColorBlindMode.none:
        break;
    }
    
    if (colors.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((color) {
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
        );
      }).toList(),
    );
  }
}

class ColorBlindPreview extends StatelessWidget {
  final ColorBlindMode mode;
  
  const ColorBlindPreview({
    Key? key,
    required this.mode,
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
                'Color Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Color swatches
          _buildColorSwatches(context),
          
          const SizedBox(height: 12),
          
          // Sample UI elements
          _buildSampleElements(context),
        ],
      ),
    );
  }

  Widget _buildColorSwatches(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adjusted Colors:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildColorSwatch(
              context, 
              'Primary', 
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            _buildColorSwatch(
              context, 
              'Secondary', 
              Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 16),
            _buildColorSwatch(
              context, 
              'Error', 
              Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatch(BuildContext context, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSampleElements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sample Elements:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Sample buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: null,
              child: const Text('Primary'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: null,
              child: const Text('Secondary'),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Sample status indicators
        Row(
          children: [
            _buildStatusIndicator(context, 'Success', Colors.green),
            const SizedBox(width: 12),
            _buildStatusIndicator(context, 'Warning', Colors.orange),
            const SizedBox(width: 12),
            _buildStatusIndicator(context, 'Error', Theme.of(context).colorScheme.error),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ColorBlindTestScreen extends StatelessWidget {
  const ColorBlindTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Color Vision Test'),
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
                // Current mode display
                _buildCurrentModeCard(context, service),
                
                const SizedBox(height: 24),
                
                // Color comparison grid
                _buildColorComparisonGrid(context),
                
                const SizedBox(height: 24),
                
                // UI element tests
                _buildUIElementTests(context),
                
                const SizedBox(height: 24),
                
                // Quick mode switcher
                _buildQuickModeSwitcher(context, service),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentModeCard(BuildContext context, AccessibilityService service) {
    return AccessibleCard(
      semanticLabel: 'Current color vision mode',
      child: Column(
        children: [
          Icon(
            Icons.visibility,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Current Mode',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            service.colorBlindMode.displayName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorComparisonGrid(BuildContext context) {
    return AccessibleCard(
      semanticLabel: 'Color comparison grid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color Differentiation Test',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Color grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final colors = [
                Colors.red, Colors.green, Colors.blue,
                Colors.orange, Colors.yellow, Colors.purple,
                Colors.pink, Colors.cyan, Colors.lime,
                Colors.indigo, Colors.amber, Colors.teal,
              ];
              
              return Container(
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUIElementTests(BuildContext context) {
    return AccessibleCard(
      semanticLabel: 'UI element color tests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interface Elements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Buttons test
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Primary Action'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const Text('Secondary'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTestChip('Success', Colors.green, Icons.check),
              _buildTestChip('Warning', Colors.orange, Icons.warning),
              _buildTestChip('Error', Colors.red, Icons.error),
              _buildTestChip('Info', Colors.blue, Icons.info),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress indicators
          Column(
            children: [
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.3,
                color: Theme.of(context).colorScheme.error,
                backgroundColor: Colors.grey.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickModeSwitcher(BuildContext context, AccessibilityService service) {
    return AccessibleCard(
      semanticLabel: 'Quick color mode switcher',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Different Modes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ColorBlindMode.values.map((mode) {
              final isSelected = service.colorBlindMode == mode;
              return ElevatedButton(
                onPressed: () => service.setColorBlindMode(mode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                  foregroundColor: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(mode.displayName.split(' ')[0]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}