import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_preferences_model.dart';
import '../services/personalization_service.dart';
import '../services/voice_multilingual_service.dart';
import '../screens/simple_voice_booking_screen.dart';
import '../screens/ticket_booking_screen.dart';

/// Favorite Routes Management Screen
class FavoriteRoutesScreen extends StatefulWidget {
  @override
  _FavoriteRoutesScreenState createState() => _FavoriteRoutesScreenState();
}

class _FavoriteRoutesScreenState extends State<FavoriteRoutesScreen> {
  final PersonalizationService _personalizationService = PersonalizationService.instance;
  final VoiceMultilingualService _voiceService = VoiceMultilingualService();
  final Uuid _uuid = Uuid();
  
  List<FavoriteRoute> _favoriteRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteRoutes();
    _voiceService.initialize();
  }

  Future<void> _loadFavoriteRoutes() async {
    setState(() => _isLoading = true);
    try {
      _favoriteRoutes = _personalizationService.getFavoriteRoutes();
    } catch (e) {
      print('Error loading favorite routes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewFavoriteRoute() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddFavoriteRouteDialog(),
    );

    if (result != null) {
      final route = FavoriteRoute(
        id: _uuid.v4(),
        routeName: '${result['source']} → ${result['destination']}',
        sourceStation: result['source']!,
        destinationStation: result['destination']!,
        estimatedFare: double.tryParse(result['fare'] ?? '0') ?? 15.0,
        usageCount: 0,
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
        isQuickAccess: result['quickAccess'] == 'true',
      );

      await _personalizationService.addFavoriteRoute(route);
      await _voiceService.speak('Favorite route added successfully');
      await _loadFavoriteRoutes();
    }
  }

  Future<void> _removeFavoriteRoute(FavoriteRoute route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Favorite Route'),
        content: Text('Are you sure you want to remove "${route.routeName}" from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _personalizationService.removeFavoriteRoute(route.id);
      await _voiceService.speak('Favorite route removed');
      await _loadFavoriteRoutes();
    }
  }

  Future<void> _bookFavoriteRoute(FavoriteRoute route) async {
    final bookingMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book Ticket'),
        content: Text('How would you like to book this route?\n\n${route.routeName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('voice'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic),
                SizedBox(width: 4),
                Text('Voice'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('manual'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app),
                SizedBox(width: 4),
                Text('Manual'),
              ],
            ),
          ),
        ],
      ),
    );

    if (bookingMethod == 'voice') {
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

  Future<void> _toggleQuickAccess(FavoriteRoute route) async {
    final updatedRoute = route.copyWith(isQuickAccess: !route.isQuickAccess);
    
    // Remove and re-add to update
    await _personalizationService.removeFavoriteRoute(route.id);
    await _personalizationService.addFavoriteRoute(updatedRoute);
    
    await _loadFavoriteRoutes();
    
    final message = updatedRoute.isQuickAccess 
        ? 'Added to quick access' 
        : 'Removed from quick access';
    await _voiceService.speak(message);
  }

  Widget _buildFavoriteRouteCard(FavoriteRoute route) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.routeName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${route.sourceStation} → ${route.destinationStation}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (route.isQuickAccess)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on, size: 14, color: Colors.blue[600]),
                        SizedBox(width: 4),
                        Text(
                          'Quick',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Route Stats
            Row(
              children: [
                _buildStatChip(Icons.monetization_on, '₹${route.estimatedFare.toStringAsFixed(0)}', Colors.green),
                SizedBox(width: 8),
                _buildStatChip(Icons.history, '${route.usageCount}x used', Colors.orange),
                SizedBox(width: 8),
                _buildStatChip(Icons.access_time, _formatLastUsed(route.lastUsed), Colors.purple),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _bookFavoriteRoute(route),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number, size: 18),
                        SizedBox(width: 8),
                        Text('Book Now'),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => _toggleQuickAccess(route),
                  icon: Icon(
                    route.isQuickAccess ? Icons.flash_on : Icons.flash_off,
                    color: route.isQuickAccess ? Colors.blue[600] : Colors.grey,
                  ),
                  tooltip: route.isQuickAccess ? 'Remove from Quick Access' : 'Add to Quick Access',
                ),
                IconButton(
                  onPressed: () => _removeFavoriteRoute(route),
                  icon: Icon(Icons.delete, color: Colors.red[600]),
                  tooltip: 'Remove from Favorites',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUsed(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildQuickAccessSection() {
    final quickRoutes = _favoriteRoutes.where((route) => route.isQuickAccess).take(3).toList();
    
    if (quickRoutes.isEmpty) return Container();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.flash_on, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text(
                'Quick Access',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: quickRoutes.length,
            itemBuilder: (context, index) {
              final route = quickRoutes[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: 12),
                child: Card(
                  color: Colors.blue[50],
                  child: InkWell(
                    onTap: () => _bookFavoriteRoute(route),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.flash_on, color: Colors.blue[600], size: 20),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  route.sourceStation,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.arrow_forward, color: Colors.grey[600], size: 16),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  route.destinationStation,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${route.estimatedFare.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${route.usageCount}x',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Routes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadFavoriteRoutes,
          ),
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _voiceService.speak('Favorite routes screen'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoriteRoutes.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickAccessSection(),
                      
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red.shade600),
                            SizedBox(width: 8),
                            Text(
                              'All Favorites (${_favoriteRoutes.length})',
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
                        itemCount: _favoriteRoutes.length,
                        itemBuilder: (context, index) {
                          return _buildFavoriteRouteCard(_favoriteRoutes[index]);
                        },
                      ),
                      
                      SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewFavoriteRoute,
        icon: Icon(Icons.add),
        label: Text('Add Route'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No Favorite Routes Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Add your frequently used routes to book tickets faster!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addNewFavoriteRoute,
              icon: Icon(Icons.add),
              label: Text('Add Your First Route'),
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
}

class _AddFavoriteRouteDialog extends StatefulWidget {
  @override
  _AddFavoriteRouteDialogState createState() => _AddFavoriteRouteDialogState();
}

class _AddFavoriteRouteDialogState extends State<_AddFavoriteRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController(text: '15.0');
  bool _isQuickAccess = false;

  final List<String> _popularStations = [
    'Chennai Egmore',
    'Chennai Central',
    'T Nagar',
    'Park Town',
    'Guindy',
    'Adyar',
    'Velachery',
    'Anna Nagar',
    'Vadapalani',
    'Koyambedu',
    'Tambaram',
    'Marina Beach',
    'Airport',
    'Mylapore',
    'Besant Nagar',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Favorite Route'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Source Station
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'From Station',
                  border: OutlineInputBorder(),
                ),
                items: _popularStations
                    .map((station) => DropdownMenuItem(
                          value: station,
                          child: Text(station),
                        ))
                    .toList(),
                onChanged: (value) {
                  _sourceController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select source station';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Destination Station
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'To Station',
                  border: OutlineInputBorder(),
                ),
                items: _popularStations
                    .map((station) => DropdownMenuItem(
                          value: station,
                          child: Text(station),
                        ))
                    .toList(),
                onChanged: (value) {
                  _destinationController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select destination station';
                  }
                  if (value == _sourceController.text) {
                    return 'Source and destination cannot be same';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Estimated Fare
              TextFormField(
                controller: _fareController,
                decoration: InputDecoration(
                  labelText: 'Estimated Fare (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter estimated fare';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Quick Access Toggle
              SwitchListTile(
                title: Text('Add to Quick Access'),
                subtitle: Text('Show in quick access section'),
                value: _isQuickAccess,
                onChanged: (value) {
                  setState(() => _isQuickAccess = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'source': _sourceController.text,
                'destination': _destinationController.text,
                'fare': _fareController.text,
                'quickAccess': _isQuickAccess.toString(),
              });
            }
          },
          child: Text('Add Route'),
        ),
      ],
    );
  }
}