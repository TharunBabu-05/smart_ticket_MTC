import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../services/live_location_service.dart';
import '../services/bus_stop_service.dart';
import '../models/bus_stop_model.dart';
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
  
  Map<String, dynamic> _activeBuses = {};
  Map<String, dynamic> _activePassengers = {};
  
  // Custom marker icons
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _busStopIcon;
  
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
  
  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};
    Set<Circle> newCircles = {};
    
    // Add current location marker
    newMarkers.add(Marker(
      markerId: MarkerId('current_location'),
      position: _currentLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: 'Your Location'),
    ));
    
    // Add bus markers with custom bus icons
    _activeBuses.forEach((busId, busData) {
      if (busData['location'] != null) {
        double lat = busData['location']['latitude']?.toDouble() ?? 0.0;
        double lng = busData['location']['longitude']?.toDouble() ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          int passengerCount = busData['passengerCount'] ?? 0;
          int maxCapacity = busData['maxCapacity'] ?? 50;
          double occupancyRate = passengerCount / maxCapacity;
          
          newMarkers.add(Marker(
            markerId: MarkerId('bus_$busId'),
            position: LatLng(lat, lng),
            icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: '🚌 Bus ${busData['busNumber'] ?? 'Unknown'}',
              snippet: '👥 $passengerCount/$maxCapacity passengers\n📍 Route: ${busData['route'] ?? 'Unknown'}',
            ),
          ));
          
          // Add circle to show bus coverage area
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
    });
    
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
          ),
        ],
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
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem('🚌 Active Buses', _activeBuses.length.toString()),
                    _buildInfoItem('👤 Demo Users', _activePassengers.length.toString()),
                    _buildInfoItem('🚏 Bus Stops', _markers.where((m) => m.markerId.value.startsWith('stop_')).length.toString()),
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
        child: Row(
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
                int passengers = busData['passengerCount'] ?? 0;
                int capacity = busData['maxCapacity'] ?? 50;
                double occupancyRate = passengers / capacity;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getOccupancyColor(occupancyRate),
                    child: Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  title: Text('Bus ${busData['busNumber'] ?? 'Unknown'}'),
                  subtitle: Text('Route: ${busData['route'] ?? 'Unknown'}\n$passengers/$capacity passengers'),
                  trailing: Text(
                    '${(occupancyRate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getOccupancyColor(occupancyRate),
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
    // Simulate realistic passenger count changes
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (!LiveLocationService.isSharingLocation) {
        timer.cancel();
        return;
      }
      
      // Random passenger count between 5-45
      int count = 5 + (DateTime.now().millisecondsSinceEpoch % 40).toInt();
      LiveLocationService.updatePassengerCount(count);
    });
  }
}
