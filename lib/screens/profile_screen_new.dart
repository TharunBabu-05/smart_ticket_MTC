import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'support_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  late AnimationController _avatarController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Default user data for demo purposes
  final Map<String, dynamic> _defaultUserData = {
    'name': 'Smart Ticket User',
    'phone': '+91 98765 43210',
    'email': 'user@smartticket.com',
    'ticketsBooked': 42,
    'totalTrips': 128,
    'memberSince': '2024',
    'preferredLanguage': 'English',
    'occupation': 'Professional',
    'age': 28,
    'city': 'Chennai',
    'favoriteBusRoute': 'Route 27 - T.Nagar to Airport',
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _avatarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _avatarController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            userData = {..._defaultUserData, ...doc.data()!};
            isLoading = false;
          });
        } else {
          // User document doesn't exist, use default data
          setState(() {
            userData = _defaultUserData;
            isLoading = false;
          });
        }
      } else {
        // No user signed in, use default data for demo
        setState(() {
          userData = _defaultUserData;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userData = _defaultUserData; // Fallback to default data
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Enhanced App Bar with Gradient
                SliverAppBar(
                  expandedHeight: 240,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF1DB584),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1DB584),
                            Color(0xFF159F6E),
                            Color(0xFF0E7A55),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Animated Profile Picture
                            AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(_pulseAnimation.value),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.white,
                                          child: CircleAvatar(
                                            radius: 46,
                                            backgroundColor: const Color(0xFF0E7A55),
                                            child: Text(
                                              userData?['name']?.substring(0, 1).toUpperCase() ?? 'S',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // User Name
                            Text(
                              userData?['name'] ?? 'Smart Ticket User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Phone Number
                            Text(
                              userData?['phone'] ?? '+91 98765 43210',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Member Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Member since ${userData?['memberSince'] ?? '2024'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _logout();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Profile Details Content
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Stats Cards
                      _buildStatsSection(),
                      const SizedBox(height: 20),
                      // Personal Information
                      _buildPersonalInfoSection(),
                      const SizedBox(height: 20),
                      // Travel Information  
                      _buildTravelInfoSection(),
                      const SizedBox(height: 20),
                      // Menu Items
                      _buildMenuSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Stats Section with Travel Statistics
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Travel Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.confirmation_number,
                  value: '${userData?['ticketsBooked'] ?? 42}',
                  label: 'Tickets\nBooked',
                  color: const Color(0xFF1DB584),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.directions_bus,
                  value: '${userData?['totalTrips'] ?? 128}',
                  label: 'Total\nTrips',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.eco,
                  value: '2.4kg',
                  label: 'CO₂\nSaved',
                  color: Colors.green,
                ),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Personal Information Section
  Widget _buildPersonalInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Full Name', userData?['name'] ?? 'Smart Ticket User'),
          _buildInfoRow(Icons.phone, 'Phone', userData?['phone'] ?? '+91 98765 43210'),
          _buildInfoRow(Icons.email, 'Email', userData?['email'] ?? 'user@smartticket.com'),
          _buildInfoRow(Icons.cake, 'Age', '${userData?['age'] ?? 28} years'),
          _buildInfoRow(Icons.work, 'Occupation', userData?['occupation'] ?? 'Professional'),
          _buildInfoRow(Icons.language, 'Language', userData?['preferredLanguage'] ?? 'English'),
        ],
      ),
    );
  }

  // Travel Information Section
  Widget _buildTravelInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Travel Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_city, 'City', userData?['city'] ?? 'Chennai'),
          _buildInfoRow(Icons.route, 'Favorite Route', userData?['favoriteBusRoute'] ?? 'Route 27 - T.Nagar to Airport'),
          _buildInfoRow(Icons.schedule, 'Member Since', userData?['memberSince'] ?? '2024'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF1DB584),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Menu Section
  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.confirmation_number,
            title: 'My Tickets',
            subtitle: 'View booking history',
            color: const Color(0xFF1DB584),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('My Tickets - Coming Soon')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.card_membership,
            title: 'My Passes',
            subtitle: 'Monthly & weekly passes',
            color: Colors.orange,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('My Passes - Coming Soon')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.share,
            title: 'Share App',
            subtitle: 'Invite friends to join',
            color: Colors.blue,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share App - Coming Soon')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.star_rate,
            title: 'Rate Us',
            subtitle: 'Help us improve',
            color: Colors.amber,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rate Us - Coming Soon')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.support_agent,
            title: 'Contact Support',
            subtitle: 'Get help & assistance',
            color: const Color(0xFF1DB584),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
