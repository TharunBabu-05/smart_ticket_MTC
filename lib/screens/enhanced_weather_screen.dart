import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';

class EnhancedWeatherScreen extends StatefulWidget {
  @override
  _EnhancedWeatherScreenState createState() => _EnhancedWeatherScreenState();
}

class _EnhancedWeatherScreenState extends State<EnhancedWeatherScreen>
    with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService.instance;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late TabController _tabController;
  
  WeatherData? _currentWeather;
  List<Map<String, dynamic>>? _hourlyForecast;
  List<WeatherForecast>? _weeklyForecast;
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _tabController = TabController(length: 4, vsync: this);
    _loadWeatherData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final current = await _weatherService.getCurrentWeather();
      final forecast = await _weatherService.getWeeklyForecast();
      
      setState(() {
        _currentWeather = current;
        _weeklyForecast = forecast;
        _hourlyForecast = _generateHourlyForecast();
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateHourlyForecast() {
    // Generate 24-hour forecast based on current weather
    List<Map<String, dynamic>> hourly = [];
    DateTime now = DateTime.now();
    
    for (int i = 0; i < 24; i++) {
      DateTime hour = now.add(Duration(hours: i));
      double tempVariation = (i * 2 - 12).abs() / 12; // Temperature variation
      double baseTemp = _currentWeather?.temperature ?? 25.0;
      
      hourly.add({
        'time': hour,
        'temperature': (baseTemp - tempVariation * 3).round(),
        'condition': _currentWeather?.condition ?? 'Clear',
        'precipitation': (i % 4 == 0) ? (30 + i * 2) : (10 + i),
        'icon': _currentWeather?.icon ?? '01d',
      });
    }
    
    return hourly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(colorScheme)
          : _error != null
              ? _buildErrorState(colorScheme)
              : _buildGoogleStyleWeatherContent(colorScheme),
    );
  }

  Widget _buildGoogleStyleWeatherContent(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadWeatherData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Weather Header
            _buildCurrentWeatherHeader(colorScheme),
            
            // Hourly Forecast Tabs
            _buildTabSection(colorScheme),
            
            // Hourly Forecast
            _buildHourlyForecast(colorScheme),
            
            // Daily Forecast
            _buildDailyForecast(colorScheme),
            
            // Weather Details
            _buildWeatherDetails(colorScheme),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherHeader(ColorScheme colorScheme) {
    if (_currentWeather == null) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location and current time
          Text(
            'Chennai', // You can make this dynamic
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Now',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          
          SizedBox(height: 24),
          
          // Temperature and condition
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentWeather!.temperature.round()}°',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 72,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          child: Text(
                            _getWeatherEmoji(_currentWeather!.condition),
                            style: TextStyle(fontSize: 48),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    Text(
                      _currentWeather!.description,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: 4),
                    
                    Text(
                      'Feels like ${_currentWeather!.feelsLike.round()}°',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Weather stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildWeatherStat(
                    'Precip: ${_getPrecipitationChance()}%',
                    colorScheme,
                  ),
                  SizedBox(height: 4),
                  _buildWeatherStat(
                    'Humidity: ${_currentWeather!.humidity}%',
                    colorScheme,
                  ),
                  SizedBox(height: 4),
                  _buildWeatherStat(
                    'Wind: ${_currentWeather!.windSpeed.round()} km/h',
                    colorScheme,
                  ),
                  SizedBox(height: 4),
                  _buildWeatherStat(
                    'Air quality: Satisfactory',
                    colorScheme,
                    showDot: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(String text, ColorScheme colorScheme, {bool showDot = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getPrecipitationChance() {
    // Simulate precipitation chance based on weather condition
    final condition = _currentWeather?.condition.toLowerCase() ?? '';
    if (condition.contains('rain') || condition.contains('storm')) {
      return '70';
    } else if (condition.contains('cloud')) {
      return '30';
    }
    return '10';
  }

  Widget _buildTabSection(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        indicatorColor: colorScheme.primary,
        indicatorWeight: 2,
        tabs: [
          Tab(text: 'Overview'),
          Tab(text: 'Precipitation'),
          Tab(text: 'Wind'),
          Tab(text: 'Humidity'),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(ColorScheme colorScheme) {
    if (_hourlyForecast == null || _hourlyForecast!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 160,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _hourlyForecast!.length,
        itemBuilder: (context, index) {
          final forecast = _hourlyForecast![index];
          final time = forecast['time'] as DateTime;
          final isNow = index == 0;
          
          return Container(
            width: 80,
            margin: EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Time
                Text(
                  isNow ? 'NOW' : DateFormat('h a').format(time).toLowerCase(),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: isNow ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                
                // Precipitation percentage
                Text(
                  '${forecast['precipitation']}%',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Weather icon
                Text(
                  _getWeatherEmoji(forecast['condition']),
                  style: TextStyle(fontSize: 24),
                ),
                
                // Temperature
                Text(
                  '${forecast['temperature']}°',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyForecast(ColorScheme colorScheme) {
    if (_weeklyForecast == null || _weeklyForecast!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: _weeklyForecast!.map<Widget>((day) {
          final isToday = day.dateTime.day == DateTime.now().day;
          
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Day name
                Expanded(
                  flex: 2,
                  child: Text(
                    isToday ? 'Today' : day.dayName,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                
                // Weather icon
                Text(
                  _getWeatherEmoji(day.condition),
                  style: TextStyle(fontSize: 20),
                ),
                
                SizedBox(width: 16),
                
                // Precipitation
                Container(
                  width: 40,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'N/A%', // Precipitation not available in WeatherForecast
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                SizedBox(width: 24),
                
                // Temperature range
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${day.maxTemp.round()}°',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${day.minTemp.round()}°',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeatherDetails(ColorScheme colorScheme) {
    if (_currentWeather == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Details Grid
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Humidity',
                  '${_currentWeather!.humidity}%',
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Wind',
                  '${_currentWeather!.windSpeed.round()} km/h',
                  colorScheme,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Pressure',
                  'N/A', // Pressure not available in WeatherData
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'UV Index',
                  'N/A',
                  colorScheme,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // View all details button (similar to Google Weather)
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View all details',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading weather data...',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Unable to load weather data',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Please check your internet connection',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadWeatherData,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _getWeatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return '⛈️';
      case 'drizzle':
        return '🌦️';
      case 'rain':
        return '🌧️';
      case 'snow':
        return '🌨️';
      case 'mist':
      case 'fog':
        return '🌫️';
      case 'clear':
        return DateTime.now().hour >= 6 && DateTime.now().hour < 18 ? '☀️' : '🌙';
      case 'clouds':
        return '☁️';
      default:
        return '🌤️';
    }
  }
}
