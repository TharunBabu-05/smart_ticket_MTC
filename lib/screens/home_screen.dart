import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'map_screen.dart';
import 'simple_map_test.dart';
import 'ticket_booking_screen.dart';
import 'conductor_verification_screen.dart';
import 'active_trips_screen.dart';
import 'active_tickets_screen.dart';
import 'live_bus_tracking_screen.dart';
import 'enhanced_ticket_screen.dart';
import 'nearby_bus_stops_screen.dart';
import '../models/trip_data_model.dart';
import '../models/enhanced_ticket_model.dart';
import '../services/fraud_detection_service_new.dart';
import '../services/enhanced_ticket_service.dart';
import '../widgets/user_avatar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<TripData> _activeTrips = [];
  List<EnhancedTicket> _activeTickets = [];
  bool _isLoadingTrips = true;
  bool _isLoadingTickets = true;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  String _greeting = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _loadActiveTrips();
    _loadActiveTickets();
    _loadUserInfo();
    _setGreeting();
    
    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadActiveTickets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<EnhancedTicket> tickets = await EnhancedTicketService.getUserActiveTickets(user.uid);
        
        if (mounted) {
          setState(() {
            _activeTickets = tickets;
            _isLoadingTickets = false;
          });
        }
      }
    } catch (e) {
      print('Error loading active tickets: $e');
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

  Future<void> _loadActiveTrips() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<TripData> trips = await FraudDetectionService.getUserActiveTrips(user.uid);
        
        if (mounted) {
          setState(() {
            _activeTrips = trips;
            _isLoadingTrips = false;
          });
        }
      }
    } catch (e) {
      print('Error loading active trips: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrips = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadActiveTrips();
            await _loadActiveTickets();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 
                          kBottomNavigationBarHeight - 60, // Account for bottom nav + FAB
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(colorScheme),
                  _buildActiveTicketCard(colorScheme),
                  _buildQuickActions(colorScheme),
                  _buildNearbyStops(colorScheme),
                  _buildRecentActivity(colorScheme),
                  const SizedBox(height: 120), // Increased space for bottom nav + FAB
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
      floatingActionButton: _buildBookTicketFAB(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userName,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                      icon: Icon(
                        Icons.settings_outlined,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: colorScheme.onPrimary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: UserAvatarWidget(
                          size: 40,
                          showName: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus_filled,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Smart Ticket MTC',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Live Bus Status Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '15 Live Buses',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '24 Active Routes',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTicketCard(ColorScheme colorScheme) {
    if (_isLoadingTickets) {
      return Container(
        margin: const EdgeInsets.all(24),
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_activeTickets.isEmpty) {
      return FadeTransition(
        opacity: _fadeController,
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.confirmation_number_outlined,
                  color: colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Active Tickets',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book your first bus ticket to get started',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onPrimaryContainer.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    // Show active ticket
    final ticket = _activeTickets.first;
    final timeRemaining = ticket.validUntil.difference(DateTime.now());
    final hoursRemaining = timeRemaining.inHours;
    final minutesRemaining = timeRemaining.inMinutes % 60;

    return FadeTransition(
      opacity: _fadeController,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnhancedTicketScreen(ticket: ticket),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.confirmation_number,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Ticket',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.sourceName} → ${ticket.destinationName}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${hoursRemaining}h ${minutesRemaining}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fare: ₹${ticket.fare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Tap to view ticket',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
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

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Featured Live Bus Tracking Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade500,
                    Colors.blue.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LiveBusTrackingScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.directions_bus_filled,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Bus Tracking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track buses in real-time on map',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LIVE NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.map_outlined,
                    title: 'Find Routes',
                    subtitle: 'Bus routes & stops',
                    color: colorScheme.tertiary,
                    onTap: () => Navigator.pushNamed(context, '/map'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.location_on,
                    title: 'Nearby Stops',
                    subtitle: 'Within 5 KM',
                    color: Colors.grey.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NearbyBusStopsScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.history,
                    title: 'Trip History',
                    subtitle: 'Past journeys',
                    color: colorScheme.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ActiveTicketsScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.support_agent_outlined,
                    title: 'Support',
                    subtitle: 'Help & feedback',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/support'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    color: Colors.grey.shade600,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(), // Empty space for balance
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Payment Test Card (Development only)
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyStops(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Stops',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/map'),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(right: index < 4 ? 16 : 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bus Stop ${index + 1}',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(index + 1) * 100}m away',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${3 + index} buses',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingTrips)
              const Center(child: CircularProgressIndicator())
            else if (_activeTrips.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trip history will appear here',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeTrips.length > 3 ? 3 : _activeTrips.length,
                itemBuilder: (context, index) {
                  final trip = _activeTrips[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trip.sourceName} → ${trip.destinationName}',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trip ID: ${trip.ticketId.substring(0, 8)}...',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trip.status == TripStatus.active 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trip.status.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: trip.status == TripStatus.active 
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookTicketFAB(ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/booking'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 8,
      icon: const Icon(Icons.confirmation_number, size: 24),
      label: const Text(
        'Book Ticket',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 65, // Fixed height to prevent overflow
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            _buildNavItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: true,
              onTap: () {},
              colorScheme: colorScheme,
            ),
            _buildNavItem(
              icon: Icons.directions_bus_filled,
              label: 'Live Bus',
              isSelected: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LiveBusTrackingScreen()),
              ),
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(
              icon: Icons.history,
              label: 'History',
              isSelected: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ActiveTicketsScreen()),
              ),
              colorScheme: colorScheme,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isSelected: false,
              onTap: () => Navigator.pushNamed(context, '/profile'),
              colorScheme: colorScheme,
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
