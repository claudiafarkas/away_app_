/// An in‐memory singleton that holds all imported locations
/// (each location is a Map<String, dynamic> containing keys
/// 'name', 'address', 'lat', and 'lng').

class ImportService {
  // private constructor
  ImportService._();

  // the single, global instance
  static final ImportService instance = ImportService._();

  // internal list of all imported location maps
  final List<Map<String, dynamic>> _importedLocations = [];

  /// Returns a read‐only view of all imported locations.
  List<Map<String, dynamic>> get importedLocations =>
      List.unmodifiable(_importedLocations);

  /// a batch of new locations. If a location with the same 'name'
  /// and identical lat/lng already exists, it won’t be added again.
  void addLocations(List<Map<String, dynamic>> newOnes) {
    for (var loc in newOnes) {
      final name = loc['name'];
      final lat = loc['lat'];
      final lng = loc['lng'];
      final alreadyExists = _importedLocations.any(
        (e) => e['name'] == name && e['lat'] == lat && e['lng'] == lng,
      );
      if (!alreadyExists) {
        _importedLocations.add({
          'name': name,
          'address': loc['address'],
          'lat': lat,
          'lng': lng,
        });
      }
    }
  }

  /// clear all stored locations (if you ever need to reset).
  void clearAll() {
    _importedLocations.clear();
  }
}
