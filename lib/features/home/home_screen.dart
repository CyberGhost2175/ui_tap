import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/services/search_request_api_service.dart';
import '../../ui/widgets/map_widget.dart';
import '../../ui/widgets/search_panel_widget.dart';
import '../../ui/widgets/active_request_card_widget.dart';
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
  String _customPrice = ''; // ⬅️ ИСПРАВЛЕНО: Пустая строка по умолчанию

  bool _isSelectingLocation = false;
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey<SearchPanelWidgetState> _searchPanelKey =
  GlobalKey<SearchPanelWidgetState>();

  // ⬅️ НОВОЕ: Активные заявки (список)
  List<SearchRequest> _activeRequests = [];
  bool _isLoadingActiveRequest = false;

  @override
  void initState() {
    super.initState();
    _loadActiveRequest();
  }

  /// 📥 Загрузка всех активных заявок
  Future<void> _loadActiveRequest() async {
    setState(() => _isLoadingActiveRequest = true);

    try {
      final apiService = SearchRequestApiService();
      final requests = await apiService.getAllSearchRequests(
        page: 0,
        size: 20, // Загружаем до 20 заявок
        sortBy: 'id',
        sortDirection: 'desc',
      );

      // Берём только активные заявки (не отменённые и не закрытые)
      setState(() {
        _activeRequests = requests;  // ← Все заявки (не фильтруем!)
        _isLoadingActiveRequest = false;
      });

      print('✅ [HOME] My requests loaded: ${_activeRequests.length}');


      print('✅ [HOME] Active requests loaded: ${_activeRequests.length}');
    } catch (e) {
      print('❌ [HOME] Error loading active requests: $e');
      setState(() {
        _activeRequests = [];
        _isLoadingActiveRequest = false;
      });
    }
  }

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

    // ⬅️ НОВОЕ: ВАЛИДАЦИЯ ВСЕХ ПОЛЕЙ
    final validationError = _validateSearchFields();
    if (validationError != null) {
      _showValidationError(validationError);
      return;
    }

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
      // ⬅️ ИЗМЕНЕНО: Используем новый метод getSelectedDistrictIds()
      final searchPanelState = _searchPanelKey.currentState;
      List<int> selectedDistrictIds = [];

      if (searchPanelState != null) {
        selectedDistrictIds = searchPanelState.getSelectedDistrictIds();
      }

      // Эта проверка уже не нужна, т.к. валидация выше
      if (selectedDistrictIds.isEmpty) {
        print('⚠️ [SEARCH] No districts selected after validation - should not happen');
        selectedDistrictIds = [1];
      }

      final checkInDate = DateFormat('yyyy-MM-dd').format(_checkIn);
      final checkOutDate = DateFormat('yyyy-MM-dd').format(_checkOut);
      final price = int.tryParse(_customPrice.replaceAll(RegExp(r'[^\d]'), '')) ?? 20000;

      // ⬅️ ИЗМЕНЕНО: Правильная конвертация фильтра
      final unitTypes = _filter == 'Все'
          ? ['HOTEL_ROOM', 'APARTMENT']
          : _filter == 'Отель'
          ? ['HOTEL_ROOM']
          : ['APARTMENT'];

      final request = SearchRequestCreate(
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        oneNight: _checkOut.difference(_checkIn).inDays == 1,
        price: price,
        countOfPeople: _adults + _children,
        fromRating: 4,
        toRating: 5,
        unitTypes: unitTypes,
        districtIds: selectedDistrictIds,
      );

      print('📤 [SEARCH] Request: ${request.toJson()}');
      print('📍 [SEARCH] Districts: $selectedDistrictIds (${selectedDistrictIds.length} districts)');

      final apiService = SearchRequestApiService();
      final result = await apiService.createSearchRequest(request);

      print('✅ [SEARCH] Success! Request ID: ${result.id}');

      // Закрываем loader
      Navigator.pop(context);

      // ⬅️ ИЗМЕНЕНО: Показываем заявку, а затем возвращаемся на главный
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveSearchRequestScreen(
            requestId: result.id,
          ),
        ),
      );

      // ⬅️ НОВОЕ: После возврата обновляем активную заявку и сворачиваем панель
      setState(() {
        _panelState = PanelState.collapsed;
      });
      await _loadActiveRequest();

    } catch (e) {
      print('❌ [SEARCH] Error: $e');

      Navigator.pop(context);

      String errorMessage = e.toString().replaceAll('Exception: ', '');

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

  /// ⬅️ НОВОЕ: Валидация полей поиска
  String? _validateSearchFields() {
    // 1. Даты
    if (_checkIn.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Дата заезда не может быть в прошлом';
    }
    if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
      return 'Дата выезда должна быть позже даты заезда';
    }

    // 2. Количество людей
    if (_adults < 1) {
      return 'Укажите количество взрослых (минимум 1)';
    }
    if (_adults + _children > 10) {
      return 'Максимальное количество гостей: 10 человек';
    }

    // 3. Город
    final searchPanelState = _searchPanelKey.currentState;
    if (searchPanelState == null) {
      return 'Ошибка: панель поиска не инициализирована';
    }

    final location = searchPanelState.getSelectedLocation();
    if (location['cityId'] == null) {
      return 'Выберите город';
    }

    // 4. Район
    if (location['districtId'] == null) {
      return 'Выберите район';
    }

    final districtIds = location['districtIds'] as List<int>?;
    if (districtIds == null || districtIds.isEmpty) {
      return 'Выберите район';
    }

    // 5. Тип размещения
    if (_filter.isEmpty) {
      return 'Выберите тип размещения';
    }

    // 6. Цена
    if (_customPrice.isEmpty) {
      return 'Укажите цену за ночь';
    }

    final price = int.tryParse(_customPrice.replaceAll(RegExp(r'[^\d]'), ''));
    if (price == null || price <= 0) {
      return 'Укажите корректную цену (больше 0)';
    }

    if (price < 1000) {
      return 'Минимальная цена: 1 000 тг/ночь';
    }

    if (price > 1000000) {
      return 'Максимальная цена: 1 000 000 тг/ночь';
    }

    // Всё ОК
    return null;
  }

  /// ⬅️ НОВОЕ: Показать ошибку валидации
  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Заполните все поля',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 15.sp,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF295CDB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Понятно',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

        // ------------------------ ACTIVE REQUESTS LIST ------------------------
        // ⬅️ НОВОЕ: Горизонтальный список активных заявок
        if (_activeRequests.isNotEmpty && _panelState == PanelState.collapsed)
          Positioned(
            bottom: 230.h, // ⬅️ Поднял выше (было 180)
            left: 0,
            right: 0,
            height: 210.h, // ⬅️ Увеличил высоту (было 195)
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              itemCount: _activeRequests.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 340.w,
                  height: 180.h, // ⬅️ ДОБАВИЛ фиксированную высоту
                  child: ActiveRequestCardWidget(
                    request: _activeRequests[index],
                    onRefresh: _loadActiveRequest,
                  ),
                );
              },
            ),
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