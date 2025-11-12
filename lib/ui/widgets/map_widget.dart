import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final bool isSelectingLocation;
  final VoidCallback onMapDragStart;
  final VoidCallback onMapDragEnd;

  const MapWidget({
    Key? key,
    required this.isSelectingLocation,
    required this.onMapDragStart,
    required this.onMapDragEnd,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  late final MapController _mapController;
  LatLng _currentCenter = const LatLng(51.1694, 71.4491); // Astana
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
      _currentCenter = _userLocation!;
    });
  }

  void goToCurrentLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    }
  }

  void startSelectingLocation() => setState(() {});
  void stopSelectingLocation() => setState(() {});
  void confirmLocation() => debugPrint('Confirmed location: $_currentCenter');

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: 13.5,
        onMapEvent: (event) {
          if (event is MapEventMoveStart) {
            widget.onMapDragStart();
          }
          if (event is MapEventMoveEnd) {
            // 🧭 в новой версии центр хранится в event.camera.center
            setState(() => _currentCenter = event.camera.center);
            widget.onMapDragEnd();
          }
        },
      ),
      children: [
        // 🗺️ Слой карты
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ui_tap',
        ),

        // 🔵 Радиус вокруг центра
        CircleLayer(
          circles: [
            CircleMarker(
              point: _currentCenter,
              radius: 120,
              color: Colors.blue.withOpacity(0.2),
              borderStrokeWidth: 2,
              borderColor: Colors.blueAccent,
            ),
          ],
        ),

        // 📍 Центральный маркер
        MarkerLayer(
          markers: [
            Marker(
              point: _currentCenter,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 34,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
