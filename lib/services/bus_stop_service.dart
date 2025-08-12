import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
    if (_isInitialized) {
      print('✅ BusStopService already initialized with ${_cachedBusStops.length} stops');
      return;
    }
    
    print('🚀 Initializing BusStopService...');
    
    try {
      _database = await _initDatabase();
      await _loadBusStopsFromJson();
      _isInitialized = true;
      print('✅ BusStopService initialized with ${_cachedBusStops.length} stops');
      
      // Log sample of data
      if (_cachedBusStops.isNotEmpty) {
        final sampleSize = math.min(3, _cachedBusStops.length);
        print('📍 Sample stops:');
        for (int i = 0; i < sampleSize; i++) {
          final stop = _cachedBusStops[i];
          print('   ${stop.name} (${stop.latitude}, ${stop.longitude})');
        }
      }
    } catch (e) {
      print('❌ Error initializing BusStopService: $e');
    }
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bus_stops.db');
    
    return await openDatabase(
      path,
      version: 2, // Increment version to recreate table
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE bus_stops(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            sequence INTEGER DEFAULT 0
          )
        ''');
        
        // Create index for faster location queries
        await db.execute('''
          CREATE INDEX idx_bus_stops_location ON bus_stops(latitude, longitude)
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Drop and recreate table with new schema
        await db.execute('DROP TABLE IF EXISTS bus_stops');
        await db.execute('''
          CREATE TABLE bus_stops(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            sequence INTEGER DEFAULT 0
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

      // Load Delhi bus stops
      print('📍 Loading Delhi bus stops...');
      String delhiJsonString = await rootBundle.loadString('lib/delhi_bus_stops.json');
      List<dynamic> delhiStopsData = json.decode(delhiJsonString);
      
      // Load Chennai bus stops
      print('📍 Loading Chennai bus stops...');
      String chennaiJsonString = await rootBundle.loadString('lib/chennai_bus_stops.json');
      List<dynamic> chennaiStopsData = json.decode(chennaiJsonString);
      
      List<BusStop> busStops = [];
      
      // Process Delhi stops (existing format)
      for (var stopJson in delhiStopsData) {
        busStops.add(BusStop.fromJson(stopJson));
      }
      
      // Process Chennai stops (different format)
      for (var stopJson in chennaiStopsData) {
        busStops.add(BusStop(
          id: stopJson['Stop_id'] ?? busStops.length,
          name: stopJson['Stop Name'] ?? 'Unknown Stop',
          latitude: (stopJson['Lat'] ?? 0.0).toDouble(),
          longitude: (stopJson['Lng'] ?? 0.0).toDouble(),
          sequence: busStops.length,
        ));
      }

      print('✅ Loaded ${delhiStopsData.length} Delhi stops and ${chennaiStopsData.length} Chennai stops');

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
    print('🔍 Finding nearby stops for location: $latitude, $longitude (radius: ${radiusKm}km)');
    
    if (!_isInitialized || _cachedBusStops.isEmpty) {
      print('⚠️ BusStopService not initialized or no data available (initialized: $_isInitialized, stops: ${_cachedBusStops.length})');
      return [];
    }

    List<BusStop> nearbyStops = [];
    double radiusMeters = radiusKm * 1000;
    int checkedStops = 0;
    
    for (BusStop stop in _cachedBusStops) {
      double distance = stop.distanceTo(latitude, longitude);
      checkedStops++;
      
      if (distance <= radiusMeters) {
        nearbyStops.add(stop);
        if (nearbyStops.length <= 5) { // Log first few matches
          print('✅ Found nearby stop: ${stop.name} at ${distance.toInt()}m');
        }
      }
    }
    
    print('🎯 Checked $checkedStops stops, found ${nearbyStops.length} within ${radiusKm}km');
    
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
    
    // Clear database to force fresh load from JSON
    if (_database != null) {
      await _database!.delete('bus_stops');
      print('🗑️ Cleared existing bus stops from database');
    }
    
    await initialize();
  }

  // Force reset database and reload (for debugging)
  static Future<void> resetDatabase() async {
    _cachedBusStops.clear();
    _isInitialized = false;
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    // Delete database file to force recreation
    String path = join(await getDatabasesPath(), 'bus_stops.db');
    File dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('🗑️ Deleted database file for fresh start');
    }
    
    await initialize();
  }
}
