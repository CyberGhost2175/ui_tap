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
  final Map<int, _CachedPriceRequest> _cachedOffers = {};
  List<PriceRequest> _displayOffers = [];
  Timer? _refreshTimer;
  Timer? _cleanupTimer;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _startAutoRefresh();
    _startCleanupTimer();
    _startUIUpdateTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cleanupTimer?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        if (widget.request.status == 'OPEN_TO_PRICE_REQUEST') {
          _loadOffers();
        } else {
          timer.cancel();
        }
      },
    );
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final now = DateTime.now();
        _cachedOffers.removeWhere((id, cached) {
          return now.difference(cached.addedAt).inSeconds > 15;
        });
        _updateDisplayOffers();
      },
    );
  }

  void _startUIUpdateTimer() {
    _uiUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (mounted) {
          setState(() {}); // Обновляем UI для анимации таймера
        }
      },
    );
  }

  Future<void> _loadOffers() async {
    if (widget.request.status != 'OPEN_TO_PRICE_REQUEST') return;

    try {
      final requests = await _priceApiService.getPriceRequestsBySearchRequest(
        widget.request.id,
      );

      final now = DateTime.now();

      for (var request in requests) {
        if (!_cachedOffers.containsKey(request.id)) {
          _cachedOffers[request.id] = _CachedPriceRequest(
            request: request,
            addedAt: now,
          );
        } else {
          _cachedOffers[request.id] = _CachedPriceRequest(
            request: request,
            addedAt: _cachedOffers[request.id]!.addedAt,
          );
        }
      }

      _updateDisplayOffers();
    } catch (e) {
      print('❌ [CARD] Error loading offers: $e');
    }
  }

  void _updateDisplayOffers() {
    final now = DateTime.now();
    final newOffers = _cachedOffers.values
        .where((cached) {
          final age = now.difference(cached.addedAt).inSeconds;
          return age <= 15 && cached.request.clientResponseStatus == 'WAITING';
        })
        .map((cached) => cached.request)
        .toList();

    if (mounted) {
      setState(() {
        _displayOffers = newOffers;
      });
    }
  }

  double _getTimerProgress(_CachedPriceRequest cached) {
    final now = DateTime.now();
    final age = now.difference(cached.addedAt).inSeconds;
    return (15 - age) / 15; // От 1.0 до 0.0 за 15 секунд
  }

  int _getRemainingSeconds(_CachedPriceRequest cached) {
    final now = DateTime.now();
    final age = now.difference(cached.addedAt).inSeconds;
    return (15 - age).clamp(0, 15);
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

            SizedBox(height: 8.h), // ⬅️ Уменьшил с 10 до 8

            // Info Row 1: Даты
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
                SizedBox(width: 6.w),
                Text(
                  '$checkInDate - $checkOutDate',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6.h), // ⬅️ Уменьшил с 8 до 6

            // Info Row 2: Гости и Тип
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 14.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
                SizedBox(width: 6.w),
                Text(
                  '${widget.request.countOfPeople} чел',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  Icons.home,
                  size: 14.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    widget.request.unitTypesText,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6.h), // ⬅️ Уменьшил с 8 до 6

            // Info Row 3: Цена
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 14.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${widget.request.price} тг/ночь',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6.h),

            // Предложения с таймерами (заметная версия)
            if (_displayOffers.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            Icons.local_offer,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Новое предложение!',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ..._displayOffers.take(1).map((offer) {
                      final cached = _cachedOffers[offer.id]!;
                      final progress = _getTimerProgress(cached);
                      final remaining = _getRemainingSeconds(cached);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offer.safeAccommodationName,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${offer.price} тг/ночь',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: remaining > 5 ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  '${remaining}с',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          // Полоса прогресса таймера
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3.r),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 3.h,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remaining > 5 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
            ],

            // Districts (показываем только если есть место)
            if (widget.request.districts.isNotEmpty && _displayOffers.isEmpty) ...[
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

/// Модель для кэширования предложений с временем добавления
class _CachedPriceRequest {
  final PriceRequest request;
  final DateTime addedAt;

  _CachedPriceRequest({
    required this.request,
    required this.addedAt,
  });
}
