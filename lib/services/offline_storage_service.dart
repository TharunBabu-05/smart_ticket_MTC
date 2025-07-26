import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/trip_data_model.dart';

enum SyncStatus { pending, syncing, synced, failed }
enum DataPriority { critical, high, medium, low }

class OfflineStorageService {
  static Database? _database;
  static const String _dbName = 'smart_ticket_offline.db';
  static const int _dbVersion = 1;

  // Singleton pattern
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  /// Initialize the database
  static Future<void> initialize() async {
    if (_database != null) return;

    try {
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, _dbName);
      
      _database = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
      
      print('Offline database initialized successfully');
    } catch (e) {
      print('Error initializing offline database: $e');
      rethrow;
    }
  }

  /// Create database tables
  static Future<void> _createDatabase(Database db, int version) async {
    // Offline tickets table
    await db.execute('''
      CREATE TABLE offline_tickets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        ticket_data TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        priority INTEGER NOT NULL DEFAULT 2
      )
    ''');

    // Trip data cache table
    await db.execute('''
      CREATE TABLE trip_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        trip_data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        priority INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Bus stops cache table
    await db.execute('''
      CREATE TABLE bus_stops_cache (
        id TEXT PRIMARY KEY,
        stop_data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 2,
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_attempt INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    // User preferences cache
    await db.execute('''
      CREATE TABLE user_preferences (
        user_id TEXT PRIMARY KEY,
        preferences_data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_offline_tickets_user_id ON offline_tickets(user_id)');
    await db.execute('CREATE INDEX idx_offline_tickets_sync_status ON offline_tickets(sync_status)');
    await db.execute('CREATE INDEX idx_trip_cache_user_id ON trip_cache(user_id)');
    await db.execute('CREATE INDEX idx_sync_queue_priority ON sync_queue(priority, created_at)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(sync_status)');
  }

  /// Upgrade database schema
  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    print('Upgrading database from version $oldVersion to $newVersion');
  }

  /// Get database instance
  static Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Store ticket offline
  static Future<void> storeTicketOffline(
    String ticketId,
    String userId,
    Map<String, dynamic> ticketData,
    {DataPriority priority = DataPriority.critical}
  ) async {
    try {
      final int now = DateTime.now().millisecondsSinceEpoch;
      
      await database.insert(
        'offline_tickets',
        {
          'id': ticketId,
          'user_id': userId,
          'ticket_data': jsonEncode(ticketData),
          'status': 'active',
          'created_at': now,
          'updated_at': now,
          'sync_status': 'pending',
          'priority': priority.index,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to sync queue
      await _addToSyncQueue(
        'INSERT',
        'offline_tickets',
        ticketId,
        ticketData,
        priority,
      );
      
      print('Ticket stored offline: $ticketId');
    } catch (e) {
      print('Error storing ticket offline: $e');
      rethrow;
    }
  }

  /// Get offline tickets for user
  static Future<List<Map<String, dynamic>>> getOfflineTickets(String userId) async {
    try {
      final List<Map<String, dynamic>> results = await database.query(
        'offline_tickets',
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, 'active'],
        orderBy: 'created_at DESC',
      );

      return results.map((row) {
        final Map<String, dynamic> ticketData = jsonDecode(row['ticket_data']);
        return {
          ...ticketData,
          'offline_id': row['id'],
          'sync_status': row['sync_status'],
          'created_at': row['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Error getting offline tickets: $e');
      return [];
    }
  }

  /// Cache trip data
  static Future<void> cacheTripData(TripData tripData) async {
    try {
      final int now = DateTime.now().millisecondsSinceEpoch;
      
      await database.insert(
        'trip_cache',
        {
          'id': tripData.ticketId,
          'user_id': tripData.userId,
          'trip_data': jsonEncode(tripData.toMap()),
          'created_at': now,
          'updated_at': now,
          'sync_status': 'pending',
          'priority': DataPriority.high.index,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to sync queue
      await _addToSyncQueue(
        'UPDATE',
        'trip_cache',
        tripData.ticketId,
        tripData.toMap(),
        DataPriority.high,
      );
      
      print('Trip data cached: ${tripData.ticketId}');
    } catch (e) {
      print('Error caching trip data: $e');
    }
  }

  /// Get cached trip data
  static Future<List<TripData>> getCachedTripData(String userId) async {
    try {
      final List<Map<String, dynamic>> results = await database.query(
        'trip_cache',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
        limit: 50, // Limit to recent trips
      );

      return results.map((row) {
        final Map<String, dynamic> tripData = jsonDecode(row['trip_data']);
        return TripData.fromMap(tripData);
      }).toList();
    } catch (e) {
      print('Error getting cached trip data: $e');
      return [];
    }
  }

  /// Cache bus stops data
  static Future<void> cacheBusStops(List<Map<String, dynamic>> busStops) async {
    try {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int expiresAt = now + (24 * 60 * 60 * 1000); // 24 hours

      final Batch batch = database.batch();
      
      for (final busStop in busStops) {
        batch.insert(
          'bus_stops_cache',
          {
            'id': busStop['id'],
            'stop_data': jsonEncode(busStop),
            'created_at': now,
            'updated_at': now,
            'expires_at': expiresAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit();
      print('Bus stops cached: ${busStops.length} stops');
    } catch (e) {
      print('Error caching bus stops: $e');
    }
  }

  /// Get cached bus stops
  static Future<List<Map<String, dynamic>>> getCachedBusStops() async {
    try {
      final int now = DateTime.now().millisecondsSinceEpoch;
      
      final List<Map<String, dynamic>> results = await database.query(
        'bus_stops_cache',
        where: 'expires_at > ?',
        whereArgs: [now],
        orderBy: 'id',
      );

      return results.map((row) {
        return jsonDecode(row['stop_data']) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('Error getting cached bus stops: $e');
      return [];
    }
  }

  /// Add operation to sync queue
  static Future<void> _addToSyncQueue(
    String operationType,
    String tableName,
    String recordId,
    Map<String, dynamic> data,
    DataPriority priority,
  ) async {
    try {
      await database.insert('sync_queue', {
        'operation_type': operationType,
        'table_name': tableName,
        'record_id': recordId,
        'data': jsonEncode(data),
        'priority': priority.index,
        'retry_count': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 'pending',
      });
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  /// Get pending sync operations
  static Future<List<Map<String, dynamic>>> getPendingSyncOperations({int limit = 50}) async {
    try {
      return await database.query(
        'sync_queue',
        where: 'sync_status = ? AND retry_count < ?',
        whereArgs: ['pending', 5], // Max 5 retries
        orderBy: 'priority ASC, created_at ASC',
        limit: limit,
      );
    } catch (e) {
      print('Error getting pending sync operations: $e');
      return [];
    }
  }

  /// Update sync operation status
  static Future<void> updateSyncOperationStatus(
    int operationId,
    SyncStatus status,
    {String? error}
  ) async {
    try {
      final Map<String, dynamic> updates = {
        'sync_status': status.name,
        'last_attempt': DateTime.now().millisecondsSinceEpoch,
      };

      if (status == SyncStatus.failed) {
        // Increment retry count
        final List<Map<String, dynamic>> current = await database.query(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [operationId],
          limit: 1,
        );
        
        if (current.isNotEmpty) {
          updates['retry_count'] = (current.first['retry_count'] as int) + 1;
        }
      }

      await database.update(
        'sync_queue',
        updates,
        where: 'id = ?',
        whereArgs: [operationId],
      );
    } catch (e) {
      print('Error updating sync operation status: $e');
    }
  }

  /// Clean up old data
  static Future<void> cleanupOldData() async {
    try {
      final int thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;

      // Clean up old synced operations
      await database.delete(
        'sync_queue',
        where: 'sync_status = ? AND created_at < ?',
        whereArgs: ['synced', thirtyDaysAgo],
      );

      // Clean up expired bus stops
      await database.delete(
        'bus_stops_cache',
        where: 'expires_at < ?',
        whereArgs: [DateTime.now().millisecondsSinceEpoch],
      );

      // Clean up old trip cache (keep only last 100 trips per user)
      final List<Map<String, dynamic>> users = await database.rawQuery(
        'SELECT DISTINCT user_id FROM trip_cache',
      );

      for (final user in users) {
        final String userId = user['user_id'];
        final List<Map<String, dynamic>> oldTrips = await database.query(
          'trip_cache',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'updated_at DESC',
          offset: 100, // Keep latest 100
        );

        if (oldTrips.isNotEmpty) {
          final List<String> idsToDelete = oldTrips.map((trip) => trip['id'] as String).toList();
          await database.delete(
            'trip_cache',
            where: 'id IN (${idsToDelete.map((_) => '?').join(',')})',
            whereArgs: idsToDelete,
          );
        }
      }

      print('Old data cleanup completed');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  /// Check network connectivity
  static Future<bool> isOnline() async {
    try {
      final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Get storage statistics
  static Future<Map<String, int>> getStorageStats() async {
    try {
      final Map<String, int> stats = {};
      
      // Count records in each table
      final List<String> tables = [
        'offline_tickets',
        'trip_cache',
        'bus_stops_cache',
        'sync_queue',
        'user_preferences',
      ];

      for (final table in tables) {
        final List<Map<String, dynamic>> result = await database.rawQuery(
          'SELECT COUNT(*) as count FROM $table',
        );
        stats[table] = result.first['count'] as int;
      }

      // Get pending sync operations count
      final List<Map<String, dynamic>> pendingResult = await database.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE sync_status = ?',
        ['pending'],
      );
      stats['pending_sync'] = pendingResult.first['count'] as int;

      return stats;
    } catch (e) {
      print('Error getting storage stats: $e');
      return {};
    }
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}