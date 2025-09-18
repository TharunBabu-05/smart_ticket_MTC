import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/safety_service.dart';
import '../services/location_service.dart';
import '../models/emergency_contact_model.dart';
import 'emergency_contacts_screen.dart';

class EmergencySOSScreen extends StatefulWidget {
  @override
  _EmergencySOSScreenState createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with TickerProviderStateMixin {
  final SafetyService _safetyService = SafetyService();
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  
  bool _isSosActive = false;
  bool _isCountingDown = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  List<EmergencyContact> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _countdownController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    final contacts = await _safetyService.getEmergencyContacts();
    setState(() {
      _emergencyContacts = contacts;
    });
  }

  void _startSOSCountdown() {
    if (_emergencyContacts.isEmpty) {
      _showNoContactsDialog();
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 5;
    });

    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    _countdownController.reset();
    _countdownController.forward();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      // Haptic feedback each second
      HapticFeedback.selectionClick();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  void _cancelSOSCountdown() {
    setState(() {
      _isCountingDown = false;
      _countdownSeconds = 5;
    });
    _countdownTimer?.cancel();
    _countdownController.reset();
    HapticFeedback.lightImpact();
  }

  Future<void> _activateSOS() async {
    setState(() {
      _isCountingDown = false;
      _isSosActive = true;
    });

    _pulseController.repeat();
    HapticFeedback.heavyImpact();

    try {
      await _safetyService.activateEmergencySOS();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Emergency SOS activated! Contacts notified.'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to activate SOS: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSosActive = false;
      });
      _pulseController.stop();
    }
  }

  Future<void> _deactivateSOS() async {
    final shouldDeactivate = await _showDeactivateConfirmation();
    if (shouldDeactivate == true) {
      setState(() {
        _isSosActive = false;
      });
      _pulseController.stop();
      
      try {
        await _safetyService.deactivateEmergencySOS();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Emergency SOS deactivated'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate SOS: $e'),
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
      backgroundColor: _isSosActive ? Colors.red.shade900 : colorScheme.surface,
      appBar: AppBar(
        title: Text('Emergency SOS'),
        backgroundColor: _isSosActive ? Colors.red.shade900 : Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.contacts),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
            ).then((_) => _loadEmergencyContacts()),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Status indicator
              _buildStatusIndicator(colorScheme),
              
              SizedBox(height: 40),
              
              // Main SOS button
              Expanded(
                child: Center(
                  child: _buildSOSButton(colorScheme),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Instructions and info
              _buildInstructions(colorScheme),
              
              SizedBox(height: 20),
              
              // Emergency contacts preview
              _buildContactsPreview(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme colorScheme) {
    if (_isSosActive) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 24,
                  ),
                );
              },
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOS ACTIVE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Emergency contacts notified • Location sharing active',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: Colors.green, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Safety services ready',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _isSosActive ? _deactivateSOS : (_isCountingDown ? _cancelSOSCountdown : _startSOSCountdown),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isSosActive ? 1.0 + (_pulseController.value * 0.05) : 1.0,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSosActive 
                    ? Colors.red.shade600 
                    : (_isCountingDown ? Colors.orange.shade600 : Colors.red.shade500),
                boxShadow: [
                  BoxShadow(
                    color: (_isSosActive ? Colors.red : Colors.red.shade300).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: _isSosActive ? 10 : 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isCountingDown) ...[
                    AnimatedBuilder(
                      animation: _countdownController,
                      builder: (context, child) {
                        return Text(
                          '$_countdownSeconds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Text(
                      'TAP TO CANCEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      _isSosActive ? Icons.stop : Icons.emergency,
                      color: Colors.white,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isSosActive ? 'DEACTIVATE' : 'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isSosActive ? 'Tap to stop alert' : 'Hold for emergency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'How SOS Works',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInstructionStep('1', 'Tap SOS button to start 5-second countdown', colorScheme),
          _buildInstructionStep('2', 'Your location is shared with emergency contacts', colorScheme),
          _buildInstructionStep('3', 'Automatic alerts sent via app and SMS', colorScheme),
          _buildInstructionStep('4', 'Continuous location tracking until deactivated', colorScheme),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String text, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsPreview(ColorScheme colorScheme) {
    if (_emergencyContacts.isEmpty) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
        ).then((_) => _loadEmergencyContacts()),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No emergency contacts added',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      'Tap to add contacts for SOS alerts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emergency Contacts (${_emergencyContacts.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
              ).then((_) => _loadEmergencyContacts()),
              child: Text('Manage'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _emergencyContacts.take(5).length,
            itemBuilder: (context, index) {
              final contact = _emergencyContacts[index];
              return Container(
                margin: EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      contact.name.split(' ').first,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _showDeactivateConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deactivate SOS?'),
        content: Text(
          'Are you sure you want to deactivate the emergency SOS? '
          'This will stop location sharing and alert notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Emergency Contacts'),
          ],
        ),
        content: Text(
          'You need to add at least one emergency contact before using SOS. '
          'Would you like to add contacts now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
              ).then((_) => _loadEmergencyContacts());
            },
            child: Text('Add Contacts'),
          ),
        ],
      ),
    );
  }
}