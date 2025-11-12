import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../ui/widgets/map_widget.dart';
import '../../ui/widgets/search_panel_widget.dart';
import '../../ui/widgets/bottom_navigation_widget.dart';

enum PanelState { collapsed, expanded, hidden }

class BookingSearchScreen extends StatefulWidget {
  const BookingSearchScreen({Key? key}) : super(key: key);

  @override
  State<BookingSearchScreen> createState() => _BookingSearchScreenState();
}

class _BookingSearchScreenState extends State<BookingSearchScreen> {
  PanelState _panelState = PanelState.collapsed;
  PanelState? _previousPanelState;

  bool _isDraggingMap = false;

  int _adults = 1;
  int _children = 0;
  String _filter = 'Квартира';
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 6));
  String _customPrice = '';

  bool _isSelectingLocation = false;
  int _currentIndex = 0;

  final GlobalKey<MapWidgetState> _mapKey = GlobalKey<MapWidgetState>();

  double _getPanelHeight() {
    switch (_panelState) {
      case PanelState.collapsed:
        return 300.h;
      case PanelState.expanded:
        return 0.75.sh;
      case PanelState.hidden:
        return 0;
    }
  }

  void _handlePanelTap() {
    if (_panelState == PanelState.collapsed) {
      setState(() => _panelState = PanelState.expanded);
    }
  }

  void _collapsePanel() {
    if (_panelState == PanelState.expanded) {
      setState(() => _panelState = PanelState.collapsed);
    }
  }

  void _toggleMapMode() {
    setState(() {
      if (_panelState == PanelState.hidden) {
        _panelState = PanelState.collapsed;
        _isSelectingLocation = false;
        _mapKey.currentState?.stopSelectingLocation();
      } else {
        _panelState = PanelState.hidden;
        _isSelectingLocation = true;
        _mapKey.currentState?.startSelectingLocation();
      }
    });
  }

  void _confirmLocation() {
    setState(() {
      _isSelectingLocation = false;
      _panelState = PanelState.collapsed;
      _mapKey.currentState?.confirmLocation();
    });
  }

  void _goToCurrentLocation() {
    _mapKey.currentState?.goToCurrentLocation();
  }

  Future<Position?> _getUserPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _performSearch() async {
    final pos = await _getUserPosition();
    final payload = {
      'adults': _adults,
      'children': _children,
      'filter': _filter,
      'checkIn': _checkIn.toIso8601String(),
      'checkOut': _checkOut.toIso8601String(),
      'customPrice': _customPrice.isEmpty ? null : int.tryParse(_customPrice),
      'userLocation': pos == null
          ? null
          : {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      },
    };
    debugPrint('SEARCH PAYLOAD: $payload');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: _mapKey,
            isSelectingLocation: _isSelectingLocation,
            onMapDragStart: () {
              _previousPanelState = _panelState;
              _isDraggingMap = true;
              setState(() => _panelState = PanelState.hidden);
            },
            onMapDragEnd: () async {
              await Future.delayed(const Duration(milliseconds: 150));
              if (mounted) {
                setState(() {
                  _isDraggingMap = false;
                  _panelState = _previousPanelState ?? PanelState.collapsed;
                });
              }
            },
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: 0,
            height: _getPanelHeight(),
            child: SearchPanelWidget(
              panelState: _panelState,
              adults: _adults,
              children: _children,
              filter: _filter,
              checkIn: _checkIn,
              checkOut: _checkOut,
              price: _customPrice,
              onPanelTap: _handlePanelTap,
              onCloseTap: _collapsePanel,
              onAdultsChanged: (v) => setState(() => _adults = v),
              onChildrenChanged: (v) => setState(() => _children = v),
              onFilterChanged: (v) => setState(() => _filter = v),
              onCheckInChanged: (d) => setState(() {
                _checkIn = d;
                if (_checkOut.isBefore(_checkIn)) {
                  _checkOut = _checkIn.add(const Duration(days: 1));
                }
              }),
              onCheckOutChanged: (d) => setState(() => _checkOut = d),
              onPriceChanged: (v) => setState(() => _customPrice = v),
              onSearch: _performSearch,
            ),
          ),

          if (_isSelectingLocation)
            Positioned(
              bottom: 80.h,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF295CDB),
                    padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 8,
                  ),
                  child: Text(
                    'Подтвердить',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          if (!_isSelectingLocation)
            Positioned(
              right: 24.w,
              bottom: 88.h,
              child: FloatingActionButton(
                onPressed: _goToCurrentLocation,
                backgroundColor: const Color(0xFF295CDB),
                elevation: 8,
                child: Icon(Icons.my_location, size: 24.sp, color: Colors.white),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavigationWidget(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}
