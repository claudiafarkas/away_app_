import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:away/services/import_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/views/imported/import_post_screen.dart';
import 'package:away/widgets/soft_tile.dart';
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
          "color": "#c9dce8"
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
  List<Map<String, dynamic>> _pins = [];
  List<Map<String, dynamic>> _swipePins = [];
  Map<String, dynamic>? _selectedPin;
  PageController? _pageController;
  bool _syncingPage = false;

  PageController _ensurePageController() {
    return _pageController ??= PageController(viewportFraction: 0.92);
  }

  @override
  void initState() {
    super.initState();
    ImportService.instance.addListener(_onImportsChanged);
    _prepareMarkers();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    ImportService.instance.removeListener(_onImportsChanged);
    super.dispose();
  }

  void _onImportsChanged() {
    _prepareMarkers();
  }

  Color _colorFromHue(double hue) {
    final hsv = HSVColor.fromAHSV(1.0, hue, 0.65, 0.95);
    return hsv.toColor();
  }

  String _countryForLoc(Map<String, dynamic> loc) {
    final country = (loc['country'] as String? ?? '').trim();
    if (country.isNotEmpty) return country;
    return _countryFromAddress(loc['address'] as String? ?? '');
  }

  double _hueForCountry(String country) {
    return _countryColorMap.putIfAbsent(
      country,
      () => countryHues[country.hashCode.abs() % countryHues.length],
    );
  }

  bool _isSamePin(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a['name'] == b['name'] && a['lat'] == b['lat'] && a['lng'] == b['lng'];
  }

  double _distanceSq(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }

  List<Map<String, dynamic>> _pinsByDistanceFrom(Map<String, dynamic> originLoc) {
    final origin = _latLngFromLoc(originLoc);
    final ordered = <Map<String, dynamic>>[];
    for (final pin in _pins) {
      if (_latLngFromLoc(pin) != null) {
        ordered.add(Map<String, dynamic>.from(pin));
      }
    }
    if (origin == null) return ordered;
    ordered.sort((a, b) {
      final aOrigin = _isSamePin(a, originLoc);
      final bOrigin = _isSamePin(b, originLoc);
      if (aOrigin && !bOrigin) return -1;
      if (bOrigin && !aOrigin) return 1;
      return _distanceSq(origin, _latLngFromLoc(a)!).compareTo(
        _distanceSq(origin, _latLngFromLoc(b)!),
      );
    });
    return ordered;
  }

  void _openPin(Map<String, dynamic> loc, {bool zoomIn = true}) {
    final latLng = _latLngFromLoc(loc);
    if (latLng == null) return;
    _syncingPage = true;
    setState(() {
      _selectedPin = Map<String, dynamic>.from(loc);
      _swipePins = _pinsByDistanceFrom(loc);
    });
    mapController?.animateCamera(
      zoomIn
          ? CameraUpdate.newLatLngZoom(latLng, _zoomOnFocus)
          : CameraUpdate.newLatLng(latLng),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _pageController;
      if (controller != null && controller.hasClients) {
        controller.jumpToPage(0);
      }
      _syncingPage = false;
    });
  }

  void _onSwipePage(int index) {
    if (_syncingPage) return;
    if (index < 0 || index >= _swipePins.length) return;
    final pin = _swipePins[index];
    if (_selectedPin != null && _isSamePin(pin, _selectedPin!)) return;
    setState(() => _selectedPin = Map<String, dynamic>.from(pin));
    final latLng = _latLngFromLoc(pin);
    if (latLng != null) {
      mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    }
  }

  LatLng? _latLngFromLoc(Map<String, dynamic> loc) {
    try {
      final lat =
          loc['lat'] is double
              ? loc['lat'] as double
              : (loc['lat'] as num).toDouble();
      final lng =
          loc['lng'] is double
              ? loc['lng'] as double
              : (loc['lng'] as num).toDouble();
      if (lat == 0.0 && lng == 0.0) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
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
      final country = _countryForLoc(l);
      final hue = _hueForCountry(country);
      BitmapDescriptor icon;
      if (_iconCache.containsKey(hue)) {
        icon = _iconCache[hue]!;
      } else {
        icon = await _createCircleMarkerIcon(_colorFromHue(hue));
        _iconCache[hue] = icon;
      }
      final loc = Map<String, dynamic>.from(l);
      temp.add(
        Marker(
          markerId: MarkerId('${name}_${lat}_$lng'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow.noText,
          consumeTapEvents: true,
          icon: icon,
          onTap: () => _openPin(loc),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _markers = temp.toSet();
        _pins = [
          for (final l in locs)
            if (_latLngFromLoc(l) != null) Map<String, dynamic>.from(l),
        ];
        if (_selectedPin != null) {
          final stillThere = _pins.any((loc) => _isSamePin(loc, _selectedPin!));
          if (!stillThere) {
            _selectedPin = null;
            _swipePins = [];
          } else {
            _swipePins = _pinsByDistanceFrom(_selectedPin!);
          }
        }
      });
    }
    // Animate to latest marker once ready
    if (mapController != null && temp.isNotEmpty) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(temp.last.position, _zoomOnFocus),
      );
    }
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
        zoomControlsEnabled: false,
        zoomGesturesEnabled: true,
        myLocationButtonEnabled: false,
        onTap: (_) {
          if (_selectedPin != null) {
            setState(() {
              _selectedPin = null;
              _swipePins = [];
            });
          }
        },
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
    final overlayTop = MediaQuery.of(context).padding.top + 8;
    final overlayBottom =
        (showDoneButton || showBackToImportButton)
            ? MediaQuery.of(context).padding.bottom + 96
            : MediaQuery.of(context).padding.bottom + 118;
    return Scaffold(
      body: Stack(
        children: [
          mapBody,
          Positioned(
            top: overlayTop,
            right: 12,
            child: Column(
              children: [
                GlassPill(
                  padding: const EdgeInsets.all(10),
                  onTap: () {
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
                  child: const Icon(Icons.add, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                GlassPill(
                  padding: const EdgeInsets.all(10),
                  onTap: () {
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
                  child: const Icon(Icons.remove, color: AppColors.ink),
                ),
              ],
            ),
          ),
          if (showBackToImportButton)
            Positioned(
              bottom: 28,
              left: 20,
              child: GlassPill(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                    SizedBox(width: 6),
                    Text(
                      'Back to import',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showDoneButton)
            Positioned(
              bottom: 28,
              right: 20,
              child: GlassPill(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.check_rounded, size: 18, color: AppColors.ink),
                    SizedBox(width: 6),
                    Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedPin != null && _swipePins.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: overlayBottom,
              child: SizedBox(
                height: 52,
                child: PageView.builder(
                  controller: _ensurePageController(),
                  physics:
                      _swipePins.length > 1
                          ? const PageScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          )
                          : const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: _swipePins.length,
                  onPageChanged: _onSwipePage,
                  itemBuilder: (context, index) {
                    final pin = _swipePins[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _MapPinPopup(
                        pin: pin,
                        onClose: () {
                          setState(() {
                            _selectedPin = null;
                            _swipePins = [];
                          });
                        },
                        onOpen: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImportPostScreen(pin: pin),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _MapPinPopup extends StatelessWidget {
  final Map<String, dynamic> pin;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const _MapPinPopup({
    required this.pin,
    required this.onClose,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final name = pin['name'] as String? ?? 'Unknown';
    final address = pin['address'] as String? ?? '';

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 2, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    _PinThumb(
                      pin: pin,
                      gradientIndex: name.hashCode,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.15,
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinThumb extends StatelessWidget {
  final Map<String, dynamic> pin;
  final int gradientIndex;
  final double size;

  const _PinThumb({
    required this.pin,
    required this.gradientIndex,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final thumbUrl = (pin['thumbnailUrl'] as String? ?? '').trim();
    final hasThumb =
        thumbUrl.startsWith('http://') || thumbUrl.startsWith('https://');
    final fallback =
        AppColors.pinFallbackGradients[gradientIndex.abs() %
            AppColors.pinFallbackGradients.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumb)
              Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return DecoratedBox(
                    decoration: BoxDecoration(gradient: fallback),
                  );
                },
              )
            else
              DecoratedBox(decoration: BoxDecoration(gradient: fallback)),
            if (!hasThumb)
              Icon(
                Icons.place_rounded,
                color: Colors.white.withValues(alpha: 0.82),
                size: size * 0.36,
              ),
          ],
        ),
      ),
    );
  }
}
