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
  String _selectedAvatar = 'assets/avatars/InShot_20250919_180526249.jpg';
  String _displayName = 'Your Name';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Profile statistics
  int _totalTrips = 0;
  double _moneySaved = 0.0;
  int _carbonFootprint = 0;
  int _weeklyTrips = 0;
  int _monthlyTrips = 0;
  String _favoriteRoute = '';
  double _averageTripCost = 0.0;
  int _totalDistance = 0;
  DateTime? _lastTripDate;
  List<String> _achievements = [];
  String _membershipLevel = 'Bronze';
  int _streakDays = 0;
  Map<String, int> _travelPatterns = {};
  int _pointsEarned = 0;
  
  // Avatar options with image paths and names
  final List<Map<String, String>> _avatarOptions = [
    {'path': 'assets/avatars/InShot_20250919_180526249.jpg', 'name': 'Professional'},
    {'path': 'assets/avatars/InShot_20250919_180639450.jpg', 'name': 'Business'},
    {'path': 'assets/avatars/InShot_20250919_180718284.jpg', 'name': 'Creative'},
    {'path': 'assets/avatars/InShot_20250919_180838567.jpg', 'name': 'Casual'},
    {'path': 'assets/avatars/InShot_20250919_180956931.jpg', 'name': 'Modern'},
    {'path': 'assets/avatars/InShot_20250919_181019878.jpg', 'name': 'Classic'},
    {'path': 'assets/avatars/InShot_20250919_181038259.jpg', 'name': 'Trendy'},
    {'path': 'assets/avatars/InShot_20250919_181119407.jpg', 'name': 'Explorer'},
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
            _selectedAvatar = data['avatar'] ?? 'assets/avatars/InShot_20250919_180526249.jpg';
            _displayName = data['name'] ?? user.displayName ?? 'Your Name';
            _totalTrips = data['totalTrips'] ?? 0;
            _moneySaved = (data['moneySaved'] ?? 0.0).toDouble();
            _carbonFootprint = data['carbonFootprint'] ?? 0;
            _weeklyTrips = data['weeklyTrips'] ?? 0;
            _monthlyTrips = data['monthlyTrips'] ?? 0;
            _favoriteRoute = data['favoriteRoute'] ?? '';
            _averageTripCost = (data['averageTripCost'] ?? 0.0).toDouble();
            _totalDistance = data['totalDistance'] ?? 0;
            _lastTripDate = data['lastTripDate'] != null ? (data['lastTripDate'] as Timestamp).toDate() : null;
            _achievements = List<String>.from(data['achievements'] ?? []);
            _membershipLevel = data['membershipLevel'] ?? 'Bronze';
            _streakDays = data['streakDays'] ?? 0;
            _travelPatterns = Map<String, int>.from(data['travelPatterns'] ?? {});
            _pointsEarned = data['pointsEarned'] ?? 0;
            _isLoading = false;
          });
        } else {
          // Initialize with default values and some sample data for demonstration
          setState(() {
            _nameController.text = user.displayName ?? 'Your Name';
            _emailController.text = user.email ?? '';
            _displayName = user.displayName ?? 'Your Name';
            // Add some sample data for demonstration
            _totalTrips = 42;
            _moneySaved = 1250.0;
            _carbonFootprint = 28;
            _weeklyTrips = 8;
            _monthlyTrips = 32;
            _favoriteRoute = 'Chennai Central to T.Nagar';
            _averageTripCost = 15.0;
            _totalDistance = 340;
            _lastTripDate = DateTime.now().subtract(const Duration(days: 1));
            _achievements = ['First Ride', 'Eco Warrior'];
            _membershipLevel = 'Silver';
            _streakDays = 5;
            _travelPatterns = {
              'Morning': 15,
              'Evening': 12,
              'Afternoon': 8,
              'Night': 7,
            };
            _pointsEarned = 2840;
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
          'weeklyTrips': _weeklyTrips,
          'monthlyTrips': _monthlyTrips,
          'favoriteRoute': _favoriteRoute,
          'averageTripCost': _averageTripCost,
          'totalDistance': _totalDistance,
          'lastTripDate': _lastTripDate,
          'achievements': _achievements,
          'membershipLevel': _membershipLevel,
          'streakDays': _streakDays,
          'travelPatterns': _travelPatterns,
          'pointsEarned': _pointsEarned,
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
                        _buildStatisticsGrid(),
                        const SizedBox(height: 30),
                        _buildAchievementsBadges(),
                        const SizedBox(height: 30),
                        _buildTravelInsights(),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  _selectedAvatar,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    );
                  },
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getMembershipColor().withOpacity(0.2),
                _getMembershipColor().withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getMembershipColor().withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getMembershipIcon(),
                color: _getMembershipColor(),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '$_membershipLevel Member',
                style: TextStyle(
                  color: _getMembershipColor(),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (_streakDays > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange[700], size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_streakDays day streak',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getMembershipColor() {
    switch (_membershipLevel) {
      case 'Bronze':
        return Colors.brown;
      case 'Silver':
        return Colors.grey;
      case 'Gold':
        return Colors.amber;
      case 'Platinum':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  IconData _getMembershipIcon() {
    switch (_membershipLevel) {
      case 'Bronze':
        return Icons.workspace_premium;
      case 'Silver':
        return Icons.workspace_premium;
      case 'Gold':
        return Icons.workspace_premium;
      case 'Platinum':
        return Icons.diamond;
      default:
        return Icons.card_membership;
    }
  }

  Widget _buildStatisticsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Travel Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                icon: Icons.directions_bus,
                value: _totalTrips.toString(),
                label: 'Total Trips',
                color: Colors.blue,
                subtitle: 'All time',
              ),
              _buildStatCard(
                icon: Icons.savings,
                value: '₹${_moneySaved.toStringAsFixed(0)}',
                label: 'Money Saved',
                color: Colors.green,
                subtitle: 'vs private transport',
              ),
              _buildStatCard(
                icon: Icons.eco,
                value: '${_carbonFootprint}kg',
                label: 'CO₂ Saved',
                color: Colors.orange,
                subtitle: 'Environmental impact',
              ),
              _buildStatCard(
                icon: Icons.stars,
                value: _pointsEarned.toString(),
                label: 'Points Earned',
                color: Colors.purple,
                subtitle: 'Loyalty rewards',
              ),
              _buildStatCard(
                icon: Icons.timeline,
                value: _weeklyTrips.toString(),
                label: 'This Week',
                color: Colors.indigo,
                subtitle: 'Weekly trips',
              ),
              _buildStatCard(
                icon: Icons.route,
                value: '${_totalDistance}km',
                label: 'Distance',
                color: Colors.teal,
                subtitle: 'Total traveled',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(context),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementsBadges() {
    // Sample achievements - in a real app, these would come from user data
    final List<Map<String, dynamic>> achievements = [
      {
        'icon': Icons.directions_bus,
        'title': 'First Ride',
        'description': 'Completed your first journey',
        'earned': _totalTrips > 0,
        'color': Colors.blue,
      },
      {
        'icon': Icons.eco_outlined,
        'title': 'Eco Warrior',
        'description': 'Saved 10kg CO₂',
        'earned': _carbonFootprint >= 10,
        'color': Colors.green,
      },
      {
        'icon': Icons.savings,
        'title': 'Money Saver',
        'description': 'Saved ₹500',
        'earned': _moneySaved >= 500,
        'color': Colors.amber,
      },
      {
        'icon': Icons.local_fire_department,
        'title': 'Streak Master',
        'description': '7-day travel streak',
        'earned': _streakDays >= 7,
        'color': Colors.orange,
      },
      {
        'icon': Icons.star,
        'title': 'VIP Traveler',
        'description': '50+ trips completed',
        'earned': _totalTrips >= 50,
        'color': Colors.purple,
      },
      {
        'icon': Icons.explore,
        'title': 'Explorer',
        'description': 'Visited 10+ routes',
        'earned': _travelPatterns.length >= 10,
        'color': Colors.teal,
      },
    ];

    final earnedAchievements = achievements.where((a) => a['earned'] as bool).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${earnedAchievements.length}/${achievements.length}',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (earnedAchievements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.getSecondaryTextColor(context).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start your journey!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getPrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete trips to earn achievements',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final isEarned = achievement['earned'] as bool;
                  
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isEarned 
                                ? achievement['color'].withOpacity(0.2)
                                : AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isEarned 
                                  ? achievement['color']
                                  : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            achievement['icon'],
                            color: isEarned 
                                ? achievement['color']
                                : AppTheme.getSecondaryTextColor(context),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement['title'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isEarned 
                                ? AppTheme.getPrimaryTextColor(context)
                                : AppTheme.getSecondaryTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          achievement['description'],
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTravelInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Travel Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_favoriteRoute.isNotEmpty) ...[
            _buildInsightItem(
              icon: Icons.favorite,
              title: 'Favorite Route',
              value: _favoriteRoute,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
          ],
          _buildInsightItem(
            icon: Icons.attach_money,
            title: 'Average Trip Cost',
            value: _averageTripCost > 0 ? '₹${_averageTripCost.toStringAsFixed(0)}' : 'Not available',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            icon: Icons.calendar_today,
            title: 'Monthly Trips',
            value: '$_monthlyTrips trips',
            color: Colors.blue,
          ),
          if (_lastTripDate != null) ...[
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.schedule,
              title: 'Last Trip',
              value: _formatLastTripDate(),
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getPrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastTripDate() {
    if (_lastTripDate == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(_lastTripDate!);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(_lastTripDate!.day).toString().padLeft(2, '0')}/${(_lastTripDate!.month).toString().padLeft(2, '0')}/${_lastTripDate!.year}';
    }
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
              final isSelected = avatar['path'] == _selectedAvatar;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar['path']!;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                      width: isSelected ? 3 : 1,
                    ),
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          avatar['path']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 30,
                              ),
                            );
                          },
                        ),
                        if (isSelected)
                          Container(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            child: Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300, // Fixed height for the avatar grid
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  final avatar = _avatarOptions[index];
                  final isSelected = avatar['path'] == _selectedAvatar;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar['path']!;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).primaryColor
                              : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              avatar['path']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                            if (isSelected)
                              Container(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                child: Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an avatar that represents you',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
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
