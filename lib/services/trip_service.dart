import 'package:flutter/foundation.dart';
import 'package:away/data/preview_content.dart';

class TripService extends ChangeNotifier {
  TripService._() : _trips = List<PreviewTrip>.from(PreviewContent.trips);

  static final TripService instance = TripService._();

  final List<PreviewTrip> _trips;

  List<PreviewTrip> get trips => List.unmodifiable(_trips);

  PreviewTrip? byId(String id) {
    for (final trip in _trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  void save(PreviewTrip trip) {
    final index = _trips.indexWhere((item) => item.id == trip.id);
    if (index >= 0) {
      _trips[index] = trip;
    } else {
      _trips.add(trip);
    }
    notifyListeners();
  }

  void delete(String id) {
    _trips.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
