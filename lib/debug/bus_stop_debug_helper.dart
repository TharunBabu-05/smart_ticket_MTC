import 'package:flutter/material.dart';
import '../services/bus_stop_service.dart';

/// Utility widget to reset and reload bus stops data
class BusStopDebugHelper {
  
  /// Call this method to force reset bus stops database
  static Future<void> resetBusStopsDatabase() async {
    try {
      print('🔄 Resetting bus stops database...');
      await BusStopService.resetDatabase();
      print('✅ Bus stops database reset complete');
      print('📍 Loaded ${BusStopService.getBusStopsCount()} bus stops');
    } catch (e) {
      print('❌ Error resetting bus stops: $e');
    }
  }
  
  /// Show debug info about bus stops
  static void showBusStopsInfo() {
    print('🚌 Bus Stops Debug Info:');
    print('   - Is Ready: ${BusStopService.isReady}');
    print('   - Total Stops: ${BusStopService.getBusStopsCount()}');
    
    if (BusStopService.getBusStopsCount() > 0) {
      // Show first few stops as sample
      List<dynamic> firstFew = BusStopService.getAllBusStops().take(5).map((stop) => {
        'name': stop.name,
        'lat': stop.latitude,
        'lng': stop.longitude
      }).toList();
      print('   - Sample stops: $firstFew');
    }
  }
  
  /// Widget to show reset button (for debugging)
  static Widget buildResetButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await resetBusStopsDatabase();
        showBusStopsInfo();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus stops database reset! Check console logs.'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      label: Text('Reset Bus Stops'),
      icon: Icon(Icons.refresh),
      backgroundColor: Colors.orange,
    );
  }
}
