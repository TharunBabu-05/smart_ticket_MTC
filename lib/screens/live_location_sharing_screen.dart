import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/safety_service.dart';
import '../services/location_service.dart';
import '../models/emergency_contact_model.dart';

class LiveLocationSharingScreen extends StatefulWidget {
  @override
  _LiveLocationSharingScreenState createState() => _LiveLocationSharingScreenState();
}

class _LiveLocationSharingScreenState extends State<LiveLocationSharingScreen>
    with TickerProviderStateMixin {
  final SafetyService _safetyService = SafetyService();
  late AnimationController _pulseController;
  
  bool _isSharingLocation = false;
  DateTime? _sharingStartTime;
  Timer? _updateTimer;
  List<EmergencyContact> _selectedContacts = [];
  List<EmergencyContact> _allContacts = [];
  String? _currentAddress;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadContacts();
    _checkLocationSharingStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await _safetyService.getEmergencyContacts();
    setState(() {
      _allContacts = contacts;
      _selectedContacts = List.from(contacts); // Select all by default
    });
  }

  Future<void> _checkLocationSharingStatus() async {
    // Check if location sharing is currently active
    final isActive = _safetyService.isLocationSharingActive;
    if (isActive) {
      setState(() {
        _isSharingLocation = true;
        _sharingStartTime = DateTime.now(); // This should come from service
      });
      _pulseController.repeat();
      _startLocationUpdates();
    }
  }

  void _startLocationUpdates() {
    _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isSharingLocation) {
        _getCurrentLocation();
      } else {
        timer.cancel();
      }
    });
    _getCurrentLocation(); // Get initial location
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = await LocationService().getCurrentLocation();
      // Convert coordinates to address (you'll need a geocoding service)
      setState(() {
        _currentAddress = '${location?.position.latitude.toStringAsFixed(6) ?? '0.0'}, ${location?.position.longitude.toStringAsFixed(6) ?? '0.0'}';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _currentAddress = 'Unable to get location';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _startLocationSharing() async {
    if (_selectedContacts.isEmpty) {
      _showNoContactsSelectedDialog();
      return;
    }

    try {
      await _safetyService.startLocationSharing(
        contactIds: _selectedContacts.map((c) => c.id).toList(),
      );
      
      setState(() {
        _isSharingLocation = true;
        _sharingStartTime = DateTime.now();
      });

      _pulseController.repeat();
      _startLocationUpdates();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Location sharing started'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start location sharing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopLocationSharing() async {
    final shouldStop = await _showStopConfirmation();
    if (shouldStop == true) {
      try {
        await _safetyService.stopLocationSharing();
        
        setState(() {
          _isSharingLocation = false;
          _sharingStartTime = null;
          _currentAddress = null;
        });

        _pulseController.stop();
        _updateTimer?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Location sharing stopped'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop location sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: _isSharingLocation ? Colors.blue.shade50 : colorScheme.surface,
      appBar: AppBar(
        title: Text('Live Location Sharing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Status card
              _buildStatusCard(colorScheme),
              
              SizedBox(height: 24),
              
              // Main control button
              _buildControlButton(colorScheme),
              
              SizedBox(height: 32),
              
              // Current location info
              if (_isSharingLocation) _buildLocationInfo(colorScheme),
              
              SizedBox(height: 24),
              
              // Contact selection
              _buildContactSelection(colorScheme),
              
              SizedBox(height: 24),
              
              // Duration and sharing info
              if (_isSharingLocation) _buildSharingInfo(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isSharingLocation 
            ? Colors.blue.withOpacity(0.1) 
            : colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSharingLocation ? Colors.blue : colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isSharingLocation ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                child: Icon(
                  _isSharingLocation ? Icons.location_on : Icons.location_off,
                  color: _isSharingLocation ? Colors.blue : colorScheme.onSurface.withOpacity(0.6),
                  size: 32,
                ),
              );
            },
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSharingLocation ? 'Location Sharing Active' : 'Location Sharing Disabled',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isSharingLocation ? Colors.blue : colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _isSharingLocation 
                      ? 'Your location is being shared with selected contacts'
                      : 'Share your live location with emergency contacts',
                  style: TextStyle(
                    color: (_isSharingLocation ? Colors.blue : colorScheme.onSurface).withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(ColorScheme colorScheme) {
    return Center(
      child: GestureDetector(
        onTap: _isSharingLocation ? _stopLocationSharing : _startLocationSharing,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isSharingLocation ? 1.0 + (_pulseController.value * 0.02) : 1.0,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSharingLocation ? Colors.red.shade500 : Colors.blue.shade500,
                  boxShadow: [
                    BoxShadow(
                      color: (_isSharingLocation ? Colors.red : Colors.blue).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: _isSharingLocation ? 8 : 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSharingLocation ? Icons.stop : Icons.location_on,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _isSharingLocation ? 'STOP' : 'START',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'SHARING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationInfo(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, color: colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (_isLoadingLocation)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Getting location...'),
              ],
            )
          else
            Text(
              _currentAddress ?? 'Location unavailable',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          SizedBox(height: 8),
          Text(
            'Updates every 30 seconds',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSelection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Share with Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            if (_allContacts.isNotEmpty)
              TextButton(
                onPressed: _isSharingLocation ? null : _toggleAllContacts,
                child: Text(_selectedContacts.length == _allContacts.length ? 'Deselect All' : 'Select All'),
              ),
          ],
        ),
        
        if (_allContacts.isEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No emergency contacts added. Add contacts to share location.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allContacts.length,
              itemBuilder: (context, index) {
                final contact = _allContacts[index];
                final isSelected = _selectedContacts.contains(contact);
                
                return CheckboxListTile(
                  enabled: !_isSharingLocation,
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedContacts.add(contact);
                      } else {
                        _selectedContacts.remove(contact);
                      }
                    });
                  },
                  title: Text(contact.name),
                  subtitle: Text(contact.getFormattedPhoneNumber()),
                  secondary: CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      contact.getRelationshipIcon(),
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSharingInfo(ColorScheme colorScheme) {
    final duration = _sharingStartTime != null 
        ? DateTime.now().difference(_sharingStartTime!)
        : Duration.zero;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Duration',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.blue.shade300,
              ),
              Column(
                children: [
                  Text(
                    '${_selectedContacts.length}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Contacts',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Location shared with: ${_selectedContacts.map((c) => c.name).join(', ')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAllContacts() {
    setState(() {
      if (_selectedContacts.length == _allContacts.length) {
        _selectedContacts.clear();
      } else {
        _selectedContacts = List.from(_allContacts);
      }
    });
  }

  Future<bool?> _showStopConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop Location Sharing?'),
        content: Text(
          'Are you sure you want to stop sharing your location? '
          'Your contacts will no longer receive location updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Continue Sharing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Stop Sharing', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoContactsSelectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Contacts Selected'),
          ],
        ),
        content: Text(
          'Please select at least one contact to share your location with.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}