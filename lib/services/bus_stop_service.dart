import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bus_stop_model.dart';

class BusStopService {
  static Database? _database;
  static List<BusStop> _cachedBusStops = [];
  static bool _isInitialized = false;

  // Initialize database and load JSON data
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _database = await _initDatabase();
      await _loadBusStopsFromJson();
      _isInitialized = true;
      print('✅ BusStopService initialized with ${_cachedBusStops.length} stops');
    } catch (e) {
      print('❌ Error initializing BusStopService: $e');
    }
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bus_stops.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE bus_stops(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
        ''');
        
        // Create index for faster location queries
        await db.execute('''
          CREATE INDEX idx_bus_stops_location ON bus_stops(latitude, longitude)
        ''');
      },
    );
  }

  // Load bus stops from your JSON file
  static Future<void> _loadBusStopsFromJson() async {
    try {
      // Check if data already exists in database
      final existingStops = await _getLocalBusStops();
      if (existingStops.isNotEmpty) {
        _cachedBusStops = existingStops;
        print('📍 Loaded ${existingStops.length} bus stops from local database');
        return;
      }

      // Load from JSON file
      String jsonString = await rootBundle.loadString('lib/delhi_bus_stops.json');
      List<dynamic> stopsData = json.decode(jsonString);
      
      List<BusStop> busStops = stopsData.map((stopJson) {
        return BusStop.fromJson(stopJson);
      }).toList();

      // Save to local database in batches for better performance
      await _saveBusStopsToDatabase(busStops);
      _cachedBusStops = busStops;
      
      print('✅ Loaded ${busStops.length} bus stops from JSON and saved to database');
    } catch (e) {
      print('❌ Error loading bus stops: $e');
    }
  }

  static Future<void> _saveBusStopsToDatabase(List<BusStop> busStops) async {
    final db = _database!;
    
    // Use transaction for better performance with large datasets
    await db.transaction((txn) async {
      Batch batch = txn.batch();
      
      for (BusStop stop in busStops) {
        batch.insert('bus_stops', stop.toDbMap());
      }
      
      await batch.commit(noResult: true);
    });
  }

  static Future<List<BusStop>> _getLocalBusStops() async {
    if (_database == null) return [];
    
    final List<Map<String, dynamic>> maps = await _database!.query('bus_stops');
    return maps.map((map) => BusStop.fromDbMap(map)).toList();
  }

  // Find nearest bus stops to a location
  static List<BusStop> findNearbyStops(double latitude, double longitude, {double radiusKm = 1.0}) {
    if (!_isInitialized || _cachedBusStops.isEmpty) {
      print('⚠️ BusStopService not initialized or no data available');
      return [];
    }

    List<BusStop> nearbyStops = [];
    double radiusMeters = radiusKm * 1000;
    
    for (BusStop stop in _cachedBusStops) {
      double distance = stop.distanceTo(latitude, longitude);
      if (distance <= radiusMeters) {
        nearbyStops.add(stop);
      }
    }
    
    // Sort by distance
    nearbyStops.sort((a, b) {
      double distA = a.distanceTo(latitude, longitude);
      double distB = b.distanceTo(latitude, longitude);
      return distA.compareTo(distB);
    });
    
    return nearbyStops;
  }

  // Get the nearest bus stop within threshold
  static BusStop? getNearestBusStop(double latitude, double longitude, {double thresholdMeters = 100}) {
    if (!_isInitialized || _cachedBusStops.isEmpty) return null;
    
    BusStop? nearestStop;
    double minDistance = double.infinity;
    
    for (BusStop stop in _cachedBusStops) {
      double distance = stop.distanceTo(latitude, longitude);
      if (distance <= thresholdMeters && distance < minDistance) {
        minDistance = distance;
        nearestStop = stop;
      }
    }
    
    return nearestStop;
  }

  // Search bus stops by name
  static List<BusStop> searchByName(String query) {
    if (!_isInitialized || _cachedBusStops.isEmpty) return [];
    
    String lowerQuery = query.toLowerCase();
    return _cachedBusStops.where((stop) {
      return stop.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get all bus stops (use with caution - large dataset)
  static List<BusStop> getAllBusStops() {
    return List.from(_cachedBusStops);
  }

  // Get bus stops count
  static int getBusStopsCount() {
    return _cachedBusStops.length;
  }

  // Check if service is ready
  static bool get isReady => _isInitialized && _cachedBusStops.isNotEmpty;

  // Clear cache and reload data
  static Future<void> reload() async {
    _cachedBusStops.clear();
    _isInitialized = false;
    await initialize();
  }
}
