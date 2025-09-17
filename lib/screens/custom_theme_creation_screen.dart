import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/user_preferences_model.dart';
import '../services/personalization_service.dart';

/// Custom Theme Creation Screen
class CustomThemeCreationScreen extends StatefulWidget {
  final CustomTheme? initialTheme;

  const CustomThemeCreationScreen({Key? key, this.initialTheme}) : super(key: key);

  @override
  _CustomThemeCreationScreenState createState() => _CustomThemeCreationScreenState();
}

class _CustomThemeCreationScreenState extends State<CustomThemeCreationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _themeNameController = TextEditingController();
  
  late Color _primaryColor;
  late Color _secondaryColor;
  late Color _backgroundColor;
  late Color _surfaceColor;
  late Color _textColor;
  late Color _cardColor;
  late bool _isDarkMode;
  
  late TabController _tabController;
  bool _isPreviewMode = false;
  CustomTheme? _previewTheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize with existing theme or defaults
    final theme = widget.initialTheme ?? CustomTheme.defaultTheme;
    _themeNameController.text = theme.themeName;
    _primaryColor = theme.primaryColor;
    _secondaryColor = theme.secondaryColor;
    _backgroundColor = theme.backgroundColor;
    _surfaceColor = theme.surfaceColor;
    _textColor = theme.textColor;
    _cardColor = theme.cardColor;
    _isDarkMode = theme.isDarkMode;
    
    _updatePreviewTheme();
  }

  @override
  void dispose() {
    _themeNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updatePreviewTheme() {
    setState(() {
      _previewTheme = CustomTheme(
        themeName: _themeNameController.text.isEmpty ? 'Custom Theme' : _themeNameController.text,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        backgroundColor: _backgroundColor,
        surfaceColor: _surfaceColor,
        textColor: _textColor,
        cardColor: _cardColor,
        isDarkMode: _isDarkMode,
        createdAt: DateTime.now(),
      );
    });
  }

  void _showColorPicker(Color currentColor, String colorName, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = currentColor;
        
        return AlertDialog(
          title: Text('Choose $colorName Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) => tempColor = color,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              showLabel: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.of(context).pop();
              },
              child: Text('Select'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorSelector(String label, Color color, Function(Color) onChanged) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
        ),
        title: Text(label),
        subtitle: Text('#${color.value.toRadixString(16).substring(2).toUpperCase()}'),
        trailing: Icon(Icons.edit),
        onTap: () => _showColorPicker(color, label, onChanged),
      ),
    );
  }

  Widget _buildBasicSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Theme Name
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Name', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _themeNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter theme name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a theme name';
                      }
                      return null;
                    },
                    onChanged: (_) => _updatePreviewTheme(),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Dark Mode Toggle
          Card(
            child: SwitchListTile(
              title: Text('Dark Mode'),
              subtitle: Text('Enable dark theme colors'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                  // Auto-adjust colors for dark mode
                  if (value) {
                    _backgroundColor = Colors.grey.shade900;
                    _surfaceColor = Colors.grey.shade800;
                    _textColor = Colors.white;
                    _cardColor = Colors.grey.shade800;
                  } else {
                    _backgroundColor = Colors.white;
                    _surfaceColor = Colors.grey.shade100;
                    _textColor = Colors.black87;
                    _cardColor = Colors.white;
                  }
                });
                _updatePreviewTheme();
              },
            ),
          ),
          
          SizedBox(height: 16),
          
          // Quick Theme Presets
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Presets', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetButton('Blue', Colors.blue, Colors.blueAccent),
                      _buildPresetButton('Green', Colors.green, Colors.lightGreen),
                      _buildPresetButton('Purple', Colors.purple, Colors.purpleAccent),
                      _buildPresetButton('Orange', Colors.orange, Colors.orangeAccent),
                      _buildPresetButton('Teal', Colors.teal, Colors.tealAccent),
                      _buildPresetButton('Red', Colors.red, Colors.redAccent),
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

  Widget _buildPresetButton(String name, Color primary, Color secondary) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _primaryColor = primary;
          _secondaryColor = secondary;
        });
        _updatePreviewTheme();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      child: Text(name),
    );
  }

  Widget _buildColorSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Color Configuration', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 16),
          
          _buildColorSelector('Primary Color', _primaryColor, (color) {
            setState(() => _primaryColor = color);
            _updatePreviewTheme();
          }),
          
          _buildColorSelector('Secondary Color', _secondaryColor, (color) {
            setState(() => _secondaryColor = color);
            _updatePreviewTheme();
          }),
          
          _buildColorSelector('Background Color', _backgroundColor, (color) {
            setState(() => _backgroundColor = color);
            _updatePreviewTheme();
          }),
          
          _buildColorSelector('Surface Color', _surfaceColor, (color) {
            setState(() => _surfaceColor = color);
            _updatePreviewTheme();
          }),
          
          _buildColorSelector('Text Color', _textColor, (color) {
            setState(() => _textColor = color);
            _updatePreviewTheme();
          }),
          
          _buildColorSelector('Card Color', _cardColor, (color) {
            setState(() => _cardColor = color);
            _updatePreviewTheme();
          }),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_previewTheme == null) return Container();

    return Theme(
      data: _previewTheme!.toThemeData(),
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Theme Preview', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              
              // App Bar Preview
              Card(
                child: Container(
                  height: 56,
                  color: _previewTheme!.primaryColor,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.menu, color: _isDarkMode ? Colors.white : Colors.black),
                        SizedBox(width: 16),
                        Text(
                          'Smart Ticket MTC',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.notifications, color: _isDarkMode ? Colors.white : Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Card Preview
              Card(
                color: _previewTheme!.cardColor,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Card',
                        style: TextStyle(
                          color: _previewTheme!.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This is how cards will look with your custom theme.',
                        style: TextStyle(color: _previewTheme!.textColor),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Button Preview
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _previewTheme!.primaryColor,
                        foregroundColor: _isDarkMode ? Colors.white : Colors.black,
                      ),
                      child: Text('Primary Button'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _previewTheme!.primaryColor,
                        side: BorderSide(color: _previewTheme!.primaryColor),
                      ),
                      child: Text('Outlined Button'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // List Tile Preview
              Card(
                color: _previewTheme!.cardColor,
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _previewTheme!.secondaryColor,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        'Sample List Item',
                        style: TextStyle(color: _previewTheme!.textColor),
                      ),
                      subtitle: Text(
                        'This shows how list items will appear',
                        style: TextStyle(color: _previewTheme!.textColor.withOpacity(0.7)),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: _previewTheme!.textColor.withOpacity(0.5),
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: _previewTheme!.primaryColor,
                      ),
                      title: Text(
                        'Another List Item',
                        style: TextStyle(color: _previewTheme!.textColor),
                      ),
                      subtitle: Text(
                        'With different icon styling',
                        style: TextStyle(color: _previewTheme!.textColor.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTheme() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final theme = CustomTheme(
        themeName: _themeNameController.text,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        backgroundColor: _backgroundColor,
        surfaceColor: _surfaceColor,
        textColor: _textColor,
        cardColor: _cardColor,
        isDarkMode: _isDarkMode,
        createdAt: DateTime.now(),
      );

      await PersonalizationService.instance.updateTheme(theme);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme "${theme.themeName}" saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(theme);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving theme: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create Custom Theme'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.preview),
              onPressed: () {
                setState(() => _isPreviewMode = !_isPreviewMode);
              },
              tooltip: 'Toggle Preview',
            ),
          ],
          bottom: _isPreviewMode ? null : TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Basic'),
              Tab(icon: Icon(Icons.color_lens), text: 'Colors'),
              Tab(icon: Icon(Icons.preview), text: 'Preview'),
            ],
          ),
        ),
        body: _isPreviewMode
            ? _buildPreview()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicSettings(),
                  _buildColorSettings(),
                  _buildPreview(),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saveTheme,
          icon: Icon(Icons.save),
          label: Text('Save Theme'),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }
}