import '../models/trip_data_model.dart';

/// Centralized bus stops data for the Smart Ticketing system
class BusStopsData {
  static final List<BusStop> allStops = [
    BusStop(id: '1', name: 'Central Station', location: LatLng(13.0827, 80.2707), sequence: 1),
    BusStop(id: '2', name: 'Marina Beach', location: LatLng(13.0478, 80.2785), sequence: 2),
    BusStop(id: '3', name: 'T. Nagar', location: LatLng(13.0418, 80.2341), sequence: 3),
    BusStop(id: '4', name: 'Anna Nagar', location: LatLng(13.0850, 80.2101), sequence: 4),
    BusStop(id: '5', name: 'Vadapalani', location: LatLng(13.0504, 80.2066), sequence: 5),
    BusStop(id: '6', name: 'Koyambedu', location: LatLng(13.0732, 80.1963), sequence: 6),
    BusStop(id: '7', name: 'Guindy', location: LatLng(13.0067, 80.2206), sequence: 7),
    BusStop(id: '8', name: 'Tambaram', location: LatLng(12.9249, 80.1000), sequence: 8),
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
  static BusStop? getStopById(String id) {
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
    
    final fromSequence = fromStop.sequence;
    final toSequence = toStop.sequence;
    
    final minSequence = fromSequence < toSequence ? fromSequence : toSequence;
    final maxSequence = fromSequence > toSequence ? fromSequence : toSequence;
    
    return allStops
        .where((stop) => stop.sequence >= minSequence && stop.sequence <= maxSequence)
        .toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
  }
}
