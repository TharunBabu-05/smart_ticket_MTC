import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class DatabaseViewer {
  static const String _gyroSessionsPath = 'gyro_sessions';
  
  /// View all gyro sessions in the primary Firebase Realtime Database
  static Future<void> viewAllSessions() async {
    try {
      print('🔍 =========================');
      print('🔍 FETCHING ALL SESSIONS');
      print('🔍 =========================');
      
      FirebaseDatabase realtimeDatabase = FirebaseDatabase.instanceFor(
        app: Firebase.app(), // Use primary Firebase app
      );
      
      print('� Using primary Firebase Realtime Database');
      print('📍 Path: $_gyroSessionsPath');
      
      DatabaseReference sessionsRef = realtimeDatabase.ref(_gyroSessionsPath);
      print('� Database reference created: ${sessionsRef.toString()}');
      
      // Test database connectivity first
      print('🔍 Testing database connectivity...');
      // Temporarily skip connectivity test to avoid "Invalid token in path" error
      print('⚠️ Connectivity test temporarily disabled');
      print('🌐 Assuming database is connected');
      
      // Get sessions data
      print('📥 Fetching sessions data...');
      DataSnapshot snapshot = await sessionsRef.get();
      
      print('📊 Snapshot exists: ${snapshot.exists}');
      print('📊 Snapshot key: ${snapshot.key}');
      print('📊 Snapshot value type: ${snapshot.value.runtimeType}');
      print('📊 Raw snapshot value: ${snapshot.value}');
      
      if (snapshot.exists && snapshot.value != null) {
        print('✅ Sessions data found!');
        
        if (snapshot.value is Map) {
          Map<dynamic, dynamic> sessions = snapshot.value as Map<dynamic, dynamic>;
          print('✅ Found ${sessions.length} session(s):');
          print('=' * 50);
          
          sessions.forEach((sessionId, sessionData) {
            print('🆔 Session ID: $sessionId');
            if (sessionData is Map) {
              Map<String, dynamic> data = Map<String, dynamic>.from(sessionData);
              data.forEach((key, value) {
                if (key == 'startTime' || key == 'lastUpdate') {
                  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(value);
                  print('  📅 $key: $value (${dateTime.toString()})');
                } else {
                  print('  📄 $key: $value');
                }
              });
            } else {
              print('  📄 Data: $sessionData');
            }
            print('-' * 30);
          });
        } else {
          print('⚠️ Unexpected data format: ${snapshot.value}');
        }
      } else {
        print('❌ No sessions found in the database');
        print('📍 Checked path: $_gyroSessionsPath');
        print('🔍 This could mean:');
        print('   1. No sessions have been created yet');
        print('   2. Sessions are being stored in a different path');
        print('   3. Database write permissions are preventing creation');
        
        // Check if there's any data at the root
        print('🔍 Checking root database for any data...');
        DatabaseReference rootRef = realtimeDatabase.ref();
        DataSnapshot rootSnapshot = await rootRef.get();
        
        if (rootSnapshot.exists && rootSnapshot.value is Map) {
          Map<dynamic, dynamic> rootData = rootSnapshot.value as Map<dynamic, dynamic>;
          print('📊 Root database keys: ${rootData.keys.toList()}');
        } else {
          print('❌ No data found in root database');
        }
      }
      
      print('🔍 =========================');
    } catch (e) {
      print('❌ Error fetching sessions: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }
  
  /// View a specific session by ID
  static Future<void> viewSession(String sessionId) async {
    try {
      FirebaseDatabase realtimeDatabase = FirebaseDatabase.instanceFor(
        app: Firebase.app(), // Use primary Firebase app
      );
      
      print('🔍 Fetching session: $sessionId');
      
      DatabaseReference sessionRef = realtimeDatabase.ref(_gyroSessionsPath).child(sessionId);
      DataSnapshot snapshot = await sessionRef.get();
      
      if (snapshot.exists) {
        Map<String, dynamic> sessionData = Map<String, dynamic>.from(snapshot.value as Map);
        print('✅ Session found:');
        print('=' * 50);
        sessionData.forEach((key, value) {
          if (key == 'startTime' || key == 'lastUpdate') {
            DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(value);
            print('$key: $value (${dateTime.toString()})');
          } else {
            print('$key: $value');
          }
        });
      } else {
        print('❌ Session not found: $sessionId');
      }
    } catch (e) {
      print('❌ Error fetching session: $e');
    }
  }
  
  /// Listen to real-time updates for all sessions
  static void listenToSessions() {
    try {
      FirebaseDatabase realtimeDatabase = FirebaseDatabase.instanceFor(
        app: Firebase.app(), // Use primary Firebase app
      );
      
      print('👂 Listening to real-time session updates...');
      
      DatabaseReference sessionsRef = realtimeDatabase.ref(_gyroSessionsPath);
      sessionsRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> sessions = event.snapshot.value as Map<dynamic, dynamic>;
          print('🔄 Sessions updated - Count: ${sessions.length}');
          sessions.forEach((sessionId, sessionData) {
            print('📱 $sessionId: ${sessionData['status']} - ${sessionData['plannedExit']}');
          });
        } else {
          print('📭 No sessions in database');
        }
      });
    } catch (e) {
      print('❌ Error setting up session listener: $e');
    }
  }
}
