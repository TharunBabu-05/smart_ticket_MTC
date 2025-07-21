import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip_data_model.dart';
import '../models/fraud_analysis_model.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../services/fraud_detection_service.dart';
import '../services/firebase_service.dart';
import '../services/background_service.dart';
import 'trip_completion_screen.dart';

class JourneyTrackingScreen extends StatefulWidget {
  final TripData tripData;
  
  const JourneyTrackingScreen({Key? key, required this.tripData}) : super(key: key);
  
  @override
  _JourneyTrackingScreenState createState() => _JourneyTrackingScreenState();
}

class _JourneyTrackingScreenState extends State<JourneyTrackingScreen> {
  late LocationService _locationService;
  late SensorService _sensorService;
  late FraudDetectionService _fraudService;
  
  StreamSubscription<LocationPoint>? _locationSubscription;
  StreamSubscription<SensorReading>? _sensorSubscription;
  
  List<LocationPoint> _gpsTrail = [];
  List<SensorReading> _sensorData = [];
  
  bool _isMonitoring = false;
  bool _nearDestination = false;
  String _currentStatus = 'Starting journey...';
  double _currentSpeed = 0.0;
  double _distanceTraveled = 0.0;
  TransportMode _detectedMode = TransportMode.unknown;
  
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startTripMonitoring();
  }

  void _initializeServices() {
    _locationService = LocationService();
    _sensorService = SensorService();
    _fraudService = FraudDetectionService();
  }

  Future<void> _startTripMonitoring() async {
    print('Starting trip monitoring...');
    
    if (!mounted) return;
    
    setState(() {
      _isMonitoring = true;
      _currentStatus = 'Initializing GPS and sensors...';
    });

    try {
      // Start background service with comprehensive error handling
      try {
        await BackgroundTripService.startTripMonitoring(widget.tripData)
            .timeout(Duration(seconds: 8));
        print('Background service started successfully');
      } catch (e) {
        print('Warning: Background service failed to start: $e');
        // Continue without background service - this is not critical
      }
      
      // Add delay to ensure UI is stable before starting location services
      await Future.delayed(Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Start location tracking with improved error handling
      bool locationStarted = false;
      try {
        locationStarted = await _locationService.startTracking()
            .timeout(Duration(seconds: 15)); // Increased timeout
        print('Location tracking started: $locationStarted');
      } catch (e) {
        print('Location tracking error: $e');
        // Set a user-friendly error message
        if (mounted) {
          setState(() {
            _currentStatus = 'Location permission required. Please enable location access.';
          });
        }
      }
      
      if (!locationStarted) {
        print('Warning: Location tracking failed, continuing with limited functionality');
        if (mounted) {
          setState(() {
            _currentStatus = 'GPS unavailable - limited tracking mode';
          });
        }
        // Don't return - continue with limited functionality
      }

      // Set up location stream with comprehensive error handling
      if (locationStarted && mounted) {
        try {
          _locationSubscription = _locationService.locationStream.listen(
            (LocationPoint point) {
              if (mounted) {
                try {
                  setState(() {
                    _gpsTrail.add(point);
                    _currentSpeed = point.speed;
                    _distanceTraveled = _locationService.calculateTotalDistance(_gpsTrail);
                  });
                  _checkForDestinationArrival(point);
                  _updateStatus();
                } catch (e) {
                  print('Error updating location state: $e');
                }
              }
            },
            onError: (error) {
              print('Location stream error: $error');
              if (mounted) {
                try {
                  setState(() {
                    _currentStatus = 'GPS error - limited tracking';
                  });
                } catch (e) {
                  print('Error updating GPS error state: $e');
                }
              }
            },
          );
        } catch (e) {
          print('Error setting up location stream: $e');
        }
      }

      // Add another delay before starting sensor monitoring
      await Future.delayed(Duration(milliseconds: 300));
      
      if (!mounted) return;

      // Start sensor monitoring with improved error handling
      try {
        await _sensorService.startMonitoring().timeout(Duration(seconds: 8));
        if (mounted) {
          _sensorSubscription = _sensorService.sensorStream.listen(
            (SensorReading reading) {
              if (mounted) {
                try {
                  setState(() {
                    _sensorData.add(reading);
                    // Keep only last 100 readings to manage memory
                    if (_sensorData.length > 100) {
                      _sensorData.removeAt(0);
                    }
                  });
                  _updateDetectedTransportMode();
                } catch (e) {
                  print('Error updating sensor state: $e');
                }
              }
            },
            onError: (error) {
              print('Sensor stream error: $error');
              // Don't update UI state for sensor errors as they're not critical
            },
          );
        }
        print('Sensor monitoring started successfully');
      } catch (e) {
        print('Warning: Sensor monitoring failed to start: $e');
        // Continue without sensor monitoring - this is not critical for basic functionality
      }

      if (!mounted) return;

      // Start periodic status updates with error handling
      try {
        _statusUpdateTimer = Timer.periodic(
          const Duration(seconds: 10),
          (timer) {
            if (mounted) {
              try {
                _updateStatus();
              } catch (e) {
                print('Error in periodic status update: $e');
              }
            } else {
              timer.cancel();
            }
          },
        );
      } catch (e) {
        print('Error setting up status timer: $e');
      }

      if (mounted) {
        setState(() {
          _currentStatus = 'Journey monitoring active';
        });
      }
      
      print('Trip monitoring started successfully');

    } catch (e) {
      print('Error in _startTripMonitoring: $e');
      if (mounted) {
        setState(() {
          _currentStatus = 'Monitoring error - limited functionality';
          _isMonitoring = false;
        });
        _showErrorDialog('Failed to start monitoring: $e');
      }
    }
  }

  void _updateDetectedTransportMode() {
    if (_sensorData.length >= 10) {
      // Classify transport mode every 10 readings
      if (_sensorService.detectBusPattern(_sensorData)) {
        _detectedMode = TransportMode.bus;
      } else if (_sensorService.detectBikePattern(_sensorData)) {
        _detectedMode = TransportMode.bike;
      } else if (_sensorService.detectWalkingPattern(_sensorData)) {
        _detectedMode = TransportMode.walking;
      }
    }
  }

  void _updateStatus() {
    if (!mounted) return;
    
    setState(() {
      if (_gpsTrail.isEmpty) {
        _currentStatus = 'Waiting for GPS signal...';
      } else if (_currentSpeed < 5) {
        _currentStatus = 'Bus stopped or moving slowly';
      } else if (_currentSpeed > 50) {
        _currentStatus = 'High speed detected - verify you\'re on the bus';
      } else {
        _currentStatus = 'Journey in progress';
      }
    });
  }

  void _checkForDestinationArrival(LocationPoint currentLocation) {
    double distanceToDestination = _locationService.calculateDistance(
      currentLocation.position,
      widget.tripData.destinationLocation,
    );

    if (distanceToDestination < 150 && !_nearDestination) { // Within 150 meters
      setState(() {
        _nearDestination = true;
      });
      _showExitConfirmationDialog();
    }
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 8),
              Text('Destination Reached'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You are near ${widget.tripData.destinationName}.'),
              SizedBox(height: 8),
              Text('Have you exited the bus?', 
                   style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _endTripManually(userConfirmedExit: true);
              },
              child: Text('Yes, I exited'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _nearDestination = false; // Reset to allow re-triggering
                });
              },
              child: Text('No, continue monitoring'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _endTripManually({bool userConfirmedExit = false}) async {
    setState(() {
      _currentStatus = 'Ending trip and analyzing journey...';
    });

    try {
      // Stop monitoring services
      await _stopMonitoring();

      // Create final trip data
      final completedTrip = widget.tripData.copyWith(
        endTime: DateTime.now(),
        gpsTrail: _gpsTrail,
        sensorData: _sensorData,
        status: TripStatus.completed,
      );

      // Perform fraud analysis
      final analysis = await _fraudService.analyzeTripData(completedTrip);

      // Update trip with fraud confidence
      final finalTrip = completedTrip.copyWith(
        fraudConfidence: analysis.fraudConfidence,
        status: analysis.fraudConfidence > 0.6 
            ? TripStatus.flagged 
            : TripStatus.completed,
      );

      // Save to Firebase
      await FirebaseService.saveTripData(finalTrip, analysis);
      await FirebaseService.saveUserTripHistory(widget.tripData.userId, finalTrip);

      // Navigate to completion screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripCompletionScreen(
              tripData: finalTrip,
              analysis: analysis,
              userConfirmedExit: userConfirmedExit,
            ),
          ),
        );
      }

    } catch (e) {
      _showErrorDialog('Failed to complete trip: $e');
    }
  }

  Future<void> _stopMonitoring() async {
    _statusUpdateTimer?.cancel();
    _locationService.stopTracking();
    _sensorService.stopMonitoring();
    await _locationSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await BackgroundTripService.stopTripMonitoring();
    
    setState(() {
      _isMonitoring = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Confirm before leaving the tracking screen
        bool? shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('End Trip?'),
            content: Text('Are you sure you want to stop monitoring your journey?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('End Trip'),
              ),
            ],
          ),
        );
        
        if (shouldPop == true) {
          await _endTripManually();
        }
        
        return false; // Always prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Journey in Progress'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: Column(
          children: [
            _buildTripInfoCard(),
            _buildRealTimeStats(),
            _buildStatusIndicator(),
            Spacer(),
            _buildManualEndTripButton(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.blue),
                SizedBox(width: 8),
                Text('Trip Details', style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                )),
              ],
            ),
            SizedBox(height: 12),
            _buildTripDetailRow('From', widget.tripData.sourceName ?? 'Source'),
            _buildTripDetailRow('To', widget.tripData.destinationName ?? 'Destination'),
            _buildTripDetailRow('Started', _formatTime(widget.tripData.startTime)),
            _buildTripDetailRow('Ticket ID', widget.tripData.ticketId.substring(0, 8) + '...'),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label + ':', style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            )),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Real-time Data', style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
            )),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Speed',
                    '${_currentSpeed.toStringAsFixed(1)} km/h',
                    Icons.speed,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Distance',
                    '${(_distanceTraveled / 1000).toStringAsFixed(1)} km',
                    Icons.straighten,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'GPS Points',
                    '${_gpsTrail.length}',
                    Icons.gps_fixed,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Transport',
                    _getTransportModeDisplay(_detectedMode),
                    Icons.directions,
                    _getTransportModeColor(_detectedMode),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          )),
          Text(label, style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          )),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isMonitoring ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(_currentStatus, style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEndTripButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _endTripManually(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('End Trip Manually', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getTransportModeDisplay(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.bike:
        return 'Bike';
      case TransportMode.car:
        return 'Car';
      case TransportMode.walking:
        return 'Walking';
      case TransportMode.unknown:
        return 'Detecting...';
    }
  }

  Color _getTransportModeColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:
        return Colors.green;
      case TransportMode.bike:
        return Colors.orange;
      case TransportMode.car:
        return Colors.red;
      case TransportMode.walking:
        return Colors.blue;
      case TransportMode.unknown:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _stopMonitoring();
    _locationService.dispose();
    _sensorService.dispose();
    super.dispose();
  }
}
