import '../models/bus_stop_model.dart';

/// Centralized bus stops data for the Smart Ticketing system
class BusStopsData {
  static final List<BusStop> allStops = [
    BusStop(id: 1, name: 'Central Station', latitude: 13.0827, longitude: 80.2707, sequence: 1),
    BusStop(id: 2, name: 'Marina Beach', latitude: 13.0478, longitude: 80.2785, sequence: 2),
    BusStop(id: 3, name: 'T. Nagar', latitude: 13.0418, longitude: 80.2341, sequence: 3),
    BusStop(id: 4, name: 'Anna Nagar', latitude: 13.0850, longitude: 80.2101, sequence: 4),
    BusStop(id: 5, name: 'Vadapalani', latitude: 13.0504, longitude: 80.2066, sequence: 5),
    BusStop(id: 6, name: 'Koyambedu', latitude: 13.0732, longitude: 80.1963, sequence: 6),
    BusStop(id: 7, name: 'Guindy', latitude: 13.0067, longitude: 80.2206, sequence: 7),
    BusStop(id: 8, name: 'Tambaram', latitude: 12.9249, longitude: 80.1000, sequence: 8),
    
    // Kodungaiyur Area Bus Stops
    BusStop(id: 9, name: 'Kodungaiyur', latitude: 13.1352, longitude: 80.2543, sequence: 9),
    BusStop(id: 10, name: 'K.K.D Nagar (Kaviarasu Kannadasan Nagar)', latitude: 13.1336, longitude: 80.2565, sequence: 10),
    BusStop(id: 11, name: 'Muthzhimal Nagar', latitude: 13.1370, longitude: 80.2580, sequence: 11),
    BusStop(id: 12, name: 'M.R Nagar', latitude: 13.1310, longitude: 80.2520, sequence: 12),
    BusStop(id: 13, name: 'Ezhil Nagar', latitude: 13.1390, longitude: 80.2510, sequence: 13),
    BusStop(id: 14, name: 'Parvathi Nagar (Kodungaiyur)', latitude: 13.1459, longitude: 80.2504, sequence: 14),
    BusStop(id: 15, name: 'Kannadasan Nagar Bus Depot', latitude: 13.1330, longitude: 80.2570, sequence: 15),
  ];

  /// Get all bus stop names for dropdown
  static List<String> get stopNames => allStops.map((stop) => stop.name).toList();

  /// Get bus stop by name
  static BusStop? getStopByName(String name) {
    try {
      return allStops.firstWhere((stop) => stop.name == name);
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
