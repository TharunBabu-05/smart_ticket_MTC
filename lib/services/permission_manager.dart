import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static const String tag = '🔒 PermissionManager';
  
  /// Request all permissions needed for fraud detection
  static Future<bool> requestAllPermissions() async {
    print('$tag Requesting all required permissions...');
    
    try {
      // Request all permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.sensors,
      ].request();
      
      print('$tag Permission results:');
      statuses.forEach((permission, status) {
        print('$tag ${permission.toString()}: ${status.toString()}');
      });
      
      // Check if location permission is granted
      bool locationGranted = statuses[Permission.location]?.isGranted == true ||
                           statuses[Permission.locationWhenInUse]?.isGranted == true ||
                           statuses[Permission.locationAlways]?.isGranted == true;
      
      // Check if sensor permission is granted (not all devices support this)
      bool sensorsGranted = statuses[Permission.sensors]?.isGranted == true ||
                           statuses[Permission.sensors]?.isPermanentlyDenied == false;
      
      print('$tag Location granted: $locationGranted');
      print('$tag Sensors accessible: $sensorsGranted');
      
      return locationGranted; // We mainly need location
      
    } catch (e) {
      print('$tag Error requesting permissions: $e');
      return false;
    }
  }
  
  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    try {
      PermissionStatus status = await Permission.location.status;
      PermissionStatus statusWhenInUse = await Permission.locationWhenInUse.status;
      
      return status.isGranted || statusWhenInUse.isGranted;
    } catch (e) {
      print('$tag Error checking location permission: $e');
      return false;
    }
  }
  
  /// Request location permission specifically
  static Future<bool> requestLocationPermission() async {
    try {
      print('$tag Requesting location permission...');
      
      PermissionStatus status = await Permission.locationWhenInUse.request();
      
      if (status.isGranted) {
        print('$tag ✅ Location permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('$tag ❌ Location permission permanently denied');
        await openAppSettings();
        return false;
      } else {
        print('$tag ❌ Location permission denied');
        return false;
      }
    } catch (e) {
      print('$tag Error requesting location permission: $e');
      return false;
    }
  }
  
  /// Check if sensors are available (doesn't require permissions on most devices)
  static Future<bool> areSensorsAvailable() async {
    try {
      // Sensors typically don't require runtime permissions on Android
      // They're controlled by manifest permissions and hardware availability
      return true;
    } catch (e) {
      print('$tag Error checking sensor availability: $e');
      return false;
    }
  }
  
  /// Show permission dialog if needed
  static Future<void> showPermissionDialog() async {
    print('$tag Please grant the following permissions:');
    print('$tag 1. Location - Required to verify your position');
    print('$tag 2. Motion sensors - Required for fraud detection');
  }
}
