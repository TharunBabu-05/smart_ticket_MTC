import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum PerformanceMetric {
  appStartTime,
  screenLoadTime,
  apiResponseTime,
  databaseQueryTime,
  memoryUsage,
  batteryUsage,
  networkLatency,
  crashCount,
  errorCount,
}

class PerformanceData {
  final PerformanceMetric metric;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceData({
    required this.metric,
    required this.value,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'metric': metric.name,
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory PerformanceData.fromMap(Map<String, dynamic> map) {
    return PerformanceData(
      metric: PerformanceMetric.values.firstWhere(
        (m) => m.name == map['metric'],
        orElse: () => PerformanceMetric.appStartTime,
      ),
      value: map['value']?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      metadata: map['metadata'],
    );
  }
}

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final List<PerformanceData> _performanceData = [];
  final Map<String, Stopwatch> _activeTimers = {};
  Timer? _reportingTimer;
  
  static const String _performanceKey = 'performance_data';
  static const int _maxDataPoints = 1000;
  static const Duration _reportingInterval = Duration(minutes: 5);

  /// Initialize performance monitoring
  Future<void> initialize() async {
    try {
      // Load existing performance data
      await _loadPerformanceData();
      
      // Start periodic reporting
      _startPeriodicReporting();
      
      // Monitor app lifecycle
      _setupAppLifecycleMonitoring();
      
      print('Performance monitoring initialized');
    } catch (e) {
      print('Error initializing performance monitoring: $e');
    }
  }

  /// Start timing a performance metric
  void startTimer(String timerName) {
    _activeTimers[timerName] = Stopwatch()..start();
  }

  /// Stop timing and record the metric
  void stopTimer(String timerName, PerformanceMetric metric, {Map<String, dynamic>? metadata}) {
    final Stopwatch? stopwatch = _activeTimers.remove(timerName);
    if (stopwatch != null) {
      stopwatch.stop();
      recordMetric(
        metric,
        stopwatch.elapsedMilliseconds.toDouble(),
        metadata: metadata,
      );
    }
  }

  /// Record a performance metric
  void recordMetric(
    PerformanceMetric metric,
    double value, {
    Map<String, dynamic>? metadata,
  }) {
    final performanceData = PerformanceData(
      metric: metric,
      value: value,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _performanceData.add(performanceData);

    // Keep only the latest data points
    if (_performanceData.length > _maxDataPoints) {
      _performanceData.removeAt(0);
    }

    // Log critical performance issues
    _checkPerformanceThresholds(performanceData);
  }

  /// Record app start time
  void recordAppStartTime(Duration startTime) {
    recordMetric(
      PerformanceMetric.appStartTime,
      startTime.inMilliseconds.toDouble(),
      metadata: {
        'platform': Platform.operatingSystem,
        'debug_mode': kDebugMode,
      },
    );
  }

  /// Record screen load time
  void recordScreenLoadTime(String screenName, Duration loadTime) {
    recordMetric(
      PerformanceMetric.screenLoadTime,
      loadTime.inMilliseconds.toDouble(),
      metadata: {
        'screen_name': screenName,
      },
    );
  }

  /// Record API response time
  void recordApiResponseTime(String endpoint, Duration responseTime, {int? statusCode}) {
    recordMetric(
      PerformanceMetric.apiResponseTime,
      responseTime.inMilliseconds.toDouble(),
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
      },
    );
  }

  /// Record database query time
  void recordDatabaseQueryTime(String queryType, Duration queryTime) {
    recordMetric(
      PerformanceMetric.databaseQueryTime,
      queryTime.inMilliseconds.toDouble(),
      metadata: {
        'query_type': queryType,
      },
    );
  }

  /// Record memory usage
  Future<void> recordMemoryUsage() async {
    try {
      // This is a simplified memory tracking
      // In production, you might use more sophisticated memory profiling
      if (Platform.isAndroid || Platform.isLinux) {
        final ProcessResult processResult = await Process.run('cat', ['/proc/self/status']);
        final String output = processResult.stdout.toString();
        
        final RegExp vmRssRegex = RegExp(r'VmRSS:\s+(\d+)\s+kB');
        final Match? match = vmRssRegex.firstMatch(output);
        
        if (match != null) {
          final double memoryKB = double.parse(match.group(1)!);
          recordMetric(
            PerformanceMetric.memoryUsage,
            memoryKB,
            metadata: {
              'unit': 'KB',
            },
          );
        }
      } else {
        // For iOS and other platforms, use a simplified approach
        recordMetric(
          PerformanceMetric.memoryUsage,
          0.0,
          metadata: {
            'unit': 'KB',
            'note': 'Memory tracking not available on this platform',
          },
        );
      }
    } catch (e) {
      // Fallback for platforms where this doesn't work
      print('Memory usage tracking not available: $e');
    }
  }

  /// Record network latency
  Future<void> recordNetworkLatency() async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      
      // Simple ping to check network latency
      final ConnectivityResult connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity != ConnectivityResult.none) {
        // Simulate a lightweight network request
        try {
          final HttpClient client = HttpClient();
          final HttpClientRequest request = await client.getUrl(Uri.parse('https://www.google.com'));
          request.headers.set('User-Agent', 'SmartTicketMTC/1.0');
          final HttpClientResponse response = await request.close();
          await response.drain();
          client.close();
          
          stopwatch.stop();
          recordMetric(
            PerformanceMetric.networkLatency,
            stopwatch.elapsedMilliseconds.toDouble(),
            metadata: {
              'connectivity': connectivity.name,
            },
          );
        } catch (e) {
          print('Network latency test failed: $e');
        }
      }
    } catch (e) {
      print('Error recording network latency: $e');
    }
  }

  /// Record error occurrence
  void recordError(String errorType, {String? errorMessage, StackTrace? stackTrace}) {
    recordMetric(
      PerformanceMetric.errorCount,
      1.0,
      metadata: {
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Record crash occurrence
  void recordCrash(String crashReason, {StackTrace? stackTrace}) {
    recordMetric(
      PerformanceMetric.crashCount,
      1.0,
      metadata: {
        'crash_reason': crashReason,
        'stack_trace': stackTrace?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final Map<String, List<double>> metricValues = {};
    
    // Group values by metric type
    for (final data in _performanceData) {
      final String metricName = data.metric.name;
      metricValues[metricName] ??= [];
      metricValues[metricName]!.add(data.value);
    }

    // Calculate statistics for each metric
    final Map<String, dynamic> stats = {};
    
    for (final entry in metricValues.entries) {
      final List<double> values = entry.value;
      if (values.isNotEmpty) {
        values.sort();
        
        stats[entry.key] = {
          'count': values.length,
          'min': values.first,
          'max': values.last,
          'average': values.reduce((a, b) => a + b) / values.length,
          'median': values[values.length ~/ 2],
          'p95': values[(values.length * 0.95).floor()],
          'p99': values[(values.length * 0.99).floor()],
        };
      }
    }

    return stats;
  }

  /// Get recent performance data
  List<PerformanceData> getRecentData({Duration? since}) {
    final DateTime cutoff = since != null 
        ? DateTime.now().subtract(since)
        : DateTime.now().subtract(const Duration(hours: 1));
    
    return _performanceData
        .where((data) => data.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Check performance thresholds and log warnings
  void _checkPerformanceThresholds(PerformanceData data) {
    switch (data.metric) {
      case PerformanceMetric.appStartTime:
        if (data.value > 3000) { // 3 seconds
          print('WARNING: Slow app start time: ${data.value}ms');
        }
        break;
      case PerformanceMetric.screenLoadTime:
        if (data.value > 2000) { // 2 seconds
          print('WARNING: Slow screen load time: ${data.value}ms for ${data.metadata?['screen_name']}');
        }
        break;
      case PerformanceMetric.apiResponseTime:
        if (data.value > 5000) { // 5 seconds
          print('WARNING: Slow API response: ${data.value}ms for ${data.metadata?['endpoint']}');
        }
        break;
      case PerformanceMetric.databaseQueryTime:
        if (data.value > 1000) { // 1 second
          print('WARNING: Slow database query: ${data.value}ms for ${data.metadata?['query_type']}');
        }
        break;
      case PerformanceMetric.memoryUsage:
        if (data.value > 500000) { // 500MB
          print('WARNING: High memory usage: ${data.value}KB');
        }
        break;
      case PerformanceMetric.networkLatency:
        if (data.value > 2000) { // 2 seconds
          print('WARNING: High network latency: ${data.value}ms');
        }
        break;
      default:
        break;
    }
  }

  /// Setup app lifecycle monitoring
  void _setupAppLifecycleMonitoring() {
    // Monitor app state changes
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  /// Start periodic reporting
  void _startPeriodicReporting() {
    _reportingTimer = Timer.periodic(_reportingInterval, (timer) {
      _generatePerformanceReport();
    });
  }

  /// Generate and save performance report
  Future<void> _generatePerformanceReport() async {
    try {
      final Map<String, dynamic> stats = getPerformanceStats();
      
      // Save performance data
      await _savePerformanceData();
      
      // Log summary
      print('Performance Report Generated:');
      for (final entry in stats.entries) {
        final Map<String, dynamic> metricStats = entry.value;
        print('  ${entry.key}: avg=${metricStats['average']?.toStringAsFixed(2)}ms, '
              'p95=${metricStats['p95']?.toStringAsFixed(2)}ms');
      }
      
      // Clean up old data
      _cleanupOldData();
      
    } catch (e) {
      print('Error generating performance report: $e');
    }
  }

  /// Load performance data from storage
  Future<void> _loadPerformanceData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? dataJson = prefs.getString(_performanceKey);
      
      if (dataJson != null) {
        final List<dynamic> dataList = jsonDecode(dataJson);
        _performanceData.clear();
        _performanceData.addAll(
          dataList.map((item) => PerformanceData.fromMap(item)).toList(),
        );
      }
    } catch (e) {
      print('Error loading performance data: $e');
    }
  }

  /// Save performance data to storage
  Future<void> _savePerformanceData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> dataList = 
          _performanceData.map((data) => data.toMap()).toList();
      
      await prefs.setString(_performanceKey, jsonEncode(dataList));
    } catch (e) {
      print('Error saving performance data: $e');
    }
  }

  /// Clean up old performance data
  void _cleanupOldData() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 7));
    _performanceData.removeWhere((data) => data.timestamp.isBefore(cutoff));
  }

  /// Dispose resources
  void dispose() {
    _reportingTimer?.cancel();
    _activeTimers.clear();
    _performanceData.clear();
  }
}

/// App lifecycle observer for performance monitoring
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final PerformanceService _performanceService;
  
  _AppLifecycleObserver(this._performanceService);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _performanceService.recordMetric(
          PerformanceMetric.appStartTime,
          0.0,
          metadata: {'lifecycle_event': 'resumed'},
        );
        break;
      case AppLifecycleState.paused:
        _performanceService.recordMetric(
          PerformanceMetric.appStartTime,
          0.0,
          metadata: {'lifecycle_event': 'paused'},
        );
        break;
      case AppLifecycleState.detached:
        _performanceService.recordMetric(
          PerformanceMetric.appStartTime,
          0.0,
          metadata: {'lifecycle_event': 'detached'},
        );
        break;
      default:
        break;
    }
  }
}

/// Performance monitoring mixin for screens
mixin PerformanceMonitoringMixin<T extends StatefulWidget> on State<T> {
  final PerformanceService _performanceService = PerformanceService();
  late final Stopwatch _screenLoadStopwatch;

  @override
  void initState() {
    super.initState();
    _screenLoadStopwatch = Stopwatch()..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Record screen load time after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenLoadStopwatch.stop();
      _performanceService.recordScreenLoadTime(
        runtimeType.toString(),
        Duration(milliseconds: _screenLoadStopwatch.elapsedMilliseconds),
      );
    });
  }

  /// Record custom performance metric
  void recordPerformanceMetric(PerformanceMetric metric, double value, {Map<String, dynamic>? metadata}) {
    _performanceService.recordMetric(metric, value, metadata: metadata);
  }

  /// Start performance timer
  void startPerformanceTimer(String timerName) {
    _performanceService.startTimer(timerName);
  }

  /// Stop performance timer
  void stopPerformanceTimer(String timerName, PerformanceMetric metric, {Map<String, dynamic>? metadata}) {
    _performanceService.stopTimer(timerName, metric, metadata: metadata);
  }
}