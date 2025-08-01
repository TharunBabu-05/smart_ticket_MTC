import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_ticket_model.dart';

class FirebaseDebugHelper {
  static final FirebaseDatabase _realtimeDB = FirebaseDatabase.instance;
  
  /// Debug: Print all tickets in the database
  static Future<void> debugPrintAllTickets() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🚫 No authenticated user');
        return;
      }
      
      print('🔍 DEBUG: Fetching all tickets for user: ${user.uid}');
      
      // Try different paths
      List<String> paths = ['tickets', 'enhanced_tickets'];
      
      for (String path in paths) {
        print('\n📂 Checking path: $path');
        
        try {
          DatabaseReference ref = _realtimeDB.ref(path);
          DatabaseEvent event = await ref.once();
          
          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
            print('✅ Found ${data.length} records in $path');
            
            // Print details of each ticket
            for (var entry in data.entries) {
              Map<String, dynamic> ticketData = Map<String, dynamic>.from(entry.value as Map);
              print('🎫 Ticket ${entry.key}:');
              print('   - UserId: ${ticketData['userId']}');
              print('   - Status: ${ticketData['status']}');
              print('   - Valid Until: ${ticketData['validUntil']}');
              print('   - Is User Ticket: ${ticketData['userId'] == user.uid}');
              
              // Try to parse as ticket
              try {
                EnhancedTicket ticket = EnhancedTicket.fromMap(ticketData);
                print('   - Parsed Successfully: ${ticket.isValid ? 'VALID' : 'EXPIRED'}');
              } catch (e) {
                print('   - Parse Error: $e');
              }
            }
          } else {
            print('📭 No data found in $path');
          }
        } catch (e) {
          print('❌ Error accessing $path: $e');
        }
      }
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }
  
  /// Debug: Clear all expired tickets
  static Future<void> debugClearExpiredTickets() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🚫 No authenticated user');
        return;
      }
      
      print('🧹 DEBUG: Clearing expired tickets for user: ${user.uid}');
      
      DatabaseReference ref = _realtimeDB.ref('enhanced_tickets');
      DatabaseEvent event = await ref.orderByChild('userId').equalTo(user.uid).once();
      
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> tickets = event.snapshot.value as Map<dynamic, dynamic>;
        
        for (var entry in tickets.entries) {
          try {
            Map<String, dynamic> ticketData = Map<String, dynamic>.from(entry.value as Map);
            EnhancedTicket ticket = EnhancedTicket.fromMap(ticketData);
            
            if (!ticket.isValid) {
              print('🗑️ Removing expired ticket: ${ticket.ticketId}');
              await ref.child(entry.key).remove();
            }
          } catch (e) {
            print('❌ Error processing ticket ${entry.key}: $e');
          }
        }
        
        print('✅ Cleanup completed');
      } else {
        print('📭 No tickets found to clean');
      }
      
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }
}
