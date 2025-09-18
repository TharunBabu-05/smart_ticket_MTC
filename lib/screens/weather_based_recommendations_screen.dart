import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../widgets/weather_forecast_widget.dart';

class WeatherBasedRecommendationsScreen extends StatefulWidget {
  const WeatherBasedRecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<WeatherBasedRecommendationsScreen> createState() => _WeatherBasedRecommendationsScreenState();
}

class _WeatherBasedRecommendationsScreenState extends State<WeatherBasedRecommendationsScreen> {
  final WeatherService _weatherService = WeatherService.instance;
  
  WeatherData? currentWeather;
  List<WeatherForecast> weeklyForecast = [];
  List<WeatherRecommendation> recommendations = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load current weather and weekly forecast
      final results = await Future.wait([
        _weatherService.getCurrentWeather(),
        _weatherService.getWeeklyForecast(),
      ]);

      setState(() {
        currentWeather = results[0] as WeatherData?;
        weeklyForecast = results[1] as List<WeatherForecast>;
        
        // Generate recommendations based on weather data
        if (currentWeather != null) {
          recommendations = _weatherService.getWeatherBasedRecommendations(
            currentWeather!,
            weeklyForecast,
          );
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load weather data. Please check your internet connection and location permissions.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather-Based Routes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
            tooltip: 'Refresh Weather',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWeatherData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading) ...[
                _buildLoadingWidget(),
              ] else if (errorMessage != null) ...[
                _buildErrorWidget(),
              ] else ...[
                // Weather Forecast Widget
                WeatherForecastWidget(
                  currentWeather: currentWeather,
                  forecast: weeklyForecast,
                ),
                
                const SizedBox(height: 24),
                
                // Route Recommendations Header
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Smart Route Recommendations',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Based on current and upcoming weather conditions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Weather-based Recommendations
                if (recommendations.isEmpty) ...[
                  _buildNoRecommendationsWidget(),
                ] else ...[
                  ...recommendations.map((recommendation) => 
                    WeatherRecommendationCard(recommendation: recommendation)
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Travel Tips Section
                _buildTravelTipsSection(),
                
                const SizedBox(height: 24),
                
                // Weather Alerts Section
                if (currentWeather != null) ...[
                  _buildWeatherAlertsSection(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading weather data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Weather Data Unavailable',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWeatherData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecommendationsWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.wb_sunny, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'All Routes Available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Weather conditions are favorable for all transportation options.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTipsSection() {
    if (currentWeather == null) return const SizedBox.shrink();
    
    List<TravelTip> tips = _generateTravelTips(currentWeather!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tips_and_updates, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Travel Tips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildTravelTipCard(tip)),
      ],
    );
  }

  Widget _buildTravelTipCard(TravelTip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tip.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tip.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tip.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(tip.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertsSection() {
    List<WeatherAlert> alerts = _generateWeatherAlerts(currentWeather!, weeklyForecast);
    
    if (alerts.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Weather Alerts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...alerts.map((alert) => _buildWeatherAlertCard(alert)),
      ],
    );
  }

  Widget _buildWeatherAlertCard(WeatherAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.severity == 'high' ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.severity == 'high' ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            alert.severity == 'high' ? Icons.warning : Icons.info_outline,
            color: alert.severity == 'high' ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: alert.severity == 'high' ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TravelTip> _generateTravelTips(WeatherData weather) {
    List<TravelTip> tips = [];
    
    if (weather.temperature > 35) {
      tips.add(TravelTip(
        icon: Icons.local_drink,
        title: 'Stay Hydrated',
        description: 'Carry water during your journey. Choose AC buses or metro for comfort.',
        color: Colors.orange,
      ));
    }
    
    if (weather.condition.contains('Rain') || weather.humidity > 80) {
      tips.add(TravelTip(
        icon: Icons.umbrella,
        title: 'Carry an Umbrella',
        description: 'Rain expected. Choose covered waiting areas and keep essentials dry.',
        color: Colors.blue,
      ));
    }
    
    if (weather.windSpeed > 10) {
      tips.add(TravelTip(
        icon: Icons.air,
        title: 'Windy Conditions',
        description: 'Strong winds detected. Be cautious at open bus stops and platforms.',
        color: Colors.teal,
      ));
    }
    
    if (weather.temperature < 15) {
      tips.add(TravelTip(
        icon: Icons.ac_unit,
        title: 'Dress Warmly',
        description: 'Cool weather ahead. Layer up for comfortable travel.',
        color: Colors.indigo,
      ));
    }
    
    return tips;
  }

  List<WeatherAlert> _generateWeatherAlerts(WeatherData current, List<WeatherForecast> forecast) {
    List<WeatherAlert> alerts = [];
    
    // Extreme temperature alerts
    if (current.temperature > 40) {
      alerts.add(WeatherAlert(
        title: 'Extreme Heat Warning',
        message: 'Temperature exceeds 40°C. Avoid prolonged outdoor waiting. Use AC transport options.',
        severity: 'high',
      ));
    }
    
    // Heavy rain alerts
    if (current.condition == 'Thunderstorm') {
      alerts.add(WeatherAlert(
        title: 'Thunderstorm Alert',
        message: 'Thunderstorm in progress. Seek covered transport options and avoid open areas.',
        severity: 'high',
      ));
    }
    
    // Upcoming weather changes
    if (forecast.length >= 2) {
      final tomorrow = forecast[1];
      if (current.condition == 'Clear' && tomorrow.condition.contains('Rain')) {
        alerts.add(WeatherAlert(
          title: 'Rain Expected Tomorrow',
          message: 'Weather changing to rain tomorrow. Plan accordingly for your regular commute.',
          severity: 'medium',
        ));
      }
    }
    
    return alerts;
  }
}

class TravelTip {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  TravelTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class WeatherAlert {
  final String title;
  final String message;
  final String severity;

  WeatherAlert({
    required this.title,
    required this.message,
    required this.severity,
  });
}