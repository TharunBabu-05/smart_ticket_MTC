import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/live_location_service.dart';
import '../services/bus_stop_service.dart';
import '../models/bus_stop_model.dart';
import '../themes/app_theme.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

class LiveBusTrackingScreen extends StatefulWidget {
  @override
  _LiveBusTrackingScreenState createState() => _LiveBusTrackingScreenState();
}

class _LiveBusTrackingScreenState extends State<LiveBusTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Location location = Location();
  LatLng _currentLocation = LatLng(13.0827, 80.2707); // Chennai default
  
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  
  // Bus tracking data
  Map<String, Map<String, dynamic>> _activeBuses = {};
  int _currentPersonCount = 0;
  Timer? _dataTimer;
  Timer? _personCountTimer;
  StreamSubscription? _locationSubscription;
  bool _locationPermissionGranted = false;
  
  // Firebase references
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _busDataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _initializeBusStops();
    _loadExistingBusesFromFirebase();
    _startDataGeneration();
    _initializeFirebaseListeners();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _personCountTimer?.cancel();
    _locationSubscription?.cancel();
    _busDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationPermissionGranted = true;
    LocationData locationData = await location.getLocation();
    setState(() {
      _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
    });

    _locationSubscription = location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
    });
  }

  void _initializeBusStops() {
    final busStops = BusStopService.getAllBusStops();
    Set<Marker> stopMarkers = {};
    
    for (var stop in busStops.take(20)) {
      stopMarkers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: stop.name),
        ),
      );
    }
    
    setState(() {
      _markers.addAll(stopMarkers);
    });
  }

  void _startDataGeneration() {
    // Only refresh passenger count display from Firebase data
    _personCountTimer = Timer.periodic(Duration(seconds: 5), (_) => _refreshPassengerCountDisplay());
  }

  void _loadExistingBusesFromFirebase() async {
    try {
      print('🔄 Loading existing buses from Firebase...');
      final snapshot = await _database.child('liveBuses').get();
      
      if (snapshot.exists) {
        final busesData = snapshot.value as Map<dynamic, dynamic>;
        print('📍 Found ${busesData.keys.length} buses in Firebase');
        
        // Create bus icon once
        final busIcon = await _createBusIcon();
        
        setState(() {
          busesData.forEach((busId, busData) {
            if (busData is Map && busData['isActive'] == true) {
              // Add to local buses map
              _activeBuses[busId] = {
                'busNumber': busData['busNumber'] ?? 'Unknown',
                'location': LatLng(
                  (busData['latitude'] ?? 0.0).toDouble(), 
                  (busData['longitude'] ?? 0.0).toDouble()
                ),
                'passengerCount': busData['passengerCount'] ?? 0,
                'maxCapacity': busData['maxCapacity'] ?? 45,
                'route': busData['route'] ?? 'Unknown Route',
                'lastUpdate': DateTime.now(),
              };
              
              // Add marker to map
              _markers.add(
                Marker(
                  markerId: MarkerId(busId),
                  position: LatLng(
                    (busData['latitude'] ?? 0.0).toDouble(), 
                    (busData['longitude'] ?? 0.0).toDouble()
                  ),
                  icon: busIcon,
                  infoWindow: InfoWindow(
                    title: '🚌 Bus ${busData['busNumber']}',
                    snippet: 'Live Passengers: ${busData['passengerCount'] ?? 0}/${busData['maxCapacity'] ?? 45}',
                  ),
                ),
              );
            }
          });
        });
        
        print('✅ Loaded ${_activeBuses.length} active buses from Firebase');
        _refreshPassengerCountDisplay();
      } else {
        print('📍 No existing buses found in Firebase');
      }
    } catch (error) {
      print('❌ Error loading buses from Firebase: $error');
    }
  }

  void _initializeFirebaseListeners() {
    // Test Firebase connection first
    _testFirebaseConnection();
    
    // Listen to live bus data from Firebase
    _busDataSubscription = _database.child('liveBuses').onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _updateBusDataFromFirebase(data);
        }
      }
    });
    
    // Listen to real-time person count from Firebase
    _database.child('person_count').onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data['count'] != null) {
          final realPassengerCount = data['count'] as int;
          _updateAllBusesWithRealCount(realPassengerCount);
        }
      }
    });
  }

  void _testFirebaseConnection() async {
    try {
      // Test write to Firebase
      await _database.child('test').set({
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'connected'
      });
      print('✅ Firebase connection test successful');
      
      // Test reading from Firebase buses
      final busSnapshot = await _database.child('liveBuses').get();
      if (busSnapshot.exists) {
        final busData = busSnapshot.value as Map<dynamic, dynamic>;
        print('📋 Found ${busData.keys.length} buses in Firebase');
      } else {
        print('📋 No buses found in Firebase');
      }
      
      // Test reading from Firebase person count
      final personCountSnapshot = await _database.child('person_count').get();
      if (personCountSnapshot.exists) {
        final personCountData = personCountSnapshot.value as Map<dynamic, dynamic>;
        int currentCount = personCountData['count'] ?? 0;
        print('👥 Person count from Firebase: $currentCount');
      } else {
        print('👥 No person count found in Firebase');
      }
      
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 Firebase connection successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print('❌ Firebase connection test failed: $error');
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Firebase connection failed: $error'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateBusDataFromFirebase(Map<dynamic, dynamic> firebaseData) {
    setState(() {
      // Update passenger counts for existing buses from Firebase data
      firebaseData.forEach((busId, busInfo) {
        if (_activeBuses.containsKey(busId)) {
          _activeBuses[busId]!['passengerCount'] = busInfo['passengerCount'] ?? 0;
          _activeBuses[busId]!['maxCapacity'] = busInfo['maxCapacity'] ?? 45;
          _activeBuses[busId]!['lastUpdate'] = DateTime.now();
          
          // Update marker info with real Firebase data
          _markers = _markers.map((marker) {
            if (marker.markerId.value == busId) {
              return marker.copyWith(
                infoWindowParam: InfoWindow(
                  title: '🚌 Bus ${_activeBuses[busId]!['busNumber']}',
                  snippet: 'Live Passengers: ${_activeBuses[busId]!['passengerCount']}/${_activeBuses[busId]!['maxCapacity']}',
                ),
              );
            }
            return marker;
          }).toSet();
        }
      });
    });
  }

  void _updateAllBusesWithRealCount(int realPassengerCount) {
    setState(() {
      // Update all active buses with the real passenger count from Firebase
      _activeBuses.forEach((busId, busData) {
        _activeBuses[busId]!['passengerCount'] = realPassengerCount;
        _activeBuses[busId]!['lastUpdate'] = DateTime.now();
      });
      
      // Update all bus markers with the real passenger count
      _markers = _markers.map((marker) {
        if (marker.markerId.value.startsWith('bus_')) {
          final busId = marker.markerId.value;
          if (_activeBuses.containsKey(busId)) {
            return marker.copyWith(
              infoWindowParam: InfoWindow(
                title: '🚌 Bus ${_activeBuses[busId]!['busNumber']}',
                snippet: 'Live Passengers: $realPassengerCount/${_activeBuses[busId]!['maxCapacity']}',
              ),
            );
          }
        }
        return marker;
      }).toSet();
      
      // Update the total person count display
      _currentPersonCount = realPassengerCount * _activeBuses.length;
    });
  }

  // Create custom bus icon
  Future<BitmapDescriptor> _createBusIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.orange;
    final double size = 80.0;
    
    // Draw circle background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw bus emoji/icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🚌',
        style: TextStyle(fontSize: 40.0),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));
    
    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _addBusAtCurrentLocation() async {
    // Add bus at user's current location
    final busId = 'bus_${DateTime.now().millisecondsSinceEpoch}';
    
    // Simple bus number based on current buses count
    final busNumber = 'MTC${(_activeBuses.length + 1).toString().padLeft(2, '0')}';
    
    final busData = {
      // Basic bus information
      'busId': busId,
      'busNumber': busNumber,
      'route': 'User Route',
      
      // Location data
      'latitude': _currentLocation.latitude,
      'longitude': _currentLocation.longitude,
      'location': {
        'lat': _currentLocation.latitude,
        'lng': _currentLocation.longitude,
      },
      
      // Passenger data
      'passengerCount': 0,
      'maxCapacity': 45,
      'occupancyRate': 0.0,
      
      // Status and metadata
      'isActive': true,
      'status': 'active',
      'addedBy': 'mobile_app',
      'createdAt': DateTime.now().toIso8601String(),
      'lastUpdate': DateTime.now().toIso8601String(),
      
      // Device info
      'deviceInfo': {
        'platform': 'mobile',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    };
    
    // Create bus icon
    final busIcon = await _createBusIcon();
    
    setState(() {
      _activeBuses[busId] = {
        'busNumber': busNumber,
        'location': _currentLocation,
        'passengerCount': 0,
        'maxCapacity': 45,
        'route': 'User Route',
        'lastUpdate': DateTime.now(),
      };
      
      _markers.add(
        Marker(
          markerId: MarkerId(busId),
          position: _currentLocation,
          icon: busIcon,
          infoWindow: InfoWindow(
            title: '🚌 Bus $busNumber',
            snippet: 'Live Passengers: 0/45',
          ),
        ),
      );
    });
    
    // Save to Firebase Realtime Database
    try {
      await _database.child('liveBuses').child(busId).set(busData);
      print('✅ Bus $busNumber added to Firebase successfully');
      
      // Also save to a separate active buses list for easier querying
      await _database.child('activeBuses').child(busId).set({
        'busNumber': busNumber,
        'isActive': true,
        'addedAt': DateTime.now().toIso8601String(),
      });
      
      // Show success message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚌 Bus $busNumber added to Firebase!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print('❌ Error adding bus to Firebase: $error');
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add bus to Firebase: $error'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
    
    // Move camera to current location
    _moveToCurrentLocation();
  }

  void _refreshPassengerCountDisplay() {
    // Real-time passenger counts are now updated automatically from Firebase
    // This method just calculates the total from current bus data
    setState(() {
      _currentPersonCount = _activeBuses.values
          .map<int>((bus) => bus['passengerCount'] as int)
          .fold(0, (sum, count) => sum + count);
    });
  }

  void _moveToCurrentLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15.0),
      );
    }
  }

  Color _getOccupancyColor(double occupancyRate) {
    if (occupancyRate <= 0.6) return Colors.green;
    if (occupancyRate <= 0.8) return Colors.orange;
    return Colors.red;
  }

  void _showBusListBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Active Buses (Live Firebase Data)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            ..._activeBuses.entries.map((entry) {
              var busData = entry.value;
              int passengers = busData['passengerCount'];
              int capacity = busData['maxCapacity'];
              double occupancyRate = passengers / capacity;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getOccupancyColor(occupancyRate),
                  child: Text('${busData['busNumber']}', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text('Bus ${busData['busNumber']}'),
                subtitle: Text('${busData['route']} • Live Count: $passengers'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$passengers/$capacity', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Firebase', style: TextStyle(fontSize: 10, color: Colors.green)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: 'Live Bus Tracking',
      actions: [
        IconButton(
          icon: Icon(
            Icons.cloud_upload,
            color: AppTheme.getPrimaryTextColor(context),
          ),
          onPressed: _testFirebaseConnection,
          tooltip: 'Test Firebase Connection',
        ),
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: AppTheme.getPrimaryTextColor(context),
          ),
          onPressed: _refreshPassengerCountDisplay,
          tooltip: 'Refresh Passenger Count',
        ),
        IconButton(
          icon: Icon(
            Icons.my_location,
            color: AppTheme.getPrimaryTextColor(context),
          ),
          onPressed: _moveToCurrentLocation,
          tooltip: 'My Location',
        ),
      ],
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
                      'Live Passengers (Firebase)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: _activeBuses.entries.map((entry) {
                        var busData = entry.value;
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
                  ],
                ],
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
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light 
            ? Colors.grey[100] 
            : Colors.grey[900],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addBusAtCurrentLocation,
                  child: Text('Add Bus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: _showBusListBottomSheet,
                  child: Text('Bus List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
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
        Text(
          value, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: AppTheme.getPrimaryTextColor(context),
          ),
        ),
        Text(
          label, 
          style: TextStyle(
            fontSize: 12, 
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}