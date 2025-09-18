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
    _loadWeatherData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildWeatherContent(),
    );
  }

  Color _getBackgroundColor() {
    if (_currentWeather == null) return Color(0xFF1E3A8A); // Default blue
    
    final condition = _currentWeather!.condition.toLowerCase();
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 18) {
      // Daytime colors
      if (condition.contains('rain') || condition.contains('storm')) {
        return Color(0xFF4B5563); // Dark gray for rain
      } else if (condition.contains('cloud')) {
        return Color(0xFF6B7280); // Gray for clouds
      } else {
        return Color(0xFF3B82F6); // Blue for clear
      }
    } else {
      // Nighttime colors
      return Color(0xFF1E293B); // Dark blue for night
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Loading weather data...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 64),
          SizedBox(height: 16),
          Text(
            'Unable to load weather data',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadWeatherData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadWeatherData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildCurrentWeather(),
                    _buildTabBar(),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Chennai, Tamil Nadu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadWeatherData,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Current temperature and condition
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_currentWeather?.temperature.round() ?? '--'}°',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w200,
                      height: 0.9,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      _getWeatherEmoji(_currentWeather?.condition ?? ''),
                      style: TextStyle(fontSize: 48),
                    ),
                  ),
                ],
              ),
              
              // Weather description
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentWeather?.description ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Feels like ${_currentWeather?.feelsLike.round() ?? '--'}°',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Weather details row
              _buildWeatherDetailsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsRow() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWeatherDetail(
            'Humidity',
            '${_currentWeather?.humidity ?? '--'}%',
            Icons.water_drop,
          ),
          _buildWeatherDetail(
            'Wind',
            '${_currentWeather?.windSpeed.round() ?? '--'} km/h',
            Icons.air,
          ),
          _buildWeatherDetail(
            'Pressure',
            'N/A', // Pressure not available in WeatherData
            Icons.speed,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabButton('Today', 0),
          _buildTabButton('7 Days', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return _selectedTabIndex == 0 ? _buildHourlyForecast() : _buildWeeklyForecast();
  }

  Widget _buildHourlyForecast() {
    if (_hourlyForecast == null) return Container();
    
    return Container(
      height: 120,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _hourlyForecast!.length,
        itemBuilder: (context, index) {
          final hour = _hourlyForecast![index];
          final time = hour['time'] as DateTime;
          final isNow = index == 0;
          
          return Container(
            width: 70,
            margin: EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  isNow ? 'Now' : DateFormat('HH:mm').format(time),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  _getWeatherEmoji(hour['condition']),
                  style: TextStyle(fontSize: 24),
                ),
                Text(
                  '${hour['temperature']}°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${hour['precipitation']}%',
                  style: TextStyle(
                    color: Colors.blue.shade200,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    if (_weeklyForecast == null) return Container();
    
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: _weeklyForecast!.map<Widget>((day) {
          final date = day.dateTime;
          final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                         DateFormat('yyyy-MM-dd').format(DateTime.now());
          
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    isToday ? 'Today' : DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  _getWeatherEmoji(day.condition),
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'N/A%', // Precipitation not available in WeatherForecast
                    style: TextStyle(
                      color: Colors.blue.shade200,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${day.maxTemp.round()}°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${day.minTemp.round()}°',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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