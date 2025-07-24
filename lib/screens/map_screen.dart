import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../services/bus_stop_service.dart';
import '../models/bus_stop_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LocationData? _currentPosition;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  // Custom marker icons
  BitmapDescriptor? _busStopIcon;
  BitmapDescriptor? _nearestBusStopIcon;

  // Bus stops data
  List<BusStop> _nearbyBusStops = [];
  BusStop? _currentNearestStop;

  @override
  void initState() {
    super.initState();
    print('🚀 MapScreen: initState called');
    _createCustomIcons().then((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _showLocationServiceDialog();
          return;
        }
      }

      // Check and request location permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showPermissionDialog();
          return;
        }
      }

      // Get current position
      // LocationData position = await _location.getLocation();

      // Use a hardcoded location in Delhi for debugging
      final LocationData debugPosition = LocationData.fromMap({
        "latitude": 28.6139, // Delhi latitude
        "longitude": 77.2090, // Delhi longitude
      });

      setState(() {
        _currentPosition = debugPosition;
        _isLoading = false;
      });

      _addCurrentLocationMarker();
      await _loadNearbyBusStops();
      _addBusStopMarkers();
      _startLocationUpdates();
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
      _showLocationErrorDialog();
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Current position',
            ),
          ),
        );

        // Add a circle around current location
        _circles.add(
          Circle(
            circleId: const CircleId('current_location_circle'),
            center: LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
            radius: 100,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        );
      });
    }
  }

  Future<void> _loadNearbyBusStops() async {
    print('🔍 _loadNearbyBusStops called');
    print('📍 Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    print('🔧 BusStopService ready: ${BusStopService.isReady}');
    print('📊 Total bus stops count: ${BusStopService.getBusStopsCount()}');

    if (_currentPosition != null) {
      try {
        // Check if BusStopService is ready
        if (!BusStopService.isReady) {
          print('⚠️ BusStopService not ready, initializing...');
          await BusStopService.initialize();
        }

        // Find bus stops within 2km radius
        _nearbyBusStops = BusStopService.findNearbyStops(
          _currentPosition!.latitude!,
          _currentPosition!.longitude!,
          radiusKm: 5.0, // Increased radius to 5km
        );

        // Find the nearest bus stop within 100m
        _currentNearestStop = BusStopService.getNearestBusStop(
          _currentPosition!.latitude!,
          _currentPosition!.longitude!,
          thresholdMeters: 100,
        );

        print('📍 Found ${_nearbyBusStops.length} nearby bus stops');
        if (_currentNearestStop != null) {
          print('🚏 Nearest stop: ${_currentNearestStop!.name}');
        }

        // Debug: Print first few bus stops
        if (_nearbyBusStops.isNotEmpty) {
          print('🔍 First 3 nearby stops:');
          for (int i = 0; i < _nearbyBusStops.length && i < 3; i++) {
            var stop = _nearbyBusStops[i];
            double distance = stop.distanceTo(_currentPosition!.latitude!, _currentPosition!.longitude!);
            print('  ${i + 1}. ${stop.name} - ${(distance / 1000).toStringAsFixed(2)}km');
          }
        }
      } catch (e) {
        print('❌ Error loading nearby bus stops: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
    } else {
      print('❌ Current position is null');
    }
  }

  void _addBusStopMarkers() {
    print('🖌️ _addBusStopMarkers called');
    print('Nearby stops to add: ${_nearbyBusStops.length}');
    print('Markers before adding: ${_markers.length}');

    if (_busStopIcon == null || _nearestBusStopIcon == null) {
      print('⚠️ Custom icons not ready, skipping marker update.');
      return;
    }

    // Create a temporary set to avoid concurrent modification issues
    Set<Marker> newMarkers = {};

    for (final busStop in _nearbyBusStops) {
      final bool isNearest = _currentNearestStop?.id == busStop.id;
      newMarkers.add(
        Marker(
          markerId: MarkerId('bus_stop_${busStop.id}'),
          position: LatLng(busStop.latitude, busStop.longitude),
          icon: isNearest ? _nearestBusStopIcon! : _busStopIcon!,
          onTap: () => _showBusStopDetails(busStop),
          anchor: const Offset(0.5, 0.5), // Center the icon on the location
        ),
      );
    }

    setState(() {
      // Remove old bus stop markers, keeping the current location marker
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('bus_stop_'));
      // Add the new bus stop markers
      _markers.addAll(newMarkers);
    });

    print('Markers after adding: ${_markers.length}');
  }

  void _startLocationUpdates() {
    _locationSubscription = _location.onLocationChanged.listen((LocationData newPosition) {
      if (newPosition.latitude != null && newPosition.longitude != null) {
        setState(() {
          _currentPosition = newPosition;
        });

        _updateCurrentLocationMarker();
        // Reload nearby bus stops based on the new location
        // await _loadNearbyBusStops(); // Temporarily disabled for debugging
        // _addBusStopMarkers(); // Temporarily disabled for debugging
      }
    });
  }

  void _updateCurrentLocationMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
        _circles.removeWhere((circle) => circle.circleId.value == 'current_location_circle');
      });
      _addCurrentLocationMarker();
    }
  }

  void _showBusStopDetails(BusStop busStop) {
    double distance = busStop.distanceTo(
      _currentPosition!.latitude!,
      _currentPosition!.longitude!,
    );
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentNearestStop?.id == busStop.id 
                      ? const Color(0xFF1DB584) 
                      : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        busStop.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(distance / 1000).toStringAsFixed(2)} km away • ID: ${busStop.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_currentNearestStop?.id == busStop.id)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB584).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Nearest Stop',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1DB584),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB584),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Navigate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${busStop.latitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Lng: ${busStop.longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Bus Stop Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Text(
                'This bus stop is part of the Delhi bus network. Route information will be available in future updates.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteItem(String route, String destination, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              route,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              destination,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This app needs location permission to show your current location and nearby bus stops. Please enable location permission in your device settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Try to request permission again
              _initializeLocation();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _location.requestService();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: const Text('Unable to get your current location. Please check your location settings and try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
          16.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1DB584),
        elevation: 0,
        title: const Text(
          'Bus stops near you',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Map Information'),
                  content: const Text('Blue marker shows your current location. Red markers show nearby bus stops. Tap on any marker for more details.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB584)),
                  ),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!)
                        : const LatLng(13.0827, 80.2707), // Default to Chennai
                    zoom: 15.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: false, // We're handling this manually
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF1DB584),
                    onPressed: _centerOnCurrentLocation,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
                if (_nearbyBusStops.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_bus, color: Color(0xFF1DB584)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_nearbyBusStops.length} nearby bus stops',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_currentNearestStop != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1DB584).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'At Stop',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1DB584),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_currentNearestStop != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Nearest: ${_currentNearestStop!.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ] else if (_nearbyBusStops.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Closest: ${_nearbyBusStops.first.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Helper method to create custom marker icons
  Future<void> _createCustomIcons() async {
    _busStopIcon = await _createCustomMarkerBitmap(isNearest: false);
    _nearestBusStopIcon = await _createCustomMarkerBitmap(isNearest: true);
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap({
    required bool isNearest,
    int size = 100,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = isNearest ? const Color(0xFF1DB584) : Colors.black87;
    final double radius = size / 2;

    // Draw circle
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );

    // Draw bus icon
    final icon = Icons.directions_bus;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: radius,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
