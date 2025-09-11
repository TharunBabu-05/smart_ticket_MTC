import '../models/bus_stop_model.dart';

/// Centralized bus stops data for the Smart Ticketing system
class BusStopsData {
  static final List<BusStop> allStops = [
    // Major Chennai Railway Stations
    BusStop(id: 1, name: 'Chennai Central', latitude: 13.0827, longitude: 80.2707, sequence: 1),
    BusStop(id: 2, name: 'Central Station', latitude: 13.0827, longitude: 80.2707, sequence: 1), // Alias
    BusStop(id: 3, name: 'Egmore', latitude: 13.0732, longitude: 80.2609, sequence: 2),
    BusStop(id: 4, name: 'Chennai Egmore', latitude: 13.0732, longitude: 80.2609, sequence: 2), // Alias
    
    // Popular Areas
    BusStop(id: 5, name: 'Marina Beach', latitude: 13.0478, longitude: 80.2785, sequence: 3),
    BusStop(id: 6, name: 'T Nagar', latitude: 13.0418, longitude: 80.2341, sequence: 4),
    BusStop(id: 7, name: 'T. Nagar', latitude: 13.0418, longitude: 80.2341, sequence: 4), // Alias
    BusStop(id: 8, name: 'Anna Nagar', latitude: 13.0850, longitude: 80.2101, sequence: 5),
    BusStop(id: 9, name: 'Vadapalani', latitude: 13.0504, longitude: 80.2066, sequence: 6),
    BusStop(id: 10, name: 'Koyambedu', latitude: 13.0732, longitude: 80.1963, sequence: 7),
    BusStop(id: 11, name: 'Guindy', latitude: 13.0067, longitude: 80.2206, sequence: 8),
    BusStop(id: 12, name: 'Tambaram', latitude: 12.9249, longitude: 80.1000, sequence: 9),
    BusStop(id: 13, name: 'Velachery', latitude: 12.9815, longitude: 80.2236, sequence: 10),
    BusStop(id: 14, name: 'Adyar', latitude: 13.0067, longitude: 80.2574, sequence: 11),
    BusStop(id: 15, name: 'Mylapore', latitude: 13.0339, longitude: 80.2619, sequence: 12),
    BusStop(id: 16, name: 'Park Town', latitude: 13.0732, longitude: 80.2785, sequence: 13),
    BusStop(id: 17, name: 'Airport', latitude: 12.9941, longitude: 80.1709, sequence: 14),
    BusStop(id: 18, name: 'Besant Nagar', latitude: 12.9956, longitude: 80.2661, sequence: 15),
    
    // Kodungaiyur Area Bus Stops
    BusStop(id: 19, name: 'Kodungaiyur', latitude: 13.1352, longitude: 80.2543, sequence: 16),
    BusStop(id: 20, name: 'K.K.D Nagar (Kaviarasu Kannadasan Nagar)', latitude: 13.1336, longitude: 80.2565, sequence: 17),
    BusStop(id: 21, name: 'Muthzhimal Nagar', latitude: 13.1370, longitude: 80.2580, sequence: 18),
    BusStop(id: 22, name: 'M.R Nagar', latitude: 13.1310, longitude: 80.2520, sequence: 19),
    BusStop(id: 23, name: 'Ezhil Nagar', latitude: 13.1390, longitude: 80.2510, sequence: 20),
    BusStop(id: 24, name: 'Parvathi Nagar (Kodungaiyur)', latitude: 13.1459, longitude: 80.2504, sequence: 21),
    BusStop(id: 25, name: 'Kannadasan Nagar Bus Depot', latitude: 13.1330, longitude: 80.2570, sequence: 22),
  ];

  /// Get all bus stop names for dropdown
  static List<String> get stopNames => allStops.map((stop) => stop.name).toList();

  /// Get bus stop by name with fuzzy matching
  static BusStop? getStopByName(String name) {
    try {
      // First try exact match
      final exactMatch = allStops.where((stop) => stop.name.toLowerCase() == name.toLowerCase()).firstOrNull;
      if (exactMatch != null) return exactMatch;
      
      // Try fuzzy matching
      final lowerName = name.toLowerCase();
      final fuzzyMatch = allStops.where((stop) {
        final stopName = stop.name.toLowerCase();
        return stopName.contains(lowerName) || lowerName.contains(stopName);
      }).firstOrNull;
      
      return fuzzyMatch;
    } catch (e) {
      return null;
    }
  }

  /// Get bus stop by ID
  static BusStop? getStopById(int id) {
    try {
      return allStops.firstWhere((stop) => stop.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get stops between two points (inclusive)
  static List<BusStop> getStopsBetween(String fromStopName, String toStopName) {
    final fromStop = getStopByName(fromStopName);
    final toStop = getStopByName(toStopName);
    
    if (fromStop == null || toStop == null) return [];
    
    // Use simple distance calculation since we don't have sequence anymore
    return [fromStop, toStop];
  }
}
