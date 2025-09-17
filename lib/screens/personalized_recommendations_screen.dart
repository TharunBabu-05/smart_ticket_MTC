import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_preferences_model.dart';
import '../services/personalization_service.dart';
import '../services/voice_multilingual_service.dart';
import '../screens/simple_voice_booking_screen.dart';
import '../screens/ticket_booking_screen.dart';

/// Personalized Travel Recommendations Screen
class PersonalizedRecommendationsScreen extends StatefulWidget {
  @override
  _PersonalizedRecommendationsScreenState createState() => _PersonalizedRecommendationsScreenState();
}

class _PersonalizedRecommendationsScreenState extends State<PersonalizedRecommendationsScreen> {
  final PersonalizationService _personalizationService = PersonalizationService.instance;
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  
  List<TravelRecommendation> _recommendations = [];
  List<FavoriteRoute> _favoriteRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _voiceService.initialize();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      _recommendations = _personalizationService.getTravelRecommendations();
      _favoriteRoutes = _personalizationService.getFavoriteRoutes();
      
      // Add more contextual recommendations
      _addContextualRecommendations();
    } catch (e) {
      print('Error loading recommendations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addContextualRecommendations() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    final hour = now.hour;

    // Weekend recommendations
    if (dayOfWeek >= 6) {
      _recommendations.add(TravelRecommendation(
        title: 'Weekend Explorer',
        description: 'Visit Marina Beach or T Nagar for weekend shopping',
        route: null,
        type: RecommendationType.locationBasedSuggestion,
        confidence: 0.8,
      ));
    }

    // Rush hour recommendations
    if ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20)) {
      _recommendations.add(TravelRecommendation(
        title: 'Beat the Rush',
        description: 'Consider traveling 30 minutes earlier or later to avoid crowds',
        route: null,
        type: RecommendationType.timeBasedSuggestion,
        confidence: 0.75,
      ));
    }

    // Cost optimization
    if (_favoriteRoutes.isNotEmpty) {
      final mostExpensive = _favoriteRoutes.reduce((a, b) => 
          a.estimatedFare > b.estimatedFare ? a : b);
      _recommendations.add(TravelRecommendation(
        title: 'Cost Optimizer',
        description: 'Consider alternative routes to reduce fare by up to ₹5',
        route: mostExpensive,
        type: RecommendationType.costOptimization,
        confidence: 0.6,
      ));
    }

    // New route suggestions
    final popularRoutes = [
      'Chennai Central → T Nagar',
      'Adyar → Marina Beach',
      'Koyambedu → Airport',
      'Anna Nagar → Guindy',
    ];

    final userRoutes = _favoriteRoutes.map((r) => r.routeName).toSet();
    final newRoutes = popularRoutes.where((route) => !userRoutes.contains(route)).toList();

    if (newRoutes.isNotEmpty) {
      _recommendations.add(TravelRecommendation(
        title: 'Explore New Routes',
        description: 'Try ${newRoutes.first} - popular among other users',
        route: null,
        type: RecommendationType.newRoute,
        confidence: 0.5,
      ));
    }
  }

  Widget _buildRecommendationCard(TravelRecommendation recommendation) {
    final colors = _getRecommendationColors(recommendation.type);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [colors.first.withOpacity(0.1), colors.first.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.first.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRecommendationIcon(recommendation.type),
                      color: colors.first,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getRecommendationTypeLabel(recommendation.type),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.first,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(recommendation.confidence).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(recommendation.confidence * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getConfidenceColor(recommendation.confidence),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Description
              Text(
                recommendation.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              // Route info if available
              if (recommendation.route != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.first.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.route, color: colors.first, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation.route!.routeName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colors.first,
                              ),
                            ),
                            Text(
                              '₹${recommendation.route!.estimatedFare.toStringAsFixed(2)} • Used ${recommendation.route!.usageCount}x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  if (recommendation.route != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bookRecommendedRoute(recommendation.route!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.first,
                          foregroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number, size: 16),
                            SizedBox(width: 4),
                            Text('Book Now'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _dismissRecommendation(recommendation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.first,
                        side: BorderSide(color: colors.first),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, size: 16),
                          SizedBox(width: 4),
                          Text('Dismiss'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getRecommendationColors(RecommendationType type) {
    switch (type) {
      case RecommendationType.frequentRoute:
        return [Colors.blue, Colors.blueAccent];
      case RecommendationType.timeBasedSuggestion:
        return [Colors.orange, Colors.orangeAccent];
      case RecommendationType.locationBasedSuggestion:
        return [Colors.green, Colors.lightGreen];
      case RecommendationType.costOptimization:
        return [Colors.purple, Colors.purpleAccent];
      case RecommendationType.newRoute:
        return [Colors.teal, Colors.tealAccent];
    }
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.frequentRoute:
        return Icons.history;
      case RecommendationType.timeBasedSuggestion:
        return Icons.schedule;
      case RecommendationType.locationBasedSuggestion:
        return Icons.location_on;
      case RecommendationType.costOptimization:
        return Icons.savings;
      case RecommendationType.newRoute:
        return Icons.explore;
    }
  }

  String _getRecommendationTypeLabel(RecommendationType type) {
    switch (type) {
      case RecommendationType.frequentRoute:
        return 'Based on your travel history';
      case RecommendationType.timeBasedSuggestion:
        return 'Time-based suggestion';
      case RecommendationType.locationBasedSuggestion:
        return 'Popular destinations nearby';
      case RecommendationType.costOptimization:
        return 'Save money';
      case RecommendationType.newRoute:
        return 'Discover new places';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _bookRecommendedRoute(FavoriteRoute route) async {
    final bookingMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book Recommended Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route: ${route.routeName}'),
            Text('Estimated Fare: ₹${route.estimatedFare.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            Text('How would you like to book?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('voice'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Voice Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('manual'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Manual Booking'),
          ),
        ],
      ),
    );

    if (bookingMethod == 'voice') {
      await _voiceService.speak('Opening voice booking for ${route.routeName}');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SimpleVoiceBookingScreen(),
        ),
      );
    } else if (bookingMethod == 'manual') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TicketBookingScreen(),
        ),
      );
    }
  }

  Future<void> _dismissRecommendation(TravelRecommendation recommendation) async {
    setState(() {
      _recommendations.remove(recommendation);
    });
    
    await _voiceService.speak('Recommendation dismissed');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recommendation dismissed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _recommendations.insert(0, recommendation);
            });
          },
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    if (_favoriteRoutes.isEmpty) return Container();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.insights, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text(
                'Travel Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildInsightCard(
                'Most Used Route',
                _favoriteRoutes.first.routeName,
                Icons.trending_up,
                Colors.blue,
              ),
              SizedBox(width: 12),
              _buildInsightCard(
                'Average Fare',
                '₹${(_favoriteRoutes.map((r) => r.estimatedFare).reduce((a, b) => a + b) / _favoriteRoutes.length).toStringAsFixed(2)}',
                Icons.monetization_on,
                Colors.green,
              ),
              SizedBox(width: 12),
              _buildInsightCard(
                'Total Routes',
                _favoriteRoutes.length.toString(),
                Icons.route,
                Colors.orange,
              ),
              SizedBox(width: 12),
              _buildInsightCard(
                'This Week',
                _getThisWeekTrips(),
                Icons.calendar_today,
                Colors.purple,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              Spacer(),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward, color: color, size: 12),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getThisWeekTrips() {
    final thisWeek = DateTime.now().subtract(Duration(days: 7));
    final recentTrips = _favoriteRoutes
        .where((route) => route.lastUsed.isAfter(thisWeek))
        .length;
    return recentTrips.toString();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No Recommendations Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Start using the app to get personalized travel recommendations!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TicketBookingScreen(),
                  ),
                );
              },
              icon: Icon(Icons.confirmation_number),
              label: Text('Book Your First Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Recommendations'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRecommendations,
          ),
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _voiceService.speak('Personalized travel recommendations'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _recommendations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecommendations,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInsightsSection(),
                        
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.recommend, color: Colors.green.shade600),
                              SizedBox(width: 8),
                              Text(
                                'Recommendations for You',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _recommendations.length,
                          itemBuilder: (context, index) {
                            return _buildRecommendationCard(_recommendations[index]);
                          },
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Tips Section
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Card(
                            color: Colors.blue[50],
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tips_and_updates, color: Colors.blue[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        'Smart Travel Tips',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '• Travel during off-peak hours to avoid crowds\n'
                                    '• Use voice booking for faster ticket purchases\n'
                                    '• Add frequent routes to favorites for quick access\n'
                                    '• Check analytics to optimize your travel budget',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 100), // Space for bottom navigation
                      ],
                    ),
                  ),
                ),
    );
  }
}