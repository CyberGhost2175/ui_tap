import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/models/search/price_request_models.dart';
import '../../data/services/price_request_api_service.dart';
import '../../features/search/active_search_request_screen.dart';

/// 📋 Компактная карточка активной заявки для горизонтального скролла
///
/// Отображает активную заявку пользователя с предложениями и таймерами
/// Оптимизирована для показа в списке
class ActiveRequestCardWidget extends StatefulWidget {
  final SearchRequest request;
  final VoidCallback? onRefresh;

  const ActiveRequestCardWidget({
    Key? key,
    required this.request,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ActiveRequestCardWidget> createState() => _ActiveRequestCardWidgetState();
}

class _ActiveRequestCardWidgetState extends State<ActiveRequestCardWidget> {
  final PriceRequestApiService _priceApiService = PriceRequestApiService();
  List<PriceRequest> _allWaitingOffers = []; // ⬅️ Все WAITING предложения с бэкенда
  List<PriceRequest> _displayOffers = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        // ⬅️ Загружаем предложения для всех активных заявок
        // (не только OPEN_TO_PRICE_REQUEST, но и PRICE_REQUEST_PENDING)
        if (widget.request.status == 'OPEN_TO_PRICE_REQUEST' || 
            widget.request.status == 'PRICE_REQUEST_PENDING') {
          _loadOffers();
        } else {
          timer.cancel();
        }
      },
    );
  }


  Future<void> _loadOffers() async {
    // ⬅️ Загружаем предложения для всех активных заявок
    // (не только OPEN_TO_PRICE_REQUEST, но и PRICE_REQUEST_PENDING)
    if (widget.request.status != 'OPEN_TO_PRICE_REQUEST' && 
        widget.request.status != 'PRICE_REQUEST_PENDING') {
      // Если заявка не активна, очищаем предложения
      setState(() {
        _displayOffers = [];
        _allWaitingOffers = [];
      });
      return;
    }

    try {
      final requests = await _priceApiService.getPriceRequestsBySearchRequest(
        widget.request.id,
      );

      final now = DateTime.now();

      // ⬅️ Сохраняем все WAITING предложения с бэкенда
      final waitingOffers = requests.where((pr) => 
        pr.clientResponseStatus == 'WAITING'
      ).toList();

      print('📥 [CARD] Loaded ${waitingOffers.length} WAITING offers from backend');


      // ⬅️ Сохраняем все WAITING предложения
      setState(() {
        _allWaitingOffers = waitingOffers;
      });

      _updateDisplayOffers();
    } catch (e) {
      print('❌ [CARD] Error loading offers: $e');
    }
  }

  void _updateDisplayOffers() {
    // ⬅️ Показываем ВСЕ активные предложения со статусом WAITING
    if (mounted) {
      setState(() {
        _displayOffers = _allWaitingOffers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkInDate = DateFormat('dd MMM', 'ru').format(
      DateTime.parse(widget.request.checkInDate),
    );
    final checkOutDate = DateFormat('dd MMM', 'ru').format(
      DateTime.parse(widget.request.checkOutDate),
    );

    // Определяем цвет статуса
    Color statusColor;
    IconData statusIcon;

    switch (widget.request.status) {
      case 'OPEN_TO_PRICE_REQUEST':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'CLOSED':
        statusColor = Colors.grey;
        statusIcon = Icons.lock;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return GestureDetector(
      onTap: () {
        // Переход на экран заявки
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveSearchRequestScreen(
              requestId: widget.request.id,
            ),
          ),
        ).then((_) {
          // После возврата обновляем данные
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
          // Перезагружаем предложения при возврате
          _loadOffers();
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        padding: EdgeInsets.all(12.w), // ⬅️ Уменьшил с 14 до 12
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF295CDB),
              const Color(0xFF1E46A3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF295CDB).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header: Статус + ID
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: statusColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Активна',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '#${widget.request.id}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Основная информация (компактная)
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info Row 1: Даты
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          '$checkInDate - $checkOutDate',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 5.h),

                  // Info Row 2: Гости и Тип
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${widget.request.countOfPeople} чел',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(
                        Icons.home,
                        size: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          widget.request.unitTypesText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 5.h),

                  // Info Row 3: Цена
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${widget.request.price} тг/ночь',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Предложения с таймерами (заметная версия)
            if (_displayOffers.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), // ⬅️ Уменьшено с 8.h до 6.h
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.25), // ⬅️ Более заметный фон
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3.w), // ⬅️ Уменьшено с 4.w до 3.w
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            Icons.local_offer,
                            size: 13.sp, // ⬅️ Уменьшено с 14.sp до 13.sp
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Новое предложение!',
                            style: TextStyle(
                              fontSize: 11.5.sp, // ⬅️ Уменьшено с 12.sp до 11.5.sp
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    ..._displayOffers.take(1).map((offer) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offer.safeAccommodationName,
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '${offer.price} тг/ночь',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                ),
              ),
            ],

            // Districts (показываем только если нет предложений и есть место)
            if (widget.request.districts.isNotEmpty && _displayOffers.isEmpty) ...[
              SizedBox(height: 6.h),
              Wrap(
                spacing: 4.w,
                runSpacing: 4.h,
                children: widget.request.districts.take(2).map((district) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      district.name,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

