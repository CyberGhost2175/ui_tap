import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/models/search/price_request_models.dart';
import '../../data/services/search_request_api_service.dart';
import '../../data/services/price_request_api_service.dart';
import '../../data/services/notification_service.dart';

/// ⬅️ FIXED: Кэширование предложений на 15 секунд + русские статусы + авточек каждые 15 сек
class ActiveSearchRequestScreen extends StatefulWidget {
  final int requestId;

  const ActiveSearchRequestScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<ActiveSearchRequestScreen> createState() => _ActiveSearchRequestScreenState();
}

class _ActiveSearchRequestScreenState extends State<ActiveSearchRequestScreen> {
  final SearchRequestApiService _apiService = SearchRequestApiService();
  final PriceRequestApiService _priceApiService = PriceRequestApiService();

  SearchRequest? _request;
  List<PriceRequest> _priceRequests = [];
  bool _isLoading = true;
  bool _isLoadingOffers = false;
  String? _error;

  Timer? _autoRefreshTimer;
  int _previousOffersCount = 0;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _loadRequest();
    _startAutoRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ⬅️ FIXED: При возврате к экрану перезагружаем предложения
    // Защита от лишних вызовов - перезагружаем только если прошло больше 1 секунды
    if (_request != null && !_isLoading) {
      final now = DateTime.now();
      if (_lastLoadTime == null || now.difference(_lastLoadTime!).inSeconds > 1) {
        _lastLoadTime = now;
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted && _request != null) {
            _loadPriceRequests(showToastIfNew: false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// ⬅️ FIXED: Проверка каждые 15 секунд (было 60)
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15), // ⬅️ ИЗМЕНЕНО: с 60 на 15
          (timer) {
        print('🔄 [AUTO-REFRESH] Проверяем новые предложения...');

        // ⬅️ Загружаем предложения для всех активных статусов
        if (_request?.status == 'OPEN_TO_PRICE_REQUEST' || 
            _request?.status == 'PRICE_REQUEST_PENDING') {
          _loadPriceRequests(showToastIfNew: true);
        } else {
          timer.cancel();
        }
      },
    );

    print('✅ [AUTO-REFRESH] Автообновление запущено (каждые 15 секунд)');
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = await _apiService.getSearchRequestById(widget.requestId);
      setState(() {
        _request = request;
        _isLoading = false;
      });

      // ⬅️ FIXED: Всегда загружаем предложения при загрузке заявки
      // чтобы видеть все активные предложения, даже если вышли и вернулись
      // Загружаем предложения для всех заявок (API сам вернет только активные)
      await _loadPriceRequests(showToastIfNew: false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPriceRequests({bool showToastIfNew = false}) async {
    if (!showToastIfNew) {
      setState(() {
        _isLoadingOffers = true;
      });
    }

    try {
      final requests = await _priceApiService.getPriceRequestsBySearchRequest(
        widget.requestId,
      );

      // ⬅️ Показываем ВСЕ активные предложения с бэкенда (WAITING)
      final allDisplayRequests = requests.where((pr) => 
        pr.clientResponseStatus == 'WAITING'
      ).toList();

      final currentCount = allDisplayRequests.length;
      
      // ⬅️ Получаем ID существующих предложений
      final previousOffersIds = _priceRequests.map((pr) => pr.id).toSet();
      
      // Определяем новые предложения (которые появились с последней проверки)
      final newOffersIds = allDisplayRequests.map((pr) => pr.id).toSet();
      final hasNewOffers = newOffersIds.difference(previousOffersIds).isNotEmpty;
      
      // Находим новые предложения
      final newOffers = allDisplayRequests.where((pr) => 
        !previousOffersIds.contains(pr.id)
      ).toList();

      setState(() {
        _priceRequests = allDisplayRequests;
        _isLoadingOffers = false;
      });

      if (hasNewOffers && showToastIfNew && mounted) {
        final newOffersCount = newOffers.length;
        _showNewOffersToast(newOffersCount);
        
        // Показываем уведомления для новых предложений
        for (var offer in newOffers) {
          await NotificationService().showNewOfferNotification(
            requestId: offer.searchRequestId,
            accommodationName: offer.safeAccommodationName,
            price: offer.price.toInt(),
          );
        }
      }

      _previousOffersCount = currentCount;

      if (showToastIfNew) {
        print('✅ [AUTO-REFRESH] Проверка завершена. Предложений: ${allDisplayRequests.length}');
      }
    } catch (e) {
      setState(() {
        _isLoadingOffers = false;
      });
      print('❌ [PRICE REQUESTS] Error: $e');
    }
  }

  void _showNewOffersToast(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.schedule, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Новое предложение!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    count == 1
                        ? 'Получено предложение от менеджера'
                        : 'Получено $count новых предложений',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }


  Future<void> _acceptPriceRequest(PriceRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 24.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Принять предложение?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Объект: ${request.accommodationName}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text(
              'Номер: ${request.accommodationUnitName}',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.green, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '${request.price} тг/ночь',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'После принятия менеджер получит уведомление и свяжется с вами для подтверждения.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Принять', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16.h),
              Text('Принимаем предложение...', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    try {
      print('📤 [ACCEPT] Accepting price request ${request.id}');

      await _priceApiService.acceptPriceRequest(request.id);
      print('✅ [ACCEPT] Success! Backend will create reservation automatically');

      if (!mounted) return;

      Navigator.pop(context);
      _autoRefreshTimer?.cancel();

      // Локально обновляем статус заявки, чтобы сразу запретить отмену/изменение цены
      setState(() {
        if (_request != null) {
          _request = _request!.copyWith(status: 'WAIT_TO_RESERVATION');
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Предложение принято!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Менеджер свяжется с вами для подтверждения бронирования',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      print('❌ [ACCEPT] Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ошибка принятия предложения',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                e.toString().replaceAll('Exception: ', ''),
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _rejectPriceRequest(PriceRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Отклонить предложение?',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Вы уверены, что хотите отклонить это предложение? Заявка останется активной.',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Отклонить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 16.h),
              Text('Отклоняем...', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    try {
      await _priceApiService.rejectPriceRequest(request.id);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Предложение отклонено. Заявка остается активной.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      await _loadPriceRequests();
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _updatePrice() async {
    final TextEditingController priceController = TextEditingController(
      text: _request!.price.toString(),
    );

    final newPrice = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.attach_money, color: const Color(0xFF295CDB), size: 24.sp),
            SizedBox(width: 8.w),
            Text('Изменить цену', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Текущая цена: ${_request!.price} тг/ночь',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
            SizedBox(height: 16.h),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Новая цена',
                suffixText: 'тг/ночь',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = int.tryParse(priceController.text);
              if (price != null && price > 0) {
                Navigator.pop(context, price);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF295CDB),
              foregroundColor: Colors.white,
            ),
            child: Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newPrice == null || newPrice == _request!.price) return;

    try {
      await _apiService.updateSearchRequestPrice(widget.requestId, newPrice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Цена обновлена'), backgroundColor: Colors.green),
      );
      await _loadRequest();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку?'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      _autoRefreshTimer?.cancel();

      await _apiService.cancelSearchRequest(widget.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка отменена'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            _autoRefreshTimer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: Text('Заявка на поиск', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (_request?.status == 'OPEN_TO_PRICE_REQUEST')
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: const Color(0xFF295CDB)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text('Ошибка загрузки', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 8.h),
            Text(_error!, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF295CDB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_request == null) return Center(child: Text('Заявка не найдена'));

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuccessCard(),
          SizedBox(height: 20.h),
          _buildStatusCard(),
          SizedBox(height: 20.h),

          // ⬅️ Показываем предложения для всех активных статусов
          if ((_request!.status == 'OPEN_TO_PRICE_REQUEST' || 
               _request!.status == 'PRICE_REQUEST_PENDING' ||
               _request!.status == 'WAIT_TO_RESERVATION') && 
              _priceRequests.isNotEmpty) ...[
            _buildPriceRequestsSection(),
            SizedBox(height: 20.h),
          ],

          _buildMainInfoCard(),
          SizedBox(height: 20.h),

          if (_request!.districts.isNotEmpty) ...[
            _buildDistrictsCard(),
            SizedBox(height: 20.h),
          ],

          _buildActionButtons(),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildPriceRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Предложения от менеджеров (${_priceRequests.length})',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        SizedBox(height: 12.h),
        ..._priceRequests.map((request) => _buildPriceRequestCard(request)),
      ],
    );
  }

  /// ⬅️ FIXED: Используем русские статусы из модели
  Widget _buildPriceRequestCard(PriceRequest request) {
    // ⬅️ БЕРЕМ СТАТУС ИЗ МОДЕЛИ (уже на русском!)
    final statusText = request.statusTextRussian;

    Color statusColor;
    IconData statusIcon;

    switch (request.clientResponseStatus) {
      case 'WAITING':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'ACCEPTED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                statusText,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            request.safeAccommodationName,

            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          SizedBox(height: 4.h),
          Text(
            request.safeAccommodationUnitName,

            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_money, color: Colors.green, size: 20.sp),
                SizedBox(width: 4.w),
                Text(
                  '${request.price} тг/ночь',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.green),
                ),
              ],
            ),
          ),
          if (request.clientResponseStatus == 'WAITING') ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectPriceRequest(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red, width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('Отклонить', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptPriceRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('Принять', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF295CDB), const Color(0xFF1E46A3)]),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, size: 32.sp, color: Colors.white),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Заявка успешно создана!',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 4.h),
                Text('Ожидайте предложений от менеджеров',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _request!.statusText;
    final statusCode = _request!.status;
    
    // Определяем цвет и иконку в зависимости от статуса
    Color statusColor;
    IconData statusIcon;
    
    switch (statusCode) {
      case 'OPEN_TO_PRICE_REQUEST':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'PRICE_REQUEST_PENDING':
        statusColor = Colors.amber; // Желтый цвет
        statusIcon = Icons.access_time; // Иконка часов
        break;
      case 'WAIT_TO_RESERVATION':
        statusColor = Colors.purple; // Фиолетовый цвет
        statusIcon = Icons.schedule; // Иконка часов
        break;
      case 'FINISHED':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Статус заявки', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                SizedBox(height: 4.h),
                Text(status,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⬅️ FIXED: Добавлен тип размещения на русском
  Widget _buildMainInfoCard() {
    final checkIn = DateFormat('dd MMM yyyy', 'ru').format(DateTime.parse(_request!.checkInDate));
    final checkOut = DateFormat('dd MMM yyyy', 'ru').format(DateTime.parse(_request!.checkOutDate));

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Основная информация',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.calendar_today, 'Заезд', checkIn),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.calendar_today_outlined, 'Выезд', checkOut),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.people, 'Гостей', '${_request!.countOfPeople} чел'),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.attach_money, 'Бюджет', '${_request!.price} тг/ночь'),
          SizedBox(height: 12.h),
          // ⬅️ НОВОЕ: Тип размещения
          _buildInfoRow(Icons.hotel, 'Тип', _request!.unitTypesText),
        ],
      ),
    );
  }

  Widget _buildDistrictsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: const Color(0xFF295CDB), size: 20.sp),
              SizedBox(width: 8.w),
              Text('Районы', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _request!.districts
                .map((d) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF295CDB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(d.name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Можно изменять цену и отменять заявку,
    // пока она открыта или ожидает предложений
    // и ещё НЕТ принятого предложения.
    final hasAcceptedOffer = _priceRequests.any(
      (pr) => pr.clientResponseStatus == 'ACCEPTED',
    );

    final canModify = (_request!.status == 'OPEN_TO_PRICE_REQUEST' ||
            _request!.status == 'PRICE_REQUEST_PENDING') &&
        !hasAcceptedOffer;

    if (!canModify) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _updatePrice,
            icon: Icon(Icons.edit, size: 20.sp, color: Colors.white),
            label: Text('Изменить цену',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF295CDB),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _cancelRequest,
            icon: Icon(Icons.cancel, size: 20.sp, color: Colors.white),
            label: Text('Отменить заявку',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: const Color(0xFF295CDB)),
        SizedBox(width: 12.w),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
