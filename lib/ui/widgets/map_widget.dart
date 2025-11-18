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

  LatLng _center = const LatLng(51.1694, 71.4491); // fallback — Astana
  LatLng? _gpsLocation; // текущее положение пользователя

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
  }

  /// Получаем GPS и двигаем карту
  Future<void> _initLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    LocationPermission p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();

    _gpsLocation = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _center = _gpsLocation!;
    });

    /// 🔥 Двигаем карту на текущее местоположение (zoom = 16)
    _mapController.move(_gpsLocation!, 16);
  }

  /// Нажатие на кнопку "моё местоположение"
  void goToCurrentLocation() async {
    if (_gpsLocation == null) {
      await _initLocation();
    }

    if (_gpsLocation != null) {
      _center = _gpsLocation!;
      _mapController.move(_gpsLocation!, 16);
      setState(() {});
    }
  }

  /// Подтверждение выбранной точки
  void confirmLocation() {
    debugPrint("CONFIRMED LOCATION: $_center");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 16, // 🔥 карта ВСЕГДА чуть приближена
            maxZoom: 18,
            minZoom: 10,
            onMapEvent: (event) {
              if (event is MapEventMoveStart) {
                widget.onMapDragStart();
              }

              if (event is MapEventMoveEnd) {
                setState(() {
                  _center = event.camera.center;
                });
                widget.onMapDragEnd();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.example.ui_tap",
            ),
          ],
        ),

        // 🔵 Радиус вокруг маркера
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.15),
            border: Border.all(
              color: Colors.blue.withOpacity(0.45),
              width: 2,
            ),
          ),
        ),

        // 📍 Маркер в центре
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              size: 48,
              color: Colors.blue,
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
