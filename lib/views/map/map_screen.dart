import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:away/services/import_service.dart';

class MapScreen extends StatefulWidget {
  final bool showDoneButton;
  final bool showBackToImportButton;
  const MapScreen({
    super.key,
    this.showDoneButton = false,
    this.showBackToImportButton = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// --------------------------------MAP SETTINGS-------------------------------
class _MapScreenState extends State<MapScreen> {
  bool _isExpanded = false;
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(45.521563, -122.677433);
  final String _mapStyle = '''
      [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#f5f5f5"
        }
      ]
    },
    {
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#f5f5f5"
        }
      ]
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#bdbdbd"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#eeeeee"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#e5e5e5"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9e9e9e"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#ffffff"
        }
      ]
    },
    {
      "featureType": "road.arterial",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#dadada"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9e9e9e"
        }
      ]
    },
    {
      "featureType": "transit.line",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#e5e5e5"
        }
      ]
    },
    {
      "featureType": "transit.station",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#eeeeee"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#c9c9c9"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9e9e9e"
        }
      ]
    }
  ]
      ''';
  // ---------------------------------------------------------------------------

  double _currentZoom = 12;
  LatLng _lastMapPosition = LatLng(45.521563, -122.677433);

  void _onMapCreated(
    GoogleMapController controller,
    LatLng latestMarkerPosition,
  ) {
    mapController = controller;
    mapController?.setMapStyle(_mapStyle);
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latestMarkerPosition, _currentZoom),
    );
  }

  // ----------------------------MAP FUNCTIONALITY------------------------------
  @override
  Widget build(BuildContext context) {
    print("🛠 MapScreen build method called");
    final locs = ImportService.instance.importedLocations;
    print("Locations from ImportService: $locs");

    print("🧭 Starting to generate markers");
    final tempList =
        locs.map((l) {
          final name = l['name'] as String? ?? 'Unknown';
          final latValue = l['lat'];
          final lngValue = l['lng'];
          double lat = 0.0;
          double lng = 0.0;
          try {
            lat =
                (latValue is double ? latValue : (latValue as num).toDouble());
            lng =
                (lngValue is double ? lngValue : (lngValue as num).toDouble());
          } catch (_) {
            print("Skipping marker with non-numeric coordinates: $name");
            return null;
          }
          final address = l['address'] as String? ?? 'No address available';

          print("Creating marker: $name at ($lat, $lng)");
          if (lat == 0.0 && lng == 0.0) {
            print("Skipping marker with invalid coordinates: $name");
            return null;
          }
          return Marker(
            markerId: MarkerId(name),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: name, snippet: address),
          );
        }).toList();
    // filter out any nulls and convert to a Set<Marker>
    final markers = tempList.where((m) => m != null).cast<Marker>().toSet();
    print("📍 Total markers created: ${markers.length}");

    if (markers.isEmpty) {
      print('No markers available. Using default center.');
    }
    print("🧮 Calculating center of map");
    final center = markers.isNotEmpty ? markers.last.position : _center;

    Widget mapBody;
    try {
      mapBody = GoogleMap(
        onMapCreated: (controller) => _onMapCreated(controller, center),
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: markers.isNotEmpty ? 12 : 2,
        ),
        markers: markers,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: true,
        myLocationButtonEnabled: false,
        // style: _mapStyle,
        onCameraMove: (position) {
          _lastMapPosition = position.target;
          _currentZoom = position.zoom;
        },
      );
      print("✅ GoogleMap widget created successfully");
    } catch (e) {
      print("❌ GoogleMap widget failed to build: $e");
      mapBody = Center(child: Text("Error loading map"));
    }
    print("📦 Returning Scaffold with map");
    return Scaffold(
      body: Stack(
        children: [
          mapBody,
          Positioned(
            top: 100,
            left: 10,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 140,
              height: _isExpanded ? 250 : 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    title: Text(
                      _isExpanded ? "Hide Pins" : "Show Pins",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                  if (_isExpanded)
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: _buildGroupedMarkerList(markers),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black54,
                  elevation: 3,
                  shape: const CircleBorder(),
                  onPressed: () {
                    setState(() {
                      _currentZoom += 1;
                      mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _lastMapPosition,
                            zoom: _currentZoom,
                          ),
                        ),
                      );
                    });
                  },
                  child: const Icon(Icons.add),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black54,
                  elevation: 3,
                  shape: const CircleBorder(),
                  onPressed: () {
                    setState(() {
                      _currentZoom -= 1;
                      mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _lastMapPosition,
                            zoom: _currentZoom,
                          ),
                        ),
                      );
                    });
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          if (widget.showBackToImportButton)
            Positioned(
              bottom: 20,
              left: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/import'));
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back to Import Screen"),
              ),
            ),
          if (widget.showDoneButton)
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text("Done"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black54,
                  elevation: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedMarkerList(Set<Marker> markers) {
    final grouped = <String, List<Marker>>{};
    for (var marker in markers) {
      final country =
          marker.infoWindow.snippet?.split(',').last.trim() ?? 'Unknown';
      grouped.putIfAbsent(country, () => []).add(marker);
    }
    return grouped.entries.map((entry) {
      return ExpansionTile(
        title: Text(
          entry.key,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        children:
            entry.value.map((marker) {
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(
                  marker.markerId.value,
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  mapController?.animateCamera(
                    CameraUpdate.newLatLng(marker.position),
                  );
                },
              );
            }).toList(),
      );
    }).toList();
  }
}
