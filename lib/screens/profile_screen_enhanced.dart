import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreenEnhanced extends StatefulWidget {
  const ProfileScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<ProfileScreenEnhanced> createState() => _ProfileScreenEnhancedState();
}

class _ProfileScreenEnhancedState extends State<ProfileScreenEnhanced> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  String _selectedAvatar = 'avatar_1';
  
  // Unique profile picture options
  final List<Map<String, String>> _avatarOptions = [
    {'id': 'avatar_1', 'emoji': '👨‍💼', 'name': 'Professional'},
    {'id': 'avatar_2', 'emoji': '👩‍💼', 'name': 'Business'},
    {'id': 'avatar_3', 'emoji': '🧑‍🎓', 'name': 'Student'},
    {'id': 'avatar_4', 'emoji': '👨‍🔬', 'name': 'Tech Expert'},
    {'id': 'avatar_5', 'emoji': '👩‍🎨', 'name': 'Creative'},
    {'id': 'avatar_6', 'emoji': '🧑‍🏫', 'name': 'Teacher'},
    {'id': 'avatar_7', 'emoji': '👨‍⚕️', 'name': 'Healthcare'},
    {'id': 'avatar_8', 'emoji': '👩‍🚀', 'name': 'Explorer'},
    {'id': 'avatar_9', 'emoji': '🧑‍💻', 'name': 'Developer'},
    {'id': 'avatar_10', 'emoji': '👨‍🎨', 'name': 'Designer'},
    {'id': 'avatar_11', 'emoji': '👩‍🔧', 'name': 'Engineer'},
    {'id': 'avatar_12', 'emoji': '🧑‍🍳', 'name': 'Chef'},
    {'id': 'avatar_13', 'emoji': '👨‍🎤', 'name': 'Performer'},
    {'id': 'avatar_14', 'emoji': '👩‍🏃', 'name': 'Athlete'},
    {'id': 'avatar_15', 'emoji': '🧑‍🎮', 'name': 'Gamer'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load from Firebase
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? user.displayName ?? '';
            _mobileController.text = data['mobile'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _addressController.text = data['address'] ?? '';
            _selectedAvatar = data['avatar'] ?? 'avatar_1';
            _isLoading = false;
          });
        } else {
          // Initialize with default values
          setState(() {
            _nameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save to Firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': _nameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'avatar': _selectedAvatar,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save avatar to SharedPreferences for quick access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar', _selectedAvatar);
        await prefs.setString('user_name', _nameController.text.trim());

        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Widget _buildAvatarSelector(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Avatar',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 120,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = _avatarOptions[index];
              final isSelected = _selectedAvatar == avatar['id'];
              
              return GestureDetector(
                onTap: _isEditing ? () {
                  setState(() {
                    _selectedAvatar = avatar['id']!;
                  });
                } : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outline,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        avatar['emoji']!,
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(height: 4),
                      Text(
                        avatar['name']!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly || !_isEditing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          filled: true,
          fillColor: _isEditing ? colorScheme.surface : colorScheme.surfaceContainer,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: colorScheme.onPrimary),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Avatar Section
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Current Avatar Display
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.primary, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                _avatarOptions.firstWhere(
                                  (avatar) => avatar['id'] == _selectedAvatar,
                                  orElse: () => _avatarOptions[0],
                                )['emoji']!,
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 16),
                          if (_isEditing) _buildAvatarSelector(colorScheme, theme),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Profile Details Section
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            colorScheme: colorScheme,
                            theme: theme,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          
                          _buildTextField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            colorScheme: colorScheme,
                            theme: theme,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Mobile number is required';
                              }
                              if (value.trim().length < 10) {
                                return 'Enter a valid mobile number';
                              }
                              return null;
                            },
                          ),
                          
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            colorScheme: colorScheme,
                            theme: theme,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          
                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on,
                            maxLines: 3,
                            colorScheme: colorScheme,
                            theme: theme,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Address is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Action Buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                });
                                _loadUserProfile(); // Reload original data
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                foregroundColor: colorScheme.onSurface,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Save Profile',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
