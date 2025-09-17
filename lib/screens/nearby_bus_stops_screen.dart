import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/bus_stop_service.dart';
import '../models/bus_stop_model.dart';
import '../models/trip_data_model.dart';
import '../models/rating_model.dart';
import 'rating/review_list_screen.dart';
import 'rating/review_submission_screen.dart';

class NearbyBusStopsScreen extends StatefulWidget {
  const NearbyBusStopsScreen({super.key});

  @override
  State<NearbyBusStopsScreen> createState() => _NearbyBusStopsScreenState();
}

class _NearbyBusStopsScreenState extends State<NearbyBusStopsScreen> {
  List<BusStop> nearbyStops = [];
  bool isLoading = true;
  String errorMessage = '';
  LocationPoint? currentLocation;
  
  @override
  void initState() {
    super.initState();
    _loadNearbyStops();
  }

  Future<void> _loadNearbyStops() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Initialize services if needed
      await BusStopService.initialize();
      
      List<BusStop> stops = [];
      
      // ALWAYS load Delhi bus stops first (regardless of location)
      List<BusStop> delhiStops = BusStopService.getDelhiBusStops();
      stops.addAll(delhiStops);
      print('🏛️ Added ${delhiStops.length} Delhi bus stops (always included)');
      
      // Try to get current location for nearby stops
      LocationService locationService = LocationService();
      LocationPoint? location;
      
      try {
        location = await locationService.getCurrentLocation();
        
        if (location != null) {
          // Find nearby stops within 5km from current location
          List<BusStop> nearbyStops = BusStopService.findNearbyStops(
            location.position.latitude,
            location.position.longitude,
            radiusKm: 5.0,
          );
          
          // Add nearby stops that aren't already in the list (avoid duplicates)
          for (BusStop nearbyStop in nearbyStops) {
            bool alreadyExists = stops.any((existingStop) => 
              existingStop.id == nearbyStop.id ||
              (existingStop.name == nearbyStop.name && 
               (existingStop.latitude - nearbyStop.latitude).abs() < 0.001 &&
               (existingStop.longitude - nearbyStop.longitude).abs() < 0.001)
            );
            
            if (!alreadyExists) {
              stops.add(nearbyStop);
            }
          }
          
          print('📍 Current location: ${location.position.latitude}, ${location.position.longitude}');
          print('🚌 Added ${nearbyStops.length} additional nearby stops');
        } else {
          print('⚠️ Could not get location, but Delhi stops are still available');
        }
      } catch (locationError) {
        print('⚠️ Location error: $locationError, but Delhi stops are still available');
        // Continue without location - Delhi stops are already added
      }
      
      print('📊 Total stops available: ${stops.length}');

      setState(() {
        currentLocation = location;
        nearbyStops = stops;
        isLoading = false;
      });

      // Debug: Log first few stops
      for (int i = 0; i < stops.length && i < 5; i++) {
        BusStop stop = stops[i];
        String city = _getCityFromStop(stop);
        if (location != null) {
          double distance = stop.distanceTo(location.position.latitude, location.position.longitude);
          print('🚏 Stop $i: ${stop.name} (${(distance/1000).toStringAsFixed(2)}km away) - $city');
        } else {
          print('🚏 Stop $i: ${stop.name} - $city');
        }
      }

    } catch (e) {
      print('❌ Error loading bus stops: $e');
      setState(() {
        errorMessage = 'Error loading bus stops: $e';
        isLoading = false;
      });
    }
  }

  String _getDistanceText(BusStop stop) {
    if (currentLocation == null) {
      // If no location, show city instead of distance for Delhi stops
      String city = _getCityFromStop(stop);
      if (city == 'Delhi') {
        return 'Delhi';
      } else if (city == 'Chennai') {
        return 'Chennai';
      }
      return 'Location Unknown';
    }
    
    double distance = stop.distanceTo(
      currentLocation!.position.latitude, 
      currentLocation!.position.longitude
    );
    
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  String _getCityFromStop(BusStop stop) {
    // Simple heuristic based on coordinates
    // Chennai is around 13.0827° N, 80.2707° E
    // Delhi is around 28.7041° N, 77.1025° E
    if (stop.latitude > 20 && stop.latitude < 35 && stop.longitude > 75 && stop.longitude < 80) {
      return 'Delhi';
    } else if (stop.latitude > 10 && stop.latitude < 15 && stop.longitude > 78 && stop.longitude < 82) {
      return 'Chennai';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bus Stops Near You',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyStops,
            tooltip: 'Refresh Stops',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.surface,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // Header with location info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bus Stops Available',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (currentLocation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'All Delhi stops + stops near your location',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Your Location: ${currentLocation!.position.latitude.toStringAsFixed(4)}, ${currentLocation!.position.longitude.toStringAsFixed(4)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'All Delhi bus stops (location not available)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Content area
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Finding nearby bus stops...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNearbyStops,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (nearbyStops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus_filled_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Bus Stops Available',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load bus stops data. Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (currentLocation != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Location: ${currentLocation!.position.latitude.toStringAsFixed(4)}, ${currentLocation!.position.longitude.toStringAsFixed(4)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'City: ${_getCityFromLocation(currentLocation!.position)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadNearbyStops,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Show list of nearby stops
    return Column(
      children: [
        // Stats header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${nearbyStops.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1DB584),
                    ),
                  ),
                  Text(
                    'Total Stops',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
              ),
              Column(
                children: [
                  Text(
                    '${_getDelhiStopsCount()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Delhi Stops',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
              ),
              Column(
                children: [
                  Text(
                    _getNearestDistance(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1DB584),
                    ),
                  ),
                  Text(
                    'Nearest',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Bus stops list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nearbyStops.length,
            itemBuilder: (context, index) {
              final stop = nearbyStops[index];
              return _buildStopCard(stop, index);
            },
          ),
        ),
      ],
    );
  }

  String _getNearestDistance() {
    if (nearbyStops.isEmpty || currentLocation == null) return '0m';
    
    double distance = nearbyStops.first.distanceTo(
      currentLocation!.position.latitude,
      currentLocation!.position.longitude,
    );
    
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  int _getDelhiStopsCount() {
    return nearbyStops.where((stop) => _getCityFromStop(stop) == 'Delhi').length;
  }

  Widget _buildStopCard(BusStop stop, int index) {
    String distance = _getDistanceText(stop);
    String city = _getCityFromStop(stop);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showStopDetails(stop);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: city == 'Chennai' 
                        ? const Color(0xFF1DB584).withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: city == 'Chennai' 
                        ? const Color(0xFF1DB584)
                        : Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_city,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.my_location,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: index == 0 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      index == 0 ? 'NEAREST' : '#${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: index == 0 ? Colors.green : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewStationReviews(stop),
                      icon: const Icon(Icons.star_border, size: 16),
                      label: const Text('Reviews'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rateStation(stop),
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Rate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _viewStationReviews(BusStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewListScreen(
          serviceId: stop.id.toString(),
          reviewType: ReviewType.station,
          serviceName: stop.name,
        ),
      ),
    );
  }

  void _rateStation(BusStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewSubmissionScreen(
          serviceId: stop.id.toString(),
          reviewType: ReviewType.station,
          serviceName: stop.name,
        ),
      ),
    );
  }

  void _showStopDetails(BusStop stop) {
    String city = _getCityFromStop(stop);
    String distance = _getDistanceText(stop);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: city == 'Chennai' 
                    ? const Color(0xFF1DB584)
                    : Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$city • $distance away',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Stop ID', stop.id.toString()),
            _buildDetailRow('Coordinates', 
              '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}'),
            _buildDetailRow('Distance', distance),
            _buildDetailRow('City', city),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // You can navigate to booking with this stop pre-selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected ${stop.name} for booking'),
                          backgroundColor: const Color(0xFF1DB584),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB584),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.confirmation_number),
                    label: const Text('Book from Here'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCityFromLocation(LatLng location) {
    // Simple city detection based on coordinates
    // Chennai coordinates roughly: 13.0827° N, 80.2707° E
    // Delhi coordinates roughly: 28.7041° N, 77.1025° E
    
    if (location.latitude >= 12.5 && location.latitude <= 13.5 && 
        location.longitude >= 79.5 && location.longitude <= 80.5) {
      return 'Chennai';
    } else if (location.latitude >= 28.0 && location.latitude <= 29.0 && 
               location.longitude >= 76.5 && location.longitude <= 78.0) {
      return 'Delhi';
    } else {
      return 'Unknown';
    }
  }
}
