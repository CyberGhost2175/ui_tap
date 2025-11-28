import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/services/search_request_api_service.dart';
import '../../ui/widgets/map_widget.dart';
import '../../ui/widgets/search_panel_widget.dart';
import '../../ui/widgets/bottom_navigation_widget.dart';
import '../bookings/bookings_screen.dart';
import '../search/search_request_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';

enum PanelState { collapsed, expanded, hidden }

class BookingSearchScreen extends StatefulWidget {
  const BookingSearchScreen({Key? key}) : super(key: key);

  @override
  State<BookingSearchScreen> createState() => _BookingSearchScreenState();
}

class _BookingSearchScreenState extends State<BookingSearchScreen> {
  int _currentIndex = 0;

  PanelState _panelState = PanelState.collapsed;
  PanelState? _previousPanelState;
  bool _isSelectingLocation = false;

  int _adults = 1;
  int _children = 0;
  String _filter = 'Квартира';
  String _customPrice = '';
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 6));

  final GlobalKey<MapWidgetState> _mapKey = GlobalKey<MapWidgetState>();
  final GlobalKey<SearchPanelWidgetState> _searchPanelKey = GlobalKey<SearchPanelWidgetState>();

  double _getPanelHeight() {
    switch (_panelState) {
      case PanelState.collapsed:
        return 300.h;
      case PanelState.expanded:
        return 0.95.sh;
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
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _performSearch() async {
    try {
      final location = _searchPanelKey.currentState?.getSelectedLocation();

      final request = SearchRequestCreate(
        checkInDate: DateFormat('yyyy-MM-dd').format(_checkIn),
        checkOutDate: DateFormat('yyyy-MM-dd').format(_checkOut),
        oneNight: false,
        price: int.tryParse(_customPrice) ?? 0,
        countOfPeople: _adults + _children,
        fromRating: 1,
        toRating: 5,
        unitTypes: [_filter == 'Отель' ? 'HOTEL_ROOM' : 'APARTMENT'],
        districtIds: location?['districtId'] != null
            ? [location!['districtId'] as int] : [],
      );

      final apiService = SearchRequestApiService();
      final result = await apiService.createSearchRequest(request);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchRequestDetailScreen(
            requestId: result.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }


  Widget _buildHomeTab() {
    return Stack(
      children: [
        // ------------------------ MAP ------------------------
        MapWidget(
          key: _mapKey,
          isSelectingLocation: _isSelectingLocation,
          onMapDragStart: () {
            _previousPanelState = _panelState;
            setState(() => _panelState = PanelState.hidden);
          },
          onMapDragEnd: () async {
            await Future.delayed(const Duration(milliseconds: 150));
            if (!mounted) return;
            setState(() => _panelState = _previousPanelState ?? PanelState.collapsed);
          },
        ),

        // ------------------------ SEARCH PANEL ------------------------
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          top: 0,
          height: _getPanelHeight(),
          child: SearchPanelWidget(
            key: _searchPanelKey,
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
            onCheckInChanged: (d) {
              setState(() {
                _checkIn = d;
                if (_checkOut.isBefore(_checkIn)) {
                  _checkOut = _checkIn.add(const Duration(days: 1));
                }
              });
            },
            onCheckOutChanged: (d) => setState(() => _checkOut = d),
            onPriceChanged: (v) => setState(() => _customPrice = v),
            onSearch: _performSearch,
          ),
        ),

        // ------------------------ CONFIRM BUTTON ------------------------
        if (_isSelectingLocation)
          Positioned(
            bottom: 80.h,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2853AF),
                  padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: Text(
                  "Подтвердить",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // ------------------------ USER LOCATION BUTTON ------------------------
        // Only show when panel is collapsed (not expanded and not selecting location)
        if (_panelState == PanelState.collapsed && !_isSelectingLocation)
          Positioned(
            right: 24.w,
            bottom: 30.h,
            child: GestureDetector(
              onTap: _goToCurrentLocation,
              child: Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF2853AF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/location_icon.svg',
                    width: 28.w,
                    height: 28.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const BookingsScreen(),
          const SettingsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}