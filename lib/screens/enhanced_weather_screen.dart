import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../themes/app_theme.dart';

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
    
    return ThemedScaffold(
      title: 'Weather Forecast',
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.getPrimaryTextColor(context)),
          onPressed: _loadWeatherData,
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: AppTheme.getPrimaryTextColor(context)),
          onPressed: () {},
        ),
      ],
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
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location and current time with enhanced styling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chennai, Tamil Nadu',
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d • h:mm a').format(DateTime.now()),
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getWeatherConditionColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getWeatherConditionColor().withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: _getWeatherConditionColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 32),
          
          // Temperature and condition with enhanced layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                            color: AppTheme.getPrimaryTextColor(context),
                            fontSize: 64,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getWeatherConditionColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getWeatherEmoji(_currentWeather!.condition),
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    Text(
                      _currentWeather!.description.toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.getPrimaryTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    
                    SizedBox(height: 6),
                    
                    Text(
                      'Feels like ${_currentWeather!.feelsLike.round()}°',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Weather stats with modern cards
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildEnhancedWeatherStat(
                    Icons.water_drop_outlined,
                    '${_getPrecipitationChance()}%',
                    'Precipitation',
                    colorScheme,
                  ),
                  SizedBox(height: 12),
                  _buildEnhancedWeatherStat(
                    Icons.opacity,
                    '${_currentWeather!.humidity}%',
                    'Humidity',
                    colorScheme,
                  ),
                  SizedBox(height: 12),
                  _buildEnhancedWeatherStat(
                    Icons.air,
                    '${_currentWeather!.windSpeed.round()} km/h',
                    'Wind Speed',
                    colorScheme,
                  ),
                  SizedBox(height: 12),
                  _buildEnhancedWeatherStat(
                    Icons.visibility_outlined,
                    'Good',
                    'Air Quality',
                    colorScheme,
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
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Hourly Forecast',
              style: TextStyle(
                color: AppTheme.getPrimaryTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4),
              itemCount: _hourlyForecast!.length,
              itemBuilder: (context, index) {
                final forecast = _hourlyForecast![index];
                final time = forecast['time'] as DateTime;
                final isNow = index == 0;
                
                return Container(
                  width: 80,
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.all(12),
                  decoration: isNow
                      ? AppTheme.createCardDecoration(context).copyWith(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.blue.withOpacity(0.1),
                              Colors.blue.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1.5,
                          ),
                        )
                      : AppTheme.createCardDecoration(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Time
                      Text(
                        isNow ? 'NOW' : DateFormat('h a').format(time).toLowerCase(),
                        style: TextStyle(
                          color: isNow 
                              ? Colors.blue 
                              : AppTheme.getSecondaryTextColor(context),
                          fontSize: 12,
                          fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      
                      // Weather icon with enhanced styling
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getWeatherConditionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getWeatherEmoji(forecast['condition']),
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      
                      // Precipitation percentage with icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            size: 10,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${forecast['precipitation']}%',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      // Temperature
                      Text(
                        '${forecast['temperature']}°',
                        style: TextStyle(
                          color: AppTheme.getPrimaryTextColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast(ColorScheme colorScheme) {
    if (_weeklyForecast == null || _weeklyForecast!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast',
            style: TextStyle(
              color: AppTheme.getPrimaryTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          ...(_weeklyForecast!.asMap().entries.map<Widget>((entry) {
            final index = entry.key;
            final day = entry.value;
            final isToday = day.dateTime.day == DateTime.now().day;
            final isLast = index == _weeklyForecast!.length - 1;
            
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isToday 
                        ? Colors.blue.withOpacity(0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday 
                        ? Border.all(color: Colors.blue.withOpacity(0.2), width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Day name with enhanced styling
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? 'Today' : day.dayName,
                              style: TextStyle(
                                color: isToday 
                                    ? Colors.blue 
                                    : AppTheme.getPrimaryTextColor(context),
                                fontSize: 16,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            if (isToday) ...[
                              SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d').format(day.dateTime),
                                style: TextStyle(
                                  color: AppTheme.getSecondaryTextColor(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Weather condition with enhanced icon container
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getWeatherConditionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getWeatherEmoji(day.condition),
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      
                      SizedBox(width: 16),
                      
                      // Precipitation with icon
                      Container(
                        width: 50,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 14,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${(index * 10 + 10)}%', // Simulate precipitation
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(width: 16),
                      
                      // Temperature range with enhanced styling
                      Container(
                        width: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${day.minTemp.round()}°',
                              style: TextStyle(
                                color: AppTheme.getSecondaryTextColor(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 3,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.3),
                                    Colors.orange.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              '${day.maxTemp.round()}°',
                              style: TextStyle(
                                color: AppTheme.getPrimaryTextColor(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) 
                  Divider(
                    color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
                    height: 1,
                    thickness: 1,
                  ),
              ],
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails(ColorScheme colorScheme) {
    if (_currentWeather == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: AppTheme.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: TextStyle(
              color: AppTheme.getPrimaryTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          
          // Enhanced Details Grid
          Row(
            children: [
              Expanded(
                child: _buildEnhancedDetailItem(
                  Icons.water_drop_outlined,
                  'Humidity',
                  '${_currentWeather!.humidity}%',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedDetailItem(
                  Icons.air_outlined,
                  'Wind Speed',
                  '${_currentWeather!.windSpeed.round()} km/h',
                  Colors.grey,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildEnhancedDetailItem(
                  Icons.compress,
                  'Pressure',
                  '1013 hPa', // Simulated pressure
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedDetailItem(
                  Icons.wb_sunny_outlined,
                  'UV Index',
                  '6 (High)',
                  Colors.red,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildEnhancedDetailItem(
                  Icons.visibility_outlined,
                  'Visibility',
                  '10 km',
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedDetailItem(
                  Icons.thermostat_outlined,
                  'Feels Like',
                  '${(_currentWeather!.temperature + 2).round()}°C',
                  Colors.purple,
                ),
              ),
            ],
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

  Widget _buildEnhancedDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.getPrimaryTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(32),
        decoration: AppTheme.createCardDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading weather data...',
              style: TextStyle(
                color: AppTheme.getPrimaryTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Getting the latest forecast for you',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(32),
        decoration: AppTheme.createCardDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                color: Colors.red,
                size: 48,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Unable to load weather data',
              style: TextStyle(
                color: AppTheme.getPrimaryTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'Please check your internet connection and try again',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWeatherData,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
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

  Color _getWeatherConditionColor() {
    if (_currentWeather == null) return Colors.blue;
    
    switch (_currentWeather!.condition.toLowerCase()) {
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'drizzle':
      case 'rain':
        return Colors.indigo;
      case 'snow':
        return Colors.lightBlue;
      case 'mist':
      case 'fog':
        return Colors.grey;
      case 'clear':
        return DateTime.now().hour >= 6 && DateTime.now().hour < 18 
            ? Colors.orange 
            : Colors.deepPurple;
      case 'clouds':
        return Colors.blueGrey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildEnhancedWeatherStat(IconData icon, String value, String label, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryTextColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getPrimaryTextColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.getPrimaryTextColor(context),
            size: 16,
          ),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.getPrimaryTextColor(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
