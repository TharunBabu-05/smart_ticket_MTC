import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'map_screen.dart';
import 'simple_map_test.dart';
import 'ticket_booking_screen.dart';
import 'conductor_verification_screen.dart'; // Now AdminDashboardScreen
import 'active_trips_screen.dart';
import 'active_tickets_screen.dart';
import '../models/trip_data_model.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TripData> _activeTrips = [];
  bool _isLoadingTrips = true;

  @override
  void initState() {
    super.initState();
    _loadActiveTrips();
  }

  Future<void> _loadActiveTrips() async {
    try {
      // In production, get actual user ID from authentication
      String userId = 'user_123';
      List<TripData> trips = await FirebaseService.getUserActiveTrips(userId);
      
      if (mounted) {
        setState(() {
          _activeTrips = trips;
          _isLoadingTrips = false;
        });
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1DB584),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Row(
          children: [
            const Icon(Icons.directions_bus, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Smart Ticket',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildTicketOptions(context),
            _buildMapSection(context),
            _buildTicketSections(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Where do you want to go?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketOptions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTicketCard(
              context,
              'Bus Ticket',
              Icons.directions_bus,
              Colors.black,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TicketBookingScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTicketCard(
              context,
              'Monthly Pass',
              Icons.calendar_month,
              Colors.black,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TicketBookingScreen()),
              ),
              isNew: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTicketCard(
              context,
              'Active Tickets',
              Icons.confirmation_number,
              Colors.black,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActiveTicketsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, {bool isNew = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.lightBlue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (isNew)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              'Smart Ticket Wallet',
              'Activate',
              const Color(0xFF1976D2),
              Colors.white,
              () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              'Route info',
              '',
              Colors.lightBlue[50]!,
              Colors.black,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              ),
              icon: Icons.route,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              'Test Map',
              '',
              Colors.lightBlue[50]!,
              Colors.black,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SimpleMapTest()),
              ),
              icon: Icons.map,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              'Demo Test',
              'Cross Platform',
              Colors.purple[50]!,
              Colors.black,
              () => Navigator.pushNamed(context, '/demo'),
              icon: Icons.science,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, Color backgroundColor, Color textColor, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, color: textColor, size: 24)
            else
              Icon(Icons.account_balance_wallet, color: textColor, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSections() {
    return Column(
      children: [
        _buildTicketSection('Bus Ticket', 'Your bus ticket will be available here.'),
        _buildTicketSection('Bus Pass', 'Your bus pass will be available here.'),
        _buildTicketSection('Monthly Pass', 'Your monthly pass will be available here.'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTicketSection(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            'View all tickets',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1DB584),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.near_me),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Around me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help',
          ),
        ],
        onTap: (index) {
          if (index == 1 || index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConductorVerificationScreen()),
            );
          }
        },
      ),
    );
  }
}
