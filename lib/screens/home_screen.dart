import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'map_screen.dart';
import 'simple_map_test.dart';
import 'ticket_booking_screen.dart';
import 'voice_ticket_booking_screen.dart';
import 'simple_voice_booking_screen.dart';
import 'conductor_verification_screen.dart';
import 'active_trips_screen.dart';
import 'active_tickets_screen.dart';
import 'live_bus_tracking_screen.dart';
import 'enhanced_ticket_screen.dart';
import 'nearby_bus_stops_screen.dart';
import 'chatbot_screen.dart';
import 'enhanced_weather_screen.dart';
import 'usage_analytics_dashboard_screen.dart';
import 'user_manual_screen.dart';
import 'rating/review_list_screen.dart';
import 'rating/review_submission_screen.dart';
import 'weather_based_recommendations_screen.dart';
import 'safety_features_screen.dart';
import 'emergency_sos_screen.dart';
import 'icp_integration_screen.dart';
import '../models/trip_data_model.dart';
import '../models/enhanced_ticket_model.dart';
import '../models/rating_model.dart';
import '../services/fraud_detection_service_new.dart';
import '../services/enhanced_ticket_service.dart';
import '../services/weather_service.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFE91E63), // Beautiful pink from the attachment
              Color(0xFF9C27B0), // Purple transition
              Color(0xFF673AB7), // Deep purple
              Color(0xFF3F51B5), // Indigo
              Color(0xFF2196F3), // Blue from the attachment
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
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
                    _buildWeatherWidget(colorScheme),
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          // Remove the background gradient to blend with main background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black12,
            ],
            stops: [0.0, 1.0],
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 26,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 26,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const UserAvatarWidget(
                          size: 42,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus_filled,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Smart Ticket MTC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '15 Live Buses',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.lightBlueAccent.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '24 Active Routes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 1,
                              ),
                            ],
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
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
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
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
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
                  Icons.confirmation_number_outlined,
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
                      'No Active Tickets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book your first bus ticket to get started',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
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

  Widget _buildWeatherWidget(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF1E40AF),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EnhancedWeatherScreen()),
          ),
          child: FutureBuilder<WeatherData?>(
            future: WeatherService.instance.getCurrentWeather(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildWeatherLoadingState();
              } else if (snapshot.hasError) {
                return _buildWeatherErrorState();
              } else if (snapshot.hasData && snapshot.data != null) {
                return _buildWeatherDataState(snapshot.data!);
              } else {
                return _buildWeatherErrorState();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Loading current conditions...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
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
              Icons.error_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to view weather details',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white70,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDataState(WeatherData weatherData) {
    final temp = weatherData.temperature.round();
    final condition = weatherData.description;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top row with current temp and condition
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large temperature
              Text(
                '$temp°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              // Weather emoji
              Text(
                _getWeatherEmoji(weatherData.icon),
                style: const TextStyle(fontSize: 36),
              ),
              const Spacer(),
              // Arrow indicator
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weather condition and location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Chennai, Tamil Nadu',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Weather details
              Row(
                children: [
                  _buildMiniWeatherDetail(Icons.water_drop, '${weatherData.humidity}%'),
                  const SizedBox(width: 16),
                  _buildMiniWeatherDetail(Icons.air, '${weatherData.windSpeed}km/h'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniWeatherDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getWeatherEmoji(String iconCode) {
    if (iconCode.contains('01')) return '☀️'; // clear sky
    if (iconCode.contains('02')) return '⛅'; // few clouds
    if (iconCode.contains('03') || iconCode.contains('04')) return '☁️'; // clouds
    if (iconCode.contains('09') || iconCode.contains('10')) return '🌧️'; // rain
    if (iconCode.contains('11')) return '⛈️'; // thunderstorm
    if (iconCode.contains('13')) return '❄️'; // snow
    if (iconCode.contains('50')) return '🌫️'; // mist
    return '🌤️'; // default
  }

  String _getWeatherRecommendation(WeatherData weather) {
    if (weather.condition == 'Rain' || weather.condition == 'Drizzle' || weather.condition == 'Thunderstorm') {
      return 'AC BUSES RECOMMENDED';
    }
    if (weather.temperature > 35) {
      return 'STAY COOL - USE AC';
    }
    if (weather.temperature < 15) {
      return 'WRAP UP WARM';
    }
    if (weather.condition == 'Clear' && weather.temperature >= 20 && weather.temperature <= 30) {
      return 'PERFECT WEATHER';
    }
    return 'WEATHER-SMART ROUTES';
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                    Colors.cyan.shade500,
                    Colors.blue.shade800,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LiveBusTrackingScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_bus_filled,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Bus Tracking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Track buses in real-time on interactive map',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '🚌 LIVE NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
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
            
            // Safety Features Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                    Colors.pink.shade500,
                    Colors.red.shade800,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SafetyFeaturesScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Safety Features',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Emergency SOS • Live Location • Women Safety',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '🛡️ YOUR SAFETY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
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
            
            // ICP Blockchain Integration Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                    Colors.indigo.shade500,
                    Colors.deepPurple.shade800,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ICPIntegrationScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.currency_bitcoin,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ICP Blockchain',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Decentralized Tickets • Internet Identity • ICP Payments',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '⛓️ BLOCKCHAIN POWERED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.star_rounded,
                    title: 'Rate Services',
                    subtitle: 'Share your experience',
                    color: Colors.orange.shade500,
                    onTap: () => _showRatingOptions(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.reviews_rounded,
                    title: 'View Reviews',
                    subtitle: 'Community feedback',
                    color: Colors.indigo.shade500,
                    onTap: () => _showReviewsOptions(),
                  ),
                ),
              ],
            ),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.map_rounded,
                    title: 'Find Routes',
                    subtitle: 'Bus routes & stops',
                    color: Colors.teal.shade500,
                    onTap: () => Navigator.pushNamed(context, '/map'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.location_on_rounded,
                    title: 'Nearby Stops',
                    subtitle: 'Within 5 KM',
                    color: Colors.purple.shade500,
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
                    icon: Icons.mic,
                    title: 'Voice Booking',
                    subtitle: 'Speak to book tickets',
                    color: Colors.green.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SimpleVoiceBookingScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.emergency,
                    title: 'Emergency SOS',
                    subtitle: 'Quick emergency alert',
                    color: Colors.red.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmergencySOSScreen()),
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
                    icon: Icons.analytics,
                    title: 'Analytics',
                    subtitle: 'Travel insights',
                    color: Colors.purple.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UsageAnalyticsDashboardScreen()),
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
                  child: Container(), // Empty space for balance
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.smart_toy,
                    title: 'AI Assistant',
                    subtitle: 'Chat for help',
                    color: Colors.purple.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.menu_book,
                    title: 'User Manual',
                    subtitle: 'Complete guide',
                    color: Colors.teal.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserManualScreen()),
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
                    icon: Icons.support_agent_rounded,
                    title: 'Support',
                    subtitle: 'Help & feedback',
                    color: Colors.indigo.shade600,
                    onTap: () => Navigator.pushNamed(context, '/support'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    color: Colors.deepPurple.shade600,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
              color.withOpacity(0.8),
              color.withOpacity(1.0),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 3,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B6B), // Coral pink
            Color(0xFFE91E63), // Pink
            Color(0xFF9C27B0), // Purple
            Color(0xFF673AB7), // Deep purple
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/booking'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(
          Icons.confirmation_number_rounded, 
          size: 26,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        label: const Text(
          'Book Ticket',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomAppBar(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
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
              icon: Icons.smart_toy,
              label: 'Assistant',
              isSelected: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              ),
              colorScheme: colorScheme,
            ),
            _buildNavItem(
              icon: Icons.help_outline,
              label: 'Manual',
              isSelected: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManualScreen()),
              ),
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

  void _showRatingOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Bus Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help improve public transport by sharing your experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildRatingOption(
              icon: Icons.directions_bus,
              title: 'Rate Bus Service',
              subtitle: 'Overall bus experience',
              onTap: () {
                Navigator.pop(context);
                _rateBusService();
              },
            ),
            
            _buildRatingOption(
              icon: Icons.route,
              title: 'Rate Route',
              subtitle: 'Route efficiency & coverage',
              onTap: () {
                Navigator.pop(context);
                _rateRoute();
              },
            ),
            
            _buildRatingOption(
              icon: Icons.person,
              title: 'Rate Driver',
              subtitle: 'Driver behavior & service',
              onTap: () {
                Navigator.pop(context);
                _rateDriver();
              },
            ),
            
            _buildRatingOption(
              icon: Icons.location_on,
              title: 'Rate Bus Stop',
              subtitle: 'Station facilities & cleanliness',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NearbyBusStopsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewsOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browse Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'See what others are saying about bus services',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildRatingOption(
              icon: Icons.directions_bus,
              title: 'Bus Service Reviews',
              subtitle: 'Read bus service feedback',
              onTap: () {
                Navigator.pop(context);
                _viewBusServiceReviews();
              },
            ),
            
            _buildRatingOption(
              icon: Icons.route,
              title: 'Route Reviews',
              subtitle: 'Route efficiency feedback',
              onTap: () {
                Navigator.pop(context);
                _viewRouteReviews();
              },
            ),
            
            _buildRatingOption(
              icon: Icons.person,
              title: 'Driver Reviews',
              subtitle: 'Driver service feedback',
              onTap: () {
                Navigator.pop(context);
                _viewDriverReviews();
              },
            ),
            
            _buildRatingOption(
              icon: Icons.location_on,
              title: 'Station Reviews',
              subtitle: 'Bus stop reviews & ratings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NearbyBusStopsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _rateBusService() {
    _showServiceInputDialog('Rate Bus Service', 'Enter bus number', ReviewType.busService);
  }

  void _rateRoute() {
    _showServiceInputDialog('Rate Route', 'Enter route number', ReviewType.route);
  }

  void _rateDriver() {
    _showServiceInputDialog('Rate Driver', 'Enter driver ID or bus number', ReviewType.driver);
  }

  void _viewBusServiceReviews() {
    _showServiceInputDialog('View Bus Service Reviews', 'Enter bus number', ReviewType.busService, isReview: true);
  }

  void _viewRouteReviews() {
    _showServiceInputDialog('View Route Reviews', 'Enter route number', ReviewType.route, isReview: true);
  }

  void _viewDriverReviews() {
    _showServiceInputDialog('View Driver Reviews', 'Enter driver ID or bus number', ReviewType.driver, isReview: true);
  }

  void _showServiceInputDialog(String title, String hint, ReviewType reviewType, {bool isReview = false}) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hint),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'e.g., DL1PC5234, Route 52A',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                if (isReview) {
                  _navigateToReviewList(controller.text.trim(), reviewType);
                } else {
                  _navigateToRatingSubmission(controller.text.trim(), reviewType);
                }
              }
            },
            child: Text(isReview ? 'View Reviews' : 'Rate Service'),
          ),
        ],
      ),
    );
  }

  void _navigateToRatingSubmission(String serviceId, ReviewType reviewType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewSubmissionScreen(
          serviceId: serviceId,
          reviewType: reviewType,
          serviceName: serviceId,
        ),
      ),
    );
  }

  void _navigateToReviewList(String serviceId, ReviewType reviewType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewListScreen(
          serviceId: serviceId,
          reviewType: reviewType,
          serviceName: serviceId,
        ),
      ),
    );
  }
}
