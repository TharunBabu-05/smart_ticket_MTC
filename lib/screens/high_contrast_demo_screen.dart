import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import '../widgets/high_contrast_widgets.dart';
import '../widgets/accessible_widgets.dart';

class HighContrastDemoScreen extends StatefulWidget {
  const HighContrastDemoScreen({Key? key}) : super(key: key);

  @override
  State<HighContrastDemoScreen> createState() => _HighContrastDemoScreenState();
}

class _HighContrastDemoScreenState extends State<HighContrastDemoScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _switchValue = false;
  double _sliderValue = 50.0;
  int _radioValue = 1;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('High Contrast Demo'),
            leading: AccessibleIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Back to accessibility settings',
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              AccessibleIconButton(
                icon: accessibilityService.highContrastEnabled 
                  ? Icons.contrast 
                  : Icons.visibility_outlined,
                semanticLabel: accessibilityService.highContrastEnabled
                  ? 'Disable high contrast'
                  : 'Enable high contrast',
                onPressed: () => accessibilityService.toggleHighContrast(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),
                const SizedBox(height: 24),
                
                // Interactive Elements Demo
                _buildInteractiveDemo(),
                const SizedBox(height: 24),
                
                // Text Readability Demo
                _buildTextDemo(),
                const SizedBox(height: 24),
                
                // Color and Icon Demo
                _buildColorIconDemo(),
                const SizedBox(height: 24),
                
                // Navigation Demo
                _buildNavigationDemo(),
                const SizedBox(height: 24),
                
                // Contrast Test Pattern
                const ContrastTestPattern(),
              ],
            ),
          ),
          floatingActionButton: const HighContrastToggleButton(),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return AccessibleCard(
          semanticLabel: 'High contrast demonstration header',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    service.highContrastEnabled ? Icons.contrast : Icons.visibility,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Contrast Mode',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          service.highContrastEnabled 
                            ? 'Currently Active - Enhanced visibility'
                            : 'Currently Inactive - Standard visibility',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: service.highContrastEnabled 
                              ? Colors.green 
                              : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This demo shows how high contrast mode improves the visibility of text, buttons, icons, and other interface elements. Compare the difference by toggling the mode on and off.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveDemo() {
    return AccessibleCard(
      semanticLabel: 'Interactive elements demonstration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interactive Elements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Buttons Row
          Row(
            children: [
              Expanded(
                child: AccessibleElevatedButton(
                  text: 'Primary',
                  semanticLabel: 'Primary button demo',
                  onPressed: () => _showDemoMessage('Primary button pressed'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AccessibleElevatedButton(
                  text: 'Secondary',
                  semanticLabel: 'Secondary button demo',  
                  onPressed: () => _showDemoMessage('Secondary button pressed'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Text Field
          AccessibleTextField(
            controller: _textController,
            labelText: 'Test Text Field',
            hintText: 'Type to test visibility...',
            semanticLabel: 'Text input demonstration',
          ),
          
          const SizedBox(height: 16),
          
          // Switch and Slider
          AccessibleSwitch(
            value: _switchValue,
            onChanged: (value) => setState(() => _switchValue = value),
            label: 'Toggle Switch Demo',
          ),
          
          const SizedBox(height: 16),
          
          Slider(
            value: _sliderValue,
            min: 0,
            max: 100,
            divisions: 10,
            label: _sliderValue.round().toString(),
            onChanged: (value) => setState(() => _sliderValue = value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDemo() {
    return AccessibleCard(
      semanticLabel: 'Text readability demonstration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Readability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Large Heading Text',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Medium Title Text',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Regular body text that demonstrates how high contrast mode improves readability for users with visual impairments. The enhanced contrast makes text much easier to read against backgrounds.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Small caption text for fine details',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          
          const SizedBox(height: 16),
          
          // Color text samples
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                'Primary Text',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                'Secondary Text', 
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              Text(
                'Error Text',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorIconDemo() {
    return AccessibleCard(
      semanticLabel: 'Color and icon visibility demonstration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Colors & Icons',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Icon Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 6,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildIconDemo(Icons.home, 'Home'),
              _buildIconDemo(Icons.search, 'Search'),
              _buildIconDemo(Icons.favorite, 'Favorite'),
              _buildIconDemo(Icons.settings, 'Settings'),
              _buildIconDemo(Icons.info, 'Info'),
              _buildIconDemo(Icons.warning, 'Warning'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusChip('Active', Colors.green, Icons.check_circle),
              _buildStatusChip('Warning', Colors.orange, Icons.warning),
              _buildStatusChip('Error', Colors.red, Icons.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconDemo(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
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
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDemo() {
    return AccessibleCard(
      semanticLabel: 'Navigation elements demonstration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navigation Elements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // List tiles
          ...List.generate(3, (index) {
            return AccessibleListTile(
              leading: Icon(
                [Icons.account_circle, Icons.settings, Icons.help][index],
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(['Profile', 'Settings', 'Help'][index]),
              subtitle: Text(['Manage your profile', 'App preferences', 'Get support'][index]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDemoMessage('${['Profile', 'Settings', 'Help'][index]} tapped'),
              semanticLabel: '${['Profile', 'Settings', 'Help'][index]} option',
            );
          }),
          
          const Divider(height: 32),
          
          // Radio buttons demo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Radio Selection Demo:', style: Theme.of(context).textTheme.titleMedium),
              ...List.generate(3, (index) {
                return RadioListTile<int>(
                  title: Text('Option ${index + 1}'),
                  value: index,
                  groupValue: _radioValue,
                  onChanged: (value) => setState(() => _radioValue = value!),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _showDemoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}