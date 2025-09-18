import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = '16ebeafd632800074eedb5b0a38401c7'; // Replace with actual API key
  
  static WeatherService? _instance;
  static WeatherService get instance {
    _instance ??= WeatherService._();
    return _instance!;
  }
  
  WeatherService._();
  
  Location location = Location();
  WeatherData? _cachedWeather;
  List<WeatherForecast>? _cachedForecast;
  DateTime? _lastUpdate;

  // Get current weather and cache for 30 minutes
  Future<WeatherData?> getCurrentWeather() async {
    try {
      if (_cachedWeather != null && _lastUpdate != null) {
        final timeDiff = DateTime.now().difference(_lastUpdate!);
        if (timeDiff.inMinutes < 30) {
          return _cachedWeather;
        }
      }

      final locationData = await _getCurrentLocation();
      if (locationData == null) return null;

      final response = await http.get(Uri.parse(
        '$_baseUrl/weather?lat=${locationData.latitude}&lon=${locationData.longitude}&appid=$_apiKey&units=metric'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedWeather = WeatherData.fromJson(data);
        _lastUpdate = DateTime.now();
        return _cachedWeather;
      }
    } catch (e) {
      log('Error fetching current weather: $e');
    }
    return null;
  }

  // Get 7-day weather forecast
  Future<List<WeatherForecast>> getWeeklyForecast() async {
    try {
      if (_cachedForecast != null && _lastUpdate != null) {
        final timeDiff = DateTime.now().difference(_lastUpdate!);
        if (timeDiff.inHours < 2) {
          return _cachedForecast!;
        }
      }

      final locationData = await _getCurrentLocation();
      if (locationData == null) return [];

      final response = await http.get(Uri.parse(
        '$_baseUrl/forecast?lat=${locationData.latitude}&lon=${locationData.longitude}&appid=$_apiKey&units=metric&cnt=56' // 7 days * 8 forecasts per day
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        // Group by day and take one forecast per day (noon forecast)
        final Map<String, WeatherForecast> dailyForecasts = {};
        
        for (var item in forecastList) {
          final DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          
          // Take the forecast closest to noon (12:00)
          if (!dailyForecasts.containsKey(dateKey) || 
              (date.hour - 12).abs() < (dailyForecasts[dateKey]!.dateTime.hour - 12).abs()) {
            dailyForecasts[dateKey] = WeatherForecast.fromJson(item);
          }
        }
        
        _cachedForecast = dailyForecasts.values.take(7).toList();
        return _cachedForecast!;
      }
    } catch (e) {
      log('Error fetching weather forecast: $e');
    }
    return [];
  }

  Future<LocationData?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return null;
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return null;
      }

      return await location.getLocation();
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }

  // Get weather-based route recommendations
  List<WeatherRecommendation> getWeatherBasedRecommendations(WeatherData weather, List<WeatherForecast> forecast) {
    List<WeatherRecommendation> recommendations = [];

    // Current weather recommendations
    if (weather.condition == 'Rain' || weather.condition == 'Drizzle' || weather.condition == 'Thunderstorm') {
      recommendations.add(WeatherRecommendation(
        title: '🌧️ Rainy Day Routes',
        description: 'Choose covered bus stops and metro stations to stay dry',
        routes: ['Metro Lines', 'AC Bus Routes', 'Covered Bus Stations'],
        priority: 'high',
        icon: '🚇',
      ));
    }

    if (weather.temperature > 35) {
      recommendations.add(WeatherRecommendation(
        title: '🌡️ Beat the Heat',
        description: 'AC buses and metro recommended for hot weather',
        routes: ['AC Bus Routes', 'Metro Lines', 'Volvo AC Services'],
        priority: 'high',
        icon: '❄️',
      ));
    }

    if (weather.temperature < 15) {
      recommendations.add(WeatherRecommendation(
        title: '🧥 Cool Weather Options',
        description: 'Regular buses are comfortable in cool weather',
        routes: ['Regular Bus Routes', 'Open-Air Routes'],
        priority: 'medium',
        icon: '🌤️',
      ));
    }

    if (weather.condition == 'Clear' && weather.temperature >= 20 && weather.temperature <= 30) {
      recommendations.add(WeatherRecommendation(
        title: '☀️ Perfect Weather',
        description: 'Great day for any travel option!',
        routes: ['Walking + Metro', 'Bus Routes', 'Scenic Routes'],
        priority: 'low',
        icon: '🚶‍♂️',
      ));
    }

    // Weekly forecast recommendations
    final upcomingRain = forecast.where((f) => 
      f.condition.contains('Rain') || 
      f.condition.contains('Drizzle') || 
      f.condition.contains('Thunderstorm')
    ).length;

    if (upcomingRain >= 3) {
      recommendations.add(WeatherRecommendation(
        title: '☔ Rainy Week Ahead',
        description: 'Consider weekly passes for covered transport',
        routes: ['Metro Weekly Pass', 'AC Bus Pass'],
        priority: 'medium',
        icon: '🎫',
      ));
    }

    return recommendations;
  }
}

class WeatherData {
  final double temperature;
  final double feelsLike;
  final String condition;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final DateTime dateTime;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.dateTime,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }
}

class WeatherForecast {
  final double temperature;
  final double minTemp;
  final double maxTemp;
  final String condition;
  final String description;
  final String icon;
  final DateTime dateTime;

  WeatherForecast({
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.description,
    required this.icon,
    required this.dateTime,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      temperature: json['main']['temp'].toDouble(),
      minTemp: json['main']['temp_min'].toDouble(),
      maxTemp: json['main']['temp_max'].toDouble(),
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }

  String get dayName {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dateTime.weekday - 1];
  }

  String get shortDate {
    return '${dateTime.day}/${dateTime.month}';
  }
}

class WeatherRecommendation {
  final String title;
  final String description;
  final List<String> routes;
  final String priority;
  final String icon;

  WeatherRecommendation({
    required this.title,
    required this.description,
    required this.routes,
    required this.priority,
    required this.icon,
  });
}