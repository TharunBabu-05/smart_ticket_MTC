import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../services/live_location_service.dart';
import '../services/bus_stop_service.dart';
import '../models/bus_stop_model.dart';
import '../themes/app_theme.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

/// Screen to view live buses on map with passenger counts
class LiveBusTrackingScreen extends StatefulWidget {
  @override
  _LiveBusTrackingScreenState createState() => _LiveBusTrackingScreenState();
}

class _LiveBusTrackingScreenState extends State<LiveBusTrackingScreen> {
  GoogleMapController? _mapController;
  Location _location = Location();
  
  LatLng _currentLocation = LatLng(28.6139, 77.2090); // Default Delhi
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  
  StreamSubscription? _busStreamSubscription;
  StreamSubscription? _passengerStreamSubscription;
  StreamSubscription? _personCountSubscription; // New subscription for person_count
  
  Map<String, dynamic> _activeBuses = {};
  Map<String, dynamic> _activePassengers = {};
  int _currentPersonCount = 0; // Track current person count
  
  // Custom marker icons
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _busStopIcon;
  
  // Cache for bus icons with passenger count
  Map<String, BitmapDescriptor> _busIconCache = {};
  
  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _createCustomMarkers();
    _startListeningToLiveData();
    _loadBusStops();
  }
  
  @override
  void dispose() {
    _busStreamSubscription?.cancel();
    _passengerStreamSubscription?.cancel();
    _personCountSubscription?.cancel(); // Cancel person count subscription
    _busIconCache.clear(); // Clear icon cache
    super.dispose();
  }
  
  /// Create custom marker icons
  Future<void> _createCustomMarkers() async {
    _busIcon = await _createCustomMarkerIcon(
      Icons.directions_bus,
      Colors.orange,
      60.0,
    );
    
    _userIcon = await _createCustomMarkerIcon(
      Icons.person,
      Colors.blue,
      50.0,
    );
    
    _busStopIcon = await _createCustomMarkerIcon(
      Icons.location_on,
      Colors.blue,
      40.0,
    );
  }
  
  /// Create custom marker icon from Flutter icon
  Future<BitmapDescriptor> _createCustomMarkerIcon(
    IconData iconData,
    Color color,
    double size,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = size / 2;
    
    // Draw circle background
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    
    // Draw white circle border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(radius, radius), radius - 1.5, borderPaint);
    
    // Draw icon
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );
    
    final img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  /// Create custom bus marker icon with passenger count above it
  Future<BitmapDescriptor> _createBusMarkerWithPassengerCount(
    int passengerCount,
    int maxCapacity,
  ) async {
    // Create cache key based on real values
    String cacheKey = '${passengerCount}_${maxCapacity}';
    if (_busIconCache.containsKey(cacheKey)) {
      return _busIconCache[cacheKey]!;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    double busIconSize = 100.0; // Increased from 80.0 to 100.0
    double busRadius = busIconSize / 2;
    double totalHeight = 150.0; // Increased for much larger icon
    double totalWidth = 120.0; // Increased for much larger icon
    
    // Calculate occupancy rate for color coding (handle zero capacity)
    double occupancyRate = maxCapacity > 0 ? passengerCount / maxCapacity : 0.0;
    Color busColor = _getOccupancyColor(occupancyRate);
    
    // Draw passenger count background (rounded rectangle above bus)
    double countBoxHeight = 35.0; // Increased from 30.0
    double countBoxWidth = 65.0; // Increased from 55.0
    double countBoxX = (totalWidth - countBoxWidth) / 2;
    double countBoxY = 5.0;
    
    final Paint countBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint countBorderPaint = Paint()
      ..color = busColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Increased from 2.0 for better visibility
    
    // Draw rounded rectangle for count display
    RRect countBox = RRect.fromRectAndRadius(
      Rect.fromLTWH(countBoxX, countBoxY, countBoxWidth, countBoxHeight),
      Radius.circular(15.0), // Increased from 12.0 for more modern look
    );
    canvas.drawRRect(countBox, countBgPaint);
    canvas.drawRRect(countBox, countBorderPaint);
    
    // Draw passenger count text - show real values even if zero
    TextPainter countTextPainter = TextPainter(textDirection: TextDirection.ltr);
    String countText;
    if (maxCapacity > 0) {
      countText = passengerCount > 99 ? '99+' : '$passengerCount';
    } else {
      countText = '$passengerCount'; // Just show passenger count if no capacity data
    }
    
    countTextPainter.text = TextSpan(
      text: countText,
      style: TextStyle(
        fontSize: countText.length > 2 ? 18.0 : 20.0, // Increased from 14.0/16.0 for better visibility
        color: busColor,
        fontWeight: FontWeight.bold,
      ),
    );
    countTextPainter.layout();
    countTextPainter.paint(
      canvas,
      Offset(
        countBoxX + (countBoxWidth - countTextPainter.width) / 2,
        countBoxY + (countBoxHeight - countTextPainter.height) / 2,
      ),
    );
    
    // Add a small capacity indicator dot only if we have capacity data and bus is crowded
    if (maxCapacity > 0 && occupancyRate > 0.8) {
      final Paint dotPaint = Paint()..color = Colors.red;
      canvas.drawCircle(
        Offset(countBoxX + countBoxWidth - 8, countBoxY + 8),
        4.0,
        dotPaint,
      );
    }
    
    // Draw bus icon below the count
    double busY = countBoxY + countBoxHeight + 15.0; // Increased spacing from 10.0
    double busX = (totalWidth - busIconSize) / 2;
    
    final Paint busPaint = Paint()..color = busColor;
    
    // Draw bus circle background
    canvas.drawCircle(Offset(busX + busRadius, busY + busRadius), busRadius, busPaint);
    
    // Draw white circle border for bus
    final Paint busBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Increased from 3.0 for better visibility
    canvas.drawCircle(Offset(busX + busRadius, busY + busRadius), busRadius - 2.0, busBorderPaint); // Adjusted for thicker border
    
    // Draw bus icon
    TextPainter busIconPainter = TextPainter(textDirection: TextDirection.ltr);
    busIconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus.codePoint),
      style: TextStyle(
        fontSize: busIconSize * 0.6, // Increased from 0.5 to 0.6 for larger icon
        fontFamily: Icons.directions_bus.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    busIconPainter.layout();
    busIconPainter.paint(
      canvas,
      Offset(
        busX + busRadius - busIconPainter.width / 2,
        busY + busRadius - busIconPainter.height / 2,
      ),
    );
    
    final img = await pictureRecorder.endRecording().toImage(
      totalWidth.toInt(),
      totalHeight.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    BitmapDescriptor icon = BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    
    // Cache the icon for reuse
    _busIconCache[cacheKey] = icon;
    
    return icon;
  }
  
  Future<void> _initializeLocation() async {
    try {
      LocationData locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude ?? 28.6139,
          locationData.longitude ?? 77.2090,
        );
      });
      
      _moveToCurrentLocation();
    } catch (e) {
      print('Error getting location: $e');
    }
  }
  
  void _startListeningToLiveData() {
    // Listen to active buses
    _busStreamSubscription = LiveLocationService.getActiveBuses().listen((buses) {
      setState(() {
        _activeBuses = buses;
        _updateMapMarkers();
      });
    });
    
    // Listen to active passengers
    _passengerStreamSubscription = LiveLocationService.getActivePassengers().listen((passengers) {
      setState(() {
        _activePassengers = passengers;
        _updateMapMarkers();
      });
    });
    
    // Listen to person_count and sync with bus passenger count
    _startListeningToPersonCount();
  }
  
  void _startListeningToPersonCount() {
    // Listen to live_locations/person_count/count in Firebase
    _personCountSubscription = LiveLocationService.getPersonCount().listen((personCount) {
      setState(() {
        _currentPersonCount = personCount;
        // Update all active buses with the new person count
        _syncPersonCountToBuses(personCount);
        // Clear cache to refresh icons with new count
        _busIconCache.clear();
        _updateMapMarkers();
      });
    });
  }
  
  void _syncPersonCountToBuses(int personCount) {
    // Update passenger count for all active buses
    _activeBuses.forEach((busId, busData) {
      if (busData is Map<String, dynamic>) {
        busData['passengerCount'] = personCount;
        // Update in Firebase as well
        LiveLocationService.updateBusPassengerCount(busId, personCount);
      }
    });
    // Note: _updateMapMarkers() is called by the listener that calls this function
  }
  
  void _loadBusStops() {
    // Add bus stops as markers
    if (BusStopService.isReady) {
      _addBusStopMarkers();
    } else {
      // Initialize and then add
      BusStopService.initialize().then((_) {
        _addBusStopMarkers();
      });
    }
  }
  
  void _addBusStopMarkers() {
    List<BusStop> nearbyStops = BusStopService.findNearbyStops(
      _currentLocation.latitude, 
      _currentLocation.longitude, 
      radiusKm: 5.0
    );
    
    Set<Marker> busStopMarkers = nearbyStops.take(20).map((stop) {
      return Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: LatLng(stop.latitude, stop.longitude),
        icon: _busStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: stop.name,
          snippet: 'Bus Stop',
        ),
      );
    }).toSet();
    
    setState(() {
      _markers.addAll(busStopMarkers);
    });
  }
  
  void _updateMapMarkers() async {
    Set<Marker> newMarkers = {};
    Set<Circle> newCircles = {};
    
    // Note: Using default Google Maps location indicator instead of custom marker
    
    // Add bus markers with custom bus icons showing passenger count
    for (var entry in _activeBuses.entries) {
      String busId = entry.key;
      var busData = entry.value;
      
      if (busData['location'] != null) {
        double lat = busData['location']['latitude']?.toDouble() ?? 0.0;
        double lng = busData['location']['longitude']?.toDouble() ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          // Get real-time passenger count from Firebase (no default values)
          int passengerCount = busData['passengerCount'] ?? 0; // Show 0 if null
          int maxCapacity = busData['maxCapacity'] ?? 0; // Show 0 if null
          double occupancyRate = maxCapacity > 0 ? passengerCount / maxCapacity : 0.0;
          
          // Debug: Print passenger count for troubleshooting
          print('🚌 Bus $busId: busData passengerCount = $passengerCount, using live person_count = $_currentPersonCount');
          
          // Create custom bus icon with LIVE person count instead of stored bus passenger count
          BitmapDescriptor customBusIcon = await _createBusMarkerWithPassengerCount(
            _currentPersonCount, // Use live person count instead of bus data
            maxCapacity,
          );
          
          newMarkers.add(Marker(
            markerId: MarkerId('bus_$busId'),
            position: LatLng(lat, lng),
            icon: customBusIcon,
            infoWindow: InfoWindow(
              title: '🚌 Bus ${busData['busNumber'] ?? 'Unknown'}',
              snippet: maxCapacity > 0 
                ? '👥 $_currentPersonCount/$maxCapacity passengers (${(_currentPersonCount / maxCapacity * 100).toStringAsFixed(0)}%)\n📍 Route: ${busData['route'] ?? 'Unknown'}'
                : '👥 $_currentPersonCount passengers\n📍 Route: ${busData['route'] ?? 'Unknown'}',
            ),
            anchor: Offset(0.5, 1.0), // Anchor at bottom center for better positioning
          ));
          
          // Add circle to show bus coverage area (only if occupancy rate is meaningful)
          if (maxCapacity > 0) {
            newCircles.add(Circle(
              circleId: CircleId('bus_area_$busId'),
              center: LatLng(lat, lng),
              radius: 200, // 200 meter radius
              fillColor: _getOccupancyColor(occupancyRate).withOpacity(0.2),
              strokeColor: _getOccupancyColor(occupancyRate),
              strokeWidth: 2,
            ));
          }
        }
      }
    }
    // Add passenger markers with custom user icons
    _activePassengers.forEach((passengerId, passengerData) {
      if (passengerData['location'] != null) {
        double lat = passengerData['location']['latitude']?.toDouble() ?? 0.0;
        double lng = passengerData['location']['longitude']?.toDouble() ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          newMarkers.add(Marker(
            markerId: MarkerId('passenger_$passengerId'),
            position: LatLng(lat, lng),
            icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            infoWindow: InfoWindow(
              title: '👤 Demo User',
              snippet: 'Live location shared',
            ),
          ));
        }
      }
    });
    
    // Keep bus stop markers
    Set<Marker> busStopMarkers = _markers.where((marker) => 
        marker.markerId.value.startsWith('stop_')).toSet();
    newMarkers.addAll(busStopMarkers);
    
    setState(() {
      _markers = newMarkers;
      _circles = newCircles;
    });
  }
  
  Color _getOccupancyColor(double rate) {
    if (rate < 0.3) return Colors.green;
    if (rate < 0.7) return Colors.orange;
    return Colors.red;
  }
  
  void _moveToCurrentLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 15.0),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Bus Tracking'),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _moveToCurrentLocation();
            },
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Bus count info card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: AppTheme.createCardDecoration(context),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem('🚌 Active Buses', _activeBuses.length.toString()),
                      _buildInfoItem('👥 Live Count', _currentPersonCount.toString()),
                      _buildInfoItem('🚏 Bus Stops', _markers.where((m) => m.markerId.value.startsWith('stop_')).length.toString()),
                    ],
                  ),
                    if (_activeBuses.isNotEmpty) ...[
                      Divider(height: 16),
                      Text(
                        'Live Passenger Counts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: _activeBuses.entries.map((entry) {
                          var busData = entry.value;
                          // Get real values from Firebase, show 0 if null
                          int passengers = busData['passengerCount'] ?? 0;
                          int capacity = busData['maxCapacity'] ?? 0;
                          double occupancyRate = capacity > 0 ? passengers / capacity : 0.0;
                          
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getOccupancyColor(occupancyRate).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getOccupancyColor(occupancyRate),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              capacity > 0 
                                ? '${busData['busNumber'] ?? 'Bus'}: $passengers/$capacity'
                                : '${busData['busNumber'] ?? 'Bus'}: $passengers',
                              style: TextStyle(
                                fontSize: 10,
                                color: _getOccupancyColor(occupancyRate),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ]
                ],
                ),
              ),
            ),
          ),
          
          // Bus list bottom sheet trigger
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showBusListBottomSheet,
              child: Icon(Icons.list),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      
      // Demo controls
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bus controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _startBusDemo,
                  icon: Icon(Icons.directions_bus),
                  label: Text('Be Bus'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: _startPassengerDemo,
                  icon: Icon(Icons.person),
                  label: Text('Be User'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _stopSharing,
                  icon: Icon(Icons.stop),
                  label: Text('Stop'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
  
  void _showBusListBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Buses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            if (_activeBuses.isEmpty)
              Text('No active buses nearby', style: TextStyle(color: Colors.grey[600]))
            else
              ..._activeBuses.entries.map((entry) {
                var busData = entry.value;
                // Get real values from Firebase, show 0 if null
                int passengers = busData['passengerCount'] ?? 0;
                int capacity = busData['maxCapacity'] ?? 0;
                double occupancyRate = capacity > 0 ? passengers / capacity : 0.0;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getOccupancyColor(occupancyRate),
                    child: Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  title: Text('Bus ${busData['busNumber'] ?? 'Unknown'}'),
                  subtitle: Text(
                    capacity > 0 
                      ? 'Route: ${busData['route'] ?? 'Unknown'}\n$passengers/$capacity passengers'
                      : 'Route: ${busData['route'] ?? 'Unknown'}\n$passengers passengers'
                  ),
                  trailing: capacity > 0 
                    ? Text(
                        '${(occupancyRate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getOccupancyColor(occupancyRate),
                        ),
                      )
                    : Text(
                        '$passengers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
  
  void _startBusDemo() async {
    try {
      String sessionId = await LiveLocationService.startSharingAsBus(
        busRoute: 'Route 52A',
        busNumber: 'DL1PC${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚌 Started sharing as bus! Session: ${sessionId.substring(0, 8)}...')),
      );
      
      // Simulate passenger count changes
      _simulatePassengerCount();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  void _startPassengerDemo() async {
    try {
      String sessionId = await LiveLocationService.startSharingAsPassenger();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('👤 Started sharing as demo user! Session: ${sessionId.substring(0, 8)}...')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  void _stopSharing() async {
    await LiveLocationService.stopLocationSharing();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🛑 Stopped location sharing')),
    );
  }
  
  void _simulatePassengerCount() {
    // Note: This method now just clears cache periodically to refresh real Firebase data
    // The actual passenger count comes from Firebase realtime database
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (!LiveLocationService.isSharingLocation) {
        timer.cancel();
        return;
      }
      
      // Clear cache periodically to refresh icons with new real counts from Firebase
      if (_busIconCache.length > 20) {
        _busIconCache.clear();
      }
      
      // Force refresh to get latest Firebase data
      _refreshPassengerCountDisplay();
    });
  }

  /// Clear bus icon cache to force refresh of passenger count displays
  void _refreshPassengerCountDisplay() {
    _busIconCache.clear();
    _updateMapMarkers();
  }
}
