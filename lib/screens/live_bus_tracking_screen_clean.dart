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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _initializeBusStops();
    _startDataGeneration();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _personCountTimer?.cancel();
    _locationSubscription?.cancel();
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
    final busStops = BusStopService.getChennaiStops();
    Set<Marker> stopMarkers = {};
    
    for (var stop in busStops.take(20)) {
      stopMarkers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: stop.location,
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
    // Generate initial buses
    for (int i = 1; i <= 5; i++) {
      _generateRandomBus();
    }
    
    // Update bus data every 3 seconds
    _dataTimer = Timer.periodic(Duration(seconds: 3), (_) => _generateRandomData());
    
    // Update person count every 2 seconds
    _personCountTimer = Timer.periodic(Duration(seconds: 2), (_) => _refreshPassengerCountDisplay());
  }

  void _generateRandomBus() {
    final busNumbers = ['21G', '45', '23C', '15A', '9B', '12', '27E', '31', '18K'];
    final randomBusNumber = busNumbers[DateTime.now().millisecondsSinceEpoch % busNumbers.length];
    
    final lat = _currentLocation.latitude + ((-1 + 2 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000) * 0.02);
    final lng = _currentLocation.longitude + ((-1 + 2 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000) * 0.02);
    
    final busId = 'bus_${DateTime.now().millisecondsSinceEpoch}';
    
    setState(() {
      _activeBuses[busId] = {
        'busNumber': randomBusNumber,
        'location': LatLng(lat, lng),
        'passengerCount': (DateTime.now().millisecondsSinceEpoch % 40) + 5,
        'maxCapacity': 45,
        'route': 'Route ${randomBusNumber}',
        'lastUpdate': DateTime.now(),
      };
      
      _markers.add(
        Marker(
          markerId: MarkerId(busId),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Bus $randomBusNumber',
            snippet: 'Passengers: ${_activeBuses[busId]!['passengerCount']}/${_activeBuses[busId]!['maxCapacity']}',
          ),
        ),
      );
    });
  }

  void _generateRandomData() {
    setState(() {
      _activeBuses.forEach((busId, busData) {
        int currentCount = busData['passengerCount'];
        int change = (DateTime.now().millisecondsSinceEpoch % 7) - 3;
        int newCount = (currentCount + change).clamp(0, busData['maxCapacity']);
        
        _activeBuses[busId]!['passengerCount'] = newCount;
        _activeBuses[busId]!['lastUpdate'] = DateTime.now();
        
        // Update marker info
        _markers = _markers.map((marker) {
          if (marker.markerId.value == busId) {
            return marker.copyWith(
              infoWindowParam: InfoWindow(
                title: 'Bus ${busData['busNumber']}',
                snippet: 'Passengers: $newCount/${busData['maxCapacity']}',
              ),
            );
          }
          return marker;
        }).toSet();
      });
    });
  }

  void _refreshPassengerCountDisplay() {
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
            Text('Active Buses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                subtitle: Text('${busData['route']}'),
                trailing: Text('$passengers/$capacity'),
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
                      'Live Passenger Counts',
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
                  onPressed: _generateRandomBus,
                  child: Text('Add Bus'),
                ),
                ElevatedButton(
                  onPressed: _generateRandomData,
                  child: Text('Random Data'),
                ),
                ElevatedButton(
                  onPressed: _showBusListBottomSheet,
                  child: Text('Bus List'),
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