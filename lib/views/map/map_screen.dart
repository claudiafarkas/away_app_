import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:away/services/import_service.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
  final double _zoomOnFocus = 15;
  // Color assignment per country
  final List<double> countryHues = [0, 25, 50, 100, 160, 200, 260, 300, 330];
  final Map<String, double> _countryColorMap = {};
  final Map<double, BitmapDescriptor> _iconCache = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _prepareMarkers();
  }

  Color _colorFromHue(double hue) {
    final hsv = HSVColor.fromAHSV(1.0, hue, 0.65, 0.95);
    return hsv.toColor();
  }

  Future<BitmapDescriptor> _createCircleMarkerIcon(
    Color color, {
    double size = 48,
    double border = 4,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    // Transparent background
    final bgPaint = Paint()..color = const Color(0x00000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);
    // White border circle
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 2, borderPaint);
    // Inner color circle
    final fillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 2 - border, fillPaint);
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  String _countryFromAddress(String address) {
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.last.trim() : 'Unknown';
  }

  LatLng? _latestValidLatLngFromLocs(List<dynamic> locs) {
    for (int i = locs.length - 1; i >= 0; i--) {
      final l = locs[i];
      final latValue = l['lat'];
      final lngValue = l['lng'];
      try {
        final lat =
            (latValue is double ? latValue : (latValue as num).toDouble());
        final lng =
            (lngValue is double ? lngValue : (lngValue as num).toDouble());
        if (!(lat == 0.0 && lng == 0.0)) {
          return LatLng(lat, lng);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<void> _prepareMarkers() async {
    final locs = ImportService.instance.importedLocations;
    final List<Marker> temp = [];
    for (final l in locs) {
      final name = l['name'] as String? ?? 'Unknown';
      final latValue = l['lat'];
      final lngValue = l['lng'];
      double lat, lng;
      try {
        lat = (latValue is double ? latValue : (latValue as num).toDouble());
        lng = (lngValue is double ? lngValue : (lngValue as num).toDouble());
      } catch (_) {
        continue;
      }
      if (lat == 0.0 && lng == 0.0) continue;
      final address = l['address'] as String? ?? 'No address available';
      final country = _countryFromAddress(address);
      _countryColorMap.putIfAbsent(
        country,
        () => countryHues[_countryColorMap.length % countryHues.length],
      );
      final hue = _countryColorMap[country]!;
      BitmapDescriptor icon;
      if (_iconCache.containsKey(hue)) {
        icon = _iconCache[hue]!;
      } else {
        icon = await _createCircleMarkerIcon(_colorFromHue(hue));
        _iconCache[hue] = icon;
      }
      temp.add(
        Marker(
          markerId: MarkerId(name),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: name, snippet: address),
          icon: icon,
          onTap: () {
            mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(lat, lng), _zoomOnFocus),
            );
          },
        ),
      );
    }
    if (mounted) {
      setState(() {
        _markers = temp.toSet();
      });
    }
    // Animate to latest marker once ready
    if (mapController != null && temp.isNotEmpty) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(temp.last.position, _zoomOnFocus),
      );
    }
  }

  Future<void> _showPinsSheet(
    Set<Marker> markers,
    Map<String, double> countryColorMap,
  ) async {
    setState(() => _isExpanded = true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.15),
      backgroundColor: Colors.white.withOpacity(0.92),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Group markers by country
        final grouped = <String, List<Marker>>{};
        for (var m in markers) {
          final country =
              m.infoWindow.snippet?.split(',').last.trim() ?? 'Unknown';
          grouped.putIfAbsent(country, () => []).add(m);
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          expand: false,
          builder:
              (ctx, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Your Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF062D40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children:
                          grouped.entries.map((entry) {
                            final country = entry.key;
                            final hue = countryColorMap[country] ?? 200;
                            final color = _colorFromHue(hue);
                            return ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              leading: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              title: Text(
                                country,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF062D40),
                                ),
                              ),
                              children:
                                  entry.value.map((marker) {
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                      title: Text(
                                        marker.markerId.value,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      onTap: () {
                                        Navigator.of(ctx).maybePop();
                                        mapController?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                            marker.position,
                                            _zoomOnFocus,
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
        );
      },
    );
    if (mounted) setState(() => _isExpanded = false);
  }

  void _onMapCreated(
    GoogleMapController controller,
    LatLng latestMarkerPosition,
  ) {
    mapController = controller;
    // Restore custom map style
    mapController?.setMapStyle(_mapStyle);
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latestMarkerPosition, _currentZoom),
    );
  }

  // ----------------------------MAP FUNCTIONALITY------------------------------
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final fromImports = args?['fromImports'] == true;
    final showDoneButton =
        args?['showDoneButton'] == true || widget.showDoneButton;
    final showBackToImportButton =
        args?['showBackToImportButton'] == true ||
        widget.showBackToImportButton;

    print("🛠 MapScreen build method called");
    final locs = ImportService.instance.importedLocations;
    print("Locations from ImportService: $locs");

    print("📍 Total markers ready: ${_markers.length}");

    if (_markers.isEmpty) {
      print('No markers available. Using default center.');
    }
    print("🧮 Calculating center of map");
    // Prefer latest imported location if available, else use prepared markers, else default center
    final latestLocCenter = _latestValidLatLngFromLocs(locs);
    final center =
        latestLocCenter ??
        (_markers.isNotEmpty ? _markers.last.position : _center);

    Widget mapBody;
    try {
      mapBody = GoogleMap(
        onMapCreated: (controller) => _onMapCreated(controller, center),
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: _markers.isNotEmpty ? 12 : 2,
        ),
        markers: _markers,
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
          // Overlay replaced with compact translucent bottom sheet opened via button
          Positioned(
            top: 60,
            left: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  _showPinsSheet(_markers, _countryColorMap);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.map_outlined
                            : Icons.location_on_outlined,
                        size: 18,
                        color: Color(0xFF062D40),
                      ),
                      SizedBox(width: 6),
                      Text(
                        _isExpanded ? "Hide Pins" : "Show Pins",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF062D40),
                        ),
                      ),
                    ],
                  ),
                ),
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
          if (showBackToImportButton)
            Positioned(
              bottom: 20,
              left: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back to Import Screen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black54,
                  elevation: 3,
                ),
              ),
            ),
          if (showDoneButton)
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        children:
            entry.value.map((marker) {
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
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
