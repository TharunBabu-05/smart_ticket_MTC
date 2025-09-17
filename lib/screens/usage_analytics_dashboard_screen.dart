import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/enhanced_ticket_model.dart';
import '../services/enhanced_ticket_service.dart';
import '../services/personalization_service.dart';

/// Usage Analytics Dashboard Screen
class UsageAnalyticsDashboardScreen extends StatefulWidget {
  @override
  _UsageAnalyticsDashboardScreenState createState() => _UsageAnalyticsDashboardScreenState();
}

class _UsageAnalyticsDashboardScreenState extends State<UsageAnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<EnhancedTicket> _tickets = [];
  Map<String, double> _expensesByMonth = {};
  Map<String, int> _tripsByRoute = {};
  bool _isLoading = true;
  
  // Analytics data
  double _totalSpent = 0.0;
  int _totalTrips = 0;
  double _averageFare = 0.0;
  String _mostUsedRoute = '';
  String _preferredTime = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user tickets for analytics
      _tickets = await EnhancedTicketService.getUserTickets();
      
      // Calculate analytics
      _calculateAnalytics();
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateAnalytics() {
    if (_tickets.isEmpty) return;

    // Total calculations
    _totalSpent = _tickets.fold(0.0, (sum, ticket) => sum + ticket.fare);
    _totalTrips = _tickets.length;
    _averageFare = _totalSpent / _totalTrips;

    // Monthly expenses
    _expensesByMonth.clear();
    for (final ticket in _tickets) {
      final monthKey = DateFormat('MMM yyyy').format(ticket.issueTime);
      _expensesByMonth[monthKey] = (_expensesByMonth[monthKey] ?? 0.0) + ticket.fare;
    }

    // Route usage
    _tripsByRoute.clear();
    for (final ticket in _tickets) {
      final route = '${ticket.sourceName} → ${ticket.destinationName}';
      _tripsByRoute[route] = (_tripsByRoute[route] ?? 0) + 1;
    }

    // Most used route
    if (_tripsByRoute.isNotEmpty) {
      _mostUsedRoute = _tripsByRoute.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Preferred time analysis
    final timeSlots = <String, int>{};
    for (final ticket in _tickets) {
      final hour = ticket.issueTime.hour;
      String timeSlot;
      if (hour >= 6 && hour < 12) {
        timeSlot = 'Morning (6-12)';
      } else if (hour >= 12 && hour < 18) {
        timeSlot = 'Afternoon (12-18)';
      } else if (hour >= 18 && hour < 24) {
        timeSlot = 'Evening (18-24)';
      } else {
        timeSlot = 'Night (24-6)';
      }
      timeSlots[timeSlot] = (timeSlots[timeSlot] ?? 0) + 1;
    }

    if (timeSlots.isNotEmpty) {
      _preferredTime = timeSlots.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Spent',
                  '₹${_totalSpent.toStringAsFixed(2)}',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Trips',
                  _totalTrips.toString(),
                  Icons.directions_bus,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Average Fare',
                  '₹${_averageFare.toStringAsFixed(2)}',
                  Icons.calculate,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'This Month',
                  _getCurrentMonthExpense(),
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Insights Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, color: Colors.blue.shade600),
                      SizedBox(width: 8),
                      Text(
                        'Travel Insights',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  _buildInsightItem(
                    Icons.route,
                    'Most Used Route',
                    _mostUsedRoute.isEmpty ? 'No data' : _mostUsedRoute,
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildInsightItem(
                    Icons.schedule,
                    'Preferred Travel Time',
                    _preferredTime.isEmpty ? 'No data' : _preferredTime,
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildInsightItem(
                    Icons.savings,
                    'Money Saved vs Taxi',
                    _calculateSavings(),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Recent Activity
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.orange.shade600),
                      SizedBox(width: 8),
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  ..._tickets.take(5).map((ticket) => _buildRecentActivityItem(ticket)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                Spacer(),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityItem(EnhancedTicket ticket) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.confirmation_number,
              color: Colors.blue[600],
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ticket.sourceName} → ${ticket.destinationName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(ticket.issueTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${ticket.fare.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    if (_expensesByMonth.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No expense data available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final sortedEntries = _expensesByMonth.entries.toList()
      ..sort((a, b) => DateFormat('MMM yyyy').parse(a.key).compareTo(DateFormat('MMM yyyy').parse(b.key)));

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Expenses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          Container(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('₹${value.toInt()}');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedEntries.length) {
                          return Text(
                            sortedEntries[index].key.split(' ')[0],
                            style: TextStyle(fontSize: 12),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedEntries.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteChart() {
    if (_tripsByRoute.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No route data available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final sortedRoutes = _tripsByRoute.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topRoutes = sortedRoutes.take(5).toList();

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Routes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          Container(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: topRoutes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final route = entry.value;
                  final percentage = (route.value / _totalTrips) * 100;
                  
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: route.value.toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Legend
          Column(
            children: topRoutes.asMap().entries.map((entry) {
              final index = entry.key;
              final route = entry.value;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        route.key,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '${route.value} trips',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Comparison',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          _buildComparisonCard(
            'Bus vs Taxi',
            _totalSpent,
            _totalSpent * 8, // Assume taxi is 8x more expensive
            'You saved ₹${(_totalSpent * 7).toStringAsFixed(2)}',
            Colors.green,
          ),
          
          SizedBox(height: 16),
          
          _buildComparisonCard(
            'Bus vs Auto',
            _totalSpent,
            _totalSpent * 4, // Assume auto is 4x more expensive
            'You saved ₹${(_totalSpent * 3).toStringAsFixed(2)}',
            Colors.blue,
          ),
          
          SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Environmental Impact',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnvironmentalStat(
                          'CO₂ Saved',
                          '${(_totalTrips * 2.5).toStringAsFixed(1)} kg',
                          Icons.cloud,
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildEnvironmentalStat(
                          'Trees Equivalent',
                          '${(_totalTrips * 0.1).toStringAsFixed(1)}',
                          Icons.park,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(String title, double busAmount, double altAmount, String savings, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.blue, size: 32),
                      SizedBox(height: 8),
                      Text(
                        '₹${busAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text('Bus', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        title.contains('Taxi') ? Icons.local_taxi : Icons.motorcycle,
                        color: Colors.red,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '₹${altAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        title.contains('Taxi') ? 'Taxi' : 'Auto',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings, color: color),
                  SizedBox(width: 8),
                  Text(
                    savings,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildEnvironmentalStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCurrentMonthExpense() {
    final currentMonth = DateFormat('MMM yyyy').format(DateTime.now());
    final expense = _expensesByMonth[currentMonth] ?? 0.0;
    return '₹${expense.toStringAsFixed(2)}';
  }

  String _calculateSavings() {
    final savings = _totalSpent * 7; // Approximate savings vs taxi
    return '₹${savings.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usage Analytics'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Expenses'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Routes'),
            Tab(icon: Icon(Icons.compare), text: 'Compare'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildExpenseChart(),
                _buildRouteChart(),
                _buildComparisonTab(),
              ],
            ),
    );
  }
}