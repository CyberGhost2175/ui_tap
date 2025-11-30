import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/services/search_request_api_service.dart';
import '../../ui/widgets/map_widget.dart';
import '../../ui/widgets/search_panel_widget.dart';
import '../../ui/widgets/bottom_navigation_widget.dart';
import '../bookings/bookings_screen.dart';
import '../search/active_search_request_screen.dart';
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

  // Search params
  int _adults = 1;
  int _children = 0;
  String _filter = 'Отель';
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  String _customPrice = '20000';

  bool _isSelectingLocation = false;
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey<SearchPanelWidgetState> _searchPanelKey =
  GlobalKey<SearchPanelWidgetState>();

  void _handlePanelTap() {
    if (_panelState == PanelState.collapsed) {
      setState(() => _panelState = PanelState.expanded);
    }
  }

  void _collapsePanel() {
    setState(() => _panelState = PanelState.collapsed);
  }

  double _getPanelHeight() {
    switch (_panelState) {
      case PanelState.collapsed:
        return 300.h;
      case PanelState.expanded:
        return 750.h;
      case PanelState.hidden:
        return 0;
    }
  }

  /// 🔍 Выполнение поиска с отправкой на бэкенд
  Future<void> _performSearch() async {
    print('🔍 [SEARCH] Starting search...');

    // Показываем loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: const Color(0xFF295CDB)),
              SizedBox(height: 16.h),
              Text(
                'Создаем заявку...',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Получаем выбранные районы из search panel
      final searchPanelState = _searchPanelKey.currentState;
      List<int> selectedDistrictIds = [];

      if (searchPanelState != null) {
        try {
          // Попытка получить через геттер (если он добавлен)
          final districtId = searchPanelState.selectedDistrictId;
          if (districtId != null) {
            selectedDistrictIds = [districtId];
          }
        } catch (e) {
          // Если геттер не найден, используем дефолтные районы
          print('⚠️ [SEARCH] selectedDistrictId getter not found, using default districts');
          selectedDistrictIds = [1]; // Дефолтный район
        }
      }

      // Валидация - если районы не выбраны, используем дефолтный
      if (selectedDistrictIds.isEmpty) {
        print('⚠️ [SEARCH] No districts selected, using default');
        selectedDistrictIds = [1]; // Дефолтный район

        // Показываем предупреждение, но НЕ блокируем поиск
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Район не выбран, используем район по умолчанию'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Форматируем даты в формате "yyyy-MM-dd"
      final checkInDate = DateFormat('yyyy-MM-dd').format(_checkIn);
      final checkOutDate = DateFormat('yyyy-MM-dd').format(_checkOut);

      // Парсим цену
      final price = int.tryParse(_customPrice.replaceAll(RegExp(r'[^\d]'), '')) ?? 20000;

      // Определяем тип жилья
      final unitTypes = _filter == 'Отель' ? ['HOTEL_ROOM'] : ['APARTMENT'];

      // Создаем запрос
      final request = SearchRequestCreate(
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        oneNight: _checkOut.difference(_checkIn).inDays == 1,
        price: price,
        countOfPeople: _adults + _children,
        fromRating: 4, // По умолчанию
        toRating: 5,   // По умолчанию
        unitTypes: unitTypes,
        districtIds: selectedDistrictIds,
        // serviceDictionaryIds и conditionDictionaryIds опциональны
      );

      print('📤 [SEARCH] Request: ${request.toJson()}');

      // Отправляем запрос
      final apiService = SearchRequestApiService();
      final result = await apiService.createSearchRequest(request);

      print('✅ [SEARCH] Success! Request ID: ${result.id}');

      // Закрываем loader
      Navigator.pop(context);

      // Показываем экран с заявкой
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveSearchRequestScreen(
            requestId: result.id,
          ),
        ),
      );
    } catch (e) {
      print('❌ [SEARCH] Error: $e');

      // Закрываем loader
      Navigator.pop(context);

      // Показываем ошибку
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Парсим ошибку для более понятного сообщения
      if (errorMessage.contains('400')) {
        errorMessage = 'Некорректные параметры поиска. Проверьте заполненные поля.';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'Необходимо авторизоваться. Войдите в аккаунт.';
      } else if (errorMessage.contains('500')) {
        errorMessage = 'Ошибка сервера. Попробуйте позже.';
      }

      _showErrorDialog('Ошибка создания заявки', errorMessage);
    }
  }

  /// Показать диалог ошибки (ИСПРАВЛЕНО: без overflow)
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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