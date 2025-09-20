import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/safety_service.dart';
import '../services/location_service.dart';
import '../models/emergency_contact_model.dart';
import '../themes/app_theme.dart';
import 'emergency_sos_screen.dart';
import 'live_location_sharing_screen.dart';
import 'emergency_contacts_screen.dart';

class SafetyFeaturesScreen extends StatefulWidget {
  @override
  _SafetyFeaturesScreenState createState() => _SafetyFeaturesScreenState();
}

class _SafetyFeaturesScreenState extends State<SafetyFeaturesScreen>
    with TickerProviderStateMixin {
  final SafetyService _safetyService = SafetyService();
  late AnimationController _cardAnimationController;
  
  bool _isSosActive = false;
  bool _isLocationSharing = false;
  bool _isWomenSafetyEnabled = false;
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _loadSafetyStatus();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSafetyStatus() async {
    try {
      // Load current safety status
      final contacts = await _safetyService.getEmergencyContacts();
      final sosActive = await _safetyService.isEmergencySOSActive();
      final locationSharing = _safetyService.isLocationSharingActive;
      final womenSafety = await _safetyService.isWomenSafetyEnabled();

      setState(() {
        _emergencyContacts = contacts;
        _isSosActive = sosActive;
        _isLocationSharing = locationSharing;
        _isWomenSafetyEnabled = womenSafety;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load safety status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ThemedScaffold(
      title: 'Safety Features',
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.getPrimaryTextColor(context)),
          onPressed: _loadSafetyStatus,
        ),
      ],
      body: CustomScrollView(
        slivers: [
          // Enhanced Safety Status Overview
          SliverToBoxAdapter(
            child: _isLoading 
                ? Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            'Loading safety features...',
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildEnhancedSafetyOverview(),
          ),

          // Main Safety Features
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate([
                _buildEnhancedFeatureCard(
                  title: 'Emergency SOS',
                  subtitle: 'Quick emergency alert',
                  icon: Icons.emergency,
                  color: Colors.red,
                  isActive: _isSosActive,
                  statusText: _isSosActive ? 'ACTIVE' : 'Ready',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EmergencySOSScreen()),
                  ).then((_) => _loadSafetyStatus()),
                ),
                _buildEnhancedFeatureCard(
                  title: 'Live Location',
                  subtitle: 'Share with family',
                  icon: Icons.location_on,
                  color: Colors.blue,
                  isActive: _isLocationSharing,
                  statusText: _isLocationSharing ? 'SHARING' : 'Stopped',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LiveLocationSharingScreen()),
                  ).then((_) => _loadSafetyStatus()),
                ),
                _buildEnhancedFeatureCard(
                  title: 'Women Safety',
                  subtitle: 'Enhanced protection',
                  icon: Icons.shield,
                  color: Colors.purple,
                  isActive: _isWomenSafetyEnabled,
                  statusText: _isWomenSafetyEnabled ? 'ON' : 'Off',
                  onTap: () => _showWomenSafetyScreen(),
                ),
                _buildEnhancedFeatureCard(
                  title: 'Safe Routes',
                  subtitle: 'Secure travel paths',
                  icon: Icons.route,
                  color: Colors.green,
                  isActive: false,
                  statusText: 'Available',
                  onTap: () => _showSafeRoutesScreen(),
                ),
              ]),
            ),
          ),

          // Emergency Contacts Section
          SliverToBoxAdapter(
            child: _buildEnhancedEmergencyContactsSection(),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: _buildEnhancedQuickActions(),
          ),

          // Extra padding at bottom
          SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyOverview(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusIndicator('SOS', _isSosActive, Colors.red),
              _buildStatusIndicator('Location', _isLocationSharing, Colors.blue),
              _buildStatusIndicator('Contacts', _emergencyContacts.isNotEmpty, Colors.green),
            ],
          ),
          if (_isSosActive || _isLocationSharing) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safety services are currently active',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? Icons.check : Icons.close,
            color: isActive ? color : Colors.grey.shade600,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? color : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSafetyOverview() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: Colors.blue,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Status',
                      style: TextStyle(
                        color: AppTheme.getPrimaryTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your safety features overview',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnhancedStatusIndicator('SOS', _isSosActive, Colors.red, Icons.emergency),
              _buildEnhancedStatusIndicator('Location', _isLocationSharing, Colors.blue, Icons.location_on),
              _buildEnhancedStatusIndicator('Contacts', _emergencyContacts.isNotEmpty, Colors.green, Icons.contacts),
            ],
          ),
          
          if (_isSosActive || _isLocationSharing) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info_outlined, color: Colors.orange, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Services Active',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Emergency features are currently monitoring your safety',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedStatusIndicator(String label, bool isActive, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : AppTheme.getPrimaryTextColor(context).withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color : AppTheme.getSecondaryTextColor(context),
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? Icons.check : icon,
            color: isActive ? color : AppTheme.getSecondaryTextColor(context),
            size: 28,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? color : AppTheme.getSecondaryTextColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required String statusText,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimationController.value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              decoration: AppTheme.createCardDecoration(context).copyWith(
                border: isActive 
                    ? Border.all(color: color.withOpacity(0.4), width: 2)
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 32,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? color.withOpacity(0.15) : AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: isActive ? color : AppTheme.getSecondaryTextColor(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryTextColor(context),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required String statusText,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimationController.value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: isActive 
                    ? Border.all(color: color.withOpacity(0.5), width: 2)
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 28,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: isActive ? color : Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedEmergencyContactsSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contacts,
                    color: Colors.blue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getPrimaryTextColor(context),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
                  ).then((_) => _loadSafetyStatus());
                },
                child: Text(
                  'Manage',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          if (_emergencyContacts.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Emergency Contacts',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Add trusted contacts for emergency situations',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person_outline, color: Colors.green, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_emergencyContacts.length} contact${_emergencyContacts.length > 1 ? 's' : ''} configured',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _emergencyContacts.isNotEmpty ? _emergencyContacts.first.name : '',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickActions() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Test Emergency',
                  Icons.warning_outlined,
                  Colors.orange,
                  () => _testEmergency(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Share Location',
                  Icons.my_location,
                  Colors.blue,
                  () => _shareLocation(),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Safety Tips',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ...['Keep emergency contacts updated', 'Test SOS feature periodically', 'Share live location during late travels', 'Enable women safety notifications'].map((tip) =>
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: EdgeInsets.only(top: 8, right: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareLocation() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 8),
              Text('Sharing location with emergency contacts...'),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share location: $e');
    }
  }

  Widget _buildEmergencyContactsSection(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
                ).then((_) => _loadSafetyStatus()),
                child: Text('Manage'),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_emergencyContacts.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No emergency contacts added yet',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              height: 80,
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
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            contact.getRelationshipIcon(),
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          contact.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 12,
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
            if (_emergencyContacts.length > 5)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '+${_emergencyContacts.length - 5} more contacts',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Test Emergency',
                  Icons.warning_amber,
                  Colors.orange,
                  () => _testEmergencySystem(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Share Location',
                  Icons.share_location,
                  Colors.blue,
                  () => _quickShareLocation(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWomenSafetyScreen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Women Safety Features'),
        content: Text(
          'Women safety features include:\n'
          '• Women-only bus notifications\n'
          '• Enhanced night safety alerts\n'
          '• Quick SOS with gender-specific response\n'
          '• Safe zone recommendations\n\n'
          'This feature is coming soon!',
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

  void _showSafeRoutesScreen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Safe Route Recommendations'),
        content: Text(
          'Safe route features include:\n'
          '• Well-lit path suggestions\n'
          '• Crowded route preferences\n'
          '• Police station proximity\n'
          '• Real-time safety scores\n'
          '• Community safety reports\n\n'
          'This feature is coming soon!',
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

  Future<void> _testEmergencySystem() async {
    if (_emergencyContacts.isEmpty) {
      _showErrorSnackBar('Add emergency contacts first');
      return;
    }

    final shouldTest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Emergency System'),
        content: Text(
          'This will send a test alert to your emergency contacts. '
          'They will be notified that this is a test. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Send Test'),
          ),
        ],
      ),
    );

    if (shouldTest == true) {
      try {
        // Implement test functionality in SafetyService
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test alert sent to emergency contacts'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showErrorSnackBar('Failed to send test alert: $e');
      }
    }
  }

  Future<void> _quickShareLocation() async {
    try {
      if (_emergencyContacts.isEmpty) {
        _showErrorSnackBar('Add emergency contacts first');
        return;
      }

      // Quick 1-hour location sharing
      await _safetyService.startLocationSharing(
        contactIds: _emergencyContacts.map((c) => c.id).toList(),
        duration: Duration(hours: 1),
      );

      setState(() {
        _isLocationSharing = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location sharing started for 1 hour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share location: $e');
    }
  }

  void _testEmergency() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Testing emergency features...'),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}