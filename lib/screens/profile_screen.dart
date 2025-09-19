import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import '../widgets/user_avatar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  String _selectedAvatar = '👨‍💼';
  String _displayName = 'Your Name';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Profile statistics
  int _totalTrips = 0;
  double _moneySaved = 0.0;
  int _carbonFootprint = 0;
  
  // Avatar options with emojis
  final List<Map<String, String>> _avatarOptions = [
    {'emoji': '👨‍💼', 'name': 'Professional'},
    {'emoji': '👩‍💼', 'name': 'Business'},
    {'emoji': '🧑‍🎓', 'name': 'Student'},
    {'emoji': '👨‍🔬', 'name': 'Tech Expert'},
    {'emoji': '👩‍🎨', 'name': 'Creative'},
    {'emoji': '🧑‍🏫', 'name': 'Teacher'},
    {'emoji': '👨‍⚕️', 'name': 'Healthcare'},
    {'emoji': '👩‍🚀', 'name': 'Explorer'},
    {'emoji': '🧑‍💻', 'name': 'Developer'},
    {'emoji': '👨‍🎨', 'name': 'Designer'},
    {'emoji': '👩‍🔧', 'name': 'Engineer'},
    {'emoji': '🧑‍🍳', 'name': 'Chef'},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserProfile();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
            _nameController.text = data['name'] ?? user.displayName ?? 'Your Name';
            _mobileController.text = data['mobile'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _addressController.text = data['address'] ?? '';
            _selectedAvatar = data['avatar'] ?? '👨‍💼';
            _displayName = data['name'] ?? user.displayName ?? 'Your Name';
            _totalTrips = data['totalTrips'] ?? 0;
            _moneySaved = (data['moneySaved'] ?? 0.0).toDouble();
            _carbonFootprint = data['carbonFootprint'] ?? 0;
            _isLoading = false;
          });
        } else {
          // Initialize with default values
          setState(() {
            _nameController.text = user.displayName ?? 'Your Name';
            _emailController.text = user.email ?? '';
            _displayName = user.displayName ?? 'Your Name';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading profile: $e', isError: true);
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
        final profileData = {
          'name': _nameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'avatar': _selectedAvatar,
          'totalTrips': _totalTrips,
          'moneySaved': _moneySaved,
          'carbonFootprint': _carbonFootprint,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));

        // Save to SharedPreferences for quick access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar', _selectedAvatar);
        await prefs.setString('user_name', _nameController.text.trim());

        setState(() {
          _displayName = _nameController.text.trim();
          _isEditing = false;
          _isLoading = false;
        });

        _showSnackBar('Profile saved successfully!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error saving profile: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: 'My Profile',
      actions: [
        IconButton(
          icon: Icon(_isEditing ? Icons.close : Icons.edit),
          onPressed: () {
            setState(() {
              _isEditing = !_isEditing;
              if (!_isEditing) {
                // Reset fields when canceling edit
                _loadUserProfile();
              }
            });
          },
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 30),
                        _buildStatisticsRow(),
                        const SizedBox(height: 30),
                        _buildPersonalInformation(),
                        const SizedBox(height: 30),
                        if (_isEditing) ...[
                          _buildAvatarSelector(),
                          const SizedBox(height: 30),
                          _buildSaveButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.getPrimaryTextColor(context).withOpacity(0.3),
                  width: 3,
                ),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _selectedAvatar,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: () => _showAvatarBottomSheet(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _displayName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.getPrimaryTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Text(
            'Active Member',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.directions_bus,
            value: _totalTrips.toString(),
            label: 'Trips',
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.savings,
            value: '₹${_moneySaved.toStringAsFixed(0)}',
            label: 'Saved',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.eco,
            value: '${_carbonFootprint}kg',
            label: 'CO₂ Saved',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getPrimaryTextColor(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _mobileController,
            label: 'Mobile Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty == true) return null;
              if (value!.length < 10) return 'Enter valid mobile number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty == true) return 'Email is required';
              if (!value!.contains('@')) return 'Enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: AppTheme.getPrimaryTextColor(context),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: _isEditing 
              ? Colors.transparent 
              : AppTheme.getSecondaryTextColor(context).withOpacity(0.05),
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Avatar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = _avatarOptions[index];
              final isSelected = avatar['emoji'] == _selectedAvatar;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar['emoji']!;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      avatar['emoji']!,
                      style: const TextStyle(fontSize: 32),
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

  void _showAvatarBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Your Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _avatarOptions.length,
              itemBuilder: (context, index) {
                final avatar = _avatarOptions[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar['emoji']!;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatar['emoji']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
