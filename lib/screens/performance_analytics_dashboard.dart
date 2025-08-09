import 'package:flutter/material.dart';
import '../services/performance_service.dart';
import 'dart:async';

/// Performance Analytics Dashboard for Phase 2 UI
class PerformanceAnalyticsDashboard extends StatefulWidget {
  @override
  _PerformanceAnalyticsDashboardState createState() => _PerformanceAnalyticsDashboardState();
}

class _PerformanceAnalyticsDashboardState extends State<PerformanceAnalyticsDashboard>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _chartController;
  
  // Performance data
  Map<String, dynamic> _performanceMetrics = {};
  List<Map<String, dynamic>> _recentErrors = [];
  Map<String, dynamic> _appUsageStats = {};
  bool _isLoading = true;
  
  // Real-time updates
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPerformanceData();
    _startRealTimeUpdates();
  }
  
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _slideController.forward();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    _chartController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadPerformanceData() async {
    try {
      // Simulate loading performance data
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _performanceMetrics = {
          'appStartTime': 2.3,
          'averageResponseTime': 150,
          'memoryUsage': 64.2,
          'cpuUsage': 23.5,
          'networkRequests': 1247,
          'crashRate': 0.02,
          'userSatisfaction': 4.6,
          'batteryImpact': 'Low',
        };
        
        _recentErrors = [
          {
            'timestamp': DateTime.now().subtract(Duration(hours: 2)),
            'error': 'Network timeout in ticket booking',
            'frequency': 3,
            'severity': 'Medium',
          },
          {
            'timestamp': DateTime.now().subtract(Duration(hours: 5)),
            'error': 'GPS location permission denied',
            'frequency': 7,
            'severity': 'High',
          },
          {
            'timestamp': DateTime.now().subtract(Duration(hours: 8)),
            'error': 'Firebase connection lost',
            'frequency': 2,
            'severity': 'Low',
          },
        ];
        
        _appUsageStats = {
          'dailyActiveUsers': 1543,
          'sessionDuration': 8.7,
          'screenViews': 12450,
          'ticketsBooked': 892,
          'fraudDetected': 5,
        };
        
        _isLoading = false;
      });
      
      _progressController.forward();
      _chartController.forward();
    } catch (e) {
      print('Error loading performance data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _startRealTimeUpdates() {
    _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadPerformanceData();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(colorScheme),
                    _buildOverviewMetrics(colorScheme),
                    _buildPerformanceCharts(colorScheme),
                    _buildErrorAnalysis(colorScheme),
                    _buildUsageStats(colorScheme),
                    _buildOptimizationTips(colorScheme),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildHeader(ColorScheme colorScheme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade600,
              Colors.purple.shade800,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time app performance insights',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'HEALTHY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monitoring Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
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
        ),
      ),
    );
  }
  
  Widget _buildOverviewMetrics(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'App Start Time',
                  value: '${_performanceMetrics['appStartTime']}s',
                  subtitle: 'Cold start average',
                  color: Colors.blue,
                  icon: Icons.rocket_launch,
                  progress: (_performanceMetrics['appStartTime'] ?? 0) / 5.0,
                  isGood: (_performanceMetrics['appStartTime'] ?? 0) < 3.0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Response Time',
                  value: '${_performanceMetrics['averageResponseTime']}ms',
                  subtitle: 'API calls average',
                  color: Colors.green,
                  icon: Icons.speed,
                  progress: (_performanceMetrics['averageResponseTime'] ?? 0) / 500.0,
                  isGood: (_performanceMetrics['averageResponseTime'] ?? 0) < 200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Memory Usage',
                  value: '${_performanceMetrics['memoryUsage']}MB',
                  subtitle: 'Current consumption',
                  color: Colors.orange,
                  icon: Icons.memory,
                  progress: (_performanceMetrics['memoryUsage'] ?? 0) / 128.0,
                  isGood: (_performanceMetrics['memoryUsage'] ?? 0) < 80,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Crash Rate',
                  value: '${(_performanceMetrics['crashRate'] ?? 0) * 100}%',
                  subtitle: 'Last 7 days',
                  color: Colors.red,
                  icon: Icons.error_outline,
                  progress: (_performanceMetrics['crashRate'] ?? 0),
                  isGood: (_performanceMetrics['crashRate'] ?? 0) < 0.01,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required double progress,
    required bool isGood,
  }) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isGood ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress * _progressController.value,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPerformanceCharts(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Trends',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSimpleChart(colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildSimpleChart(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _chartController,
      builder: (context, child) {
        return Container(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final height = (60 + (index * 10) + (index.isEven ? 20 : -10)) * _chartController.value;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 20,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Day ${index + 1}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildErrorAnalysis(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Errors',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentErrors.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Recent Errors!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your app is running smoothly',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentErrors.length,
              itemBuilder: (context, index) {
                final error = _recentErrors[index];
                return _buildErrorCard(error, colorScheme);
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildErrorCard(Map<String, dynamic> error, ColorScheme colorScheme) {
    Color severityColor;
    switch (error['severity']) {
      case 'High':
        severityColor = Colors.red;
        break;
      case 'Medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error['error'],
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error['severity'].toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Frequency: ${error['frequency']} times',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          Text(
            'Last occurrence: ${_formatTime(error['timestamp'])}',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsageStats(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Statistics',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUsageItem(
                  'Daily Active Users',
                  '${_appUsageStats['dailyActiveUsers']}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageItem(
                  'Avg Session',
                  '${_appUsageStats['sessionDuration']}min',
                  Icons.timer,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUsageItem(
                  'Tickets Booked',
                  '${_appUsageStats['ticketsBooked']}',
                  Icons.confirmation_number,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageItem(
                  'Fraud Detected',
                  '${_appUsageStats['fraudDetected']}',
                  Icons.security,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsageItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptimizationTips(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimization Recommendations',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptimizationTip(
            'Reduce Memory Usage',
            'Consider implementing image caching optimization',
            Icons.memory,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildOptimizationTip(
            'Improve Response Time',
            'Implement request batching for API calls',
            Icons.speed,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildOptimizationTip(
            'Error Prevention',
            'Add better network error handling',
            Icons.error_outline,
            Colors.red,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptimizationTip(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          color: color.withOpacity(0.5),
          size: 16,
        ),
      ],
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
