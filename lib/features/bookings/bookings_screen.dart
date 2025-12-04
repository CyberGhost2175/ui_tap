import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/reservations/reservation_models.dart';
import '../../data/services/reservation_api_service.dart';
import '../../data/services/notification_service.dart';
import 'reservation_detail_screen.dart';

/// BookingsScreen - displays active and history bookings
/// ⬅️ FIXED: Overflow + status filtering + Russian status names
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReservationApiService _apiService = ReservationApiService();

  List<Reservation> _allReservations = [];
  List<Reservation> _activeBookings = [];
  List<Reservation> _historyBookings = [];
  
  // Для отслеживания изменений статуса
  Map<int, String> _previousStatuses = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ⬅️ FIXED: Фильтрация по статусам
  /// Активные: APPROVED
  /// История: REJECTED, FINISHED_SUCCESSFUL
  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservations = await _apiService.getMyReservations();

      // Активные: APPROVED + WAITING_TO_APPROVE
      final active = reservations.where((r) =>
          r.status == 'APPROVED' ||
          r.status == 'WAITING_TO_APPROVE').toList();

      // История: REJECTED + FINISHED_SUCCESSFUL (+ прочие завершённые статусы)
      final history = reservations.where((r) =>
          r.status == 'REJECTED' ||
          r.status == 'FINISHED_SUCCESSFUL' ||
          r.status == 'CLIENT_DIDNT_CAME' ||
          r.status == 'CANCELED').toList();

      // Проверяем изменения статуса и показываем уведомления
      for (var reservation in reservations) {
        final previousStatus = _previousStatuses[reservation.id];
        if (previousStatus != null && previousStatus != reservation.status) {
          // Статус изменился - показываем уведомление
          final statusInfo = _getStatusInfo(reservation.status);
          await NotificationService().showReservationStatusNotification(
            reservationId: reservation.id,
            statusText: statusInfo['text'],
            accommodationName: reservation.accommodationName,
          );
          print('📬 [BOOKINGS] Status changed for reservation ${reservation.id}: $previousStatus -> ${reservation.status}');
        }
        _previousStatuses[reservation.id] = reservation.status;
      }

      setState(() {
        _allReservations = reservations;
        _activeBookings = active;
        _historyBookings = history;
        _isLoading = false;
      });

      print('✅ [BOOKINGS] Loaded ${reservations.length} reservations');
      print('   Active (APPROVED + WAITING_TO_APPROVE): ${active.length}');
      print('   History (REJECTED + FINISHED_SUCCESSFUL + OTHER_FINISHED): ${history.length}');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      print('❌ [BOOKINGS] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Мои брони',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: const Color(0xFF295CDB)))
          : _error != null
          ? _buildErrorState()
          : Column(
        children: [
          _buildTabSelector(),
          SizedBox(height: 16.h),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_activeBookings, isActive: true),
                _buildBookingsList(_historyBookings, isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadReservations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF295CDB),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab selector widget (Активные / История)
  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF1A1A1A),
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Активные'),
          Tab(text: 'История'),
        ],
      ),
    );
  }

  /// Bookings list or empty state
  Widget _buildBookingsList(List<Reservation> bookings, {required bool isActive}) {
    if (bookings.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  /// ⬅️ FIXED: Карточка бронирования (overflow fix)
  Widget _buildBookingCard(Reservation reservation) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationDetailScreen(
              reservationId: reservation.id,
            ),
          ),
        ).then((_) {
          // Обновляем список после возврата
          _loadReservations();
        });
      },
      child: _buildBookingCardContent(reservation),
    );
  }

  Widget _buildBookingCardContent(Reservation reservation) {
    final checkIn = DateFormat('dd MMM yyyy', 'ru').format(reservation.checkInDate);
    final checkOut = DateFormat('dd MMM yyyy', 'ru').format(reservation.checkOutDate);
    final nights = reservation.checkOutDate.difference(reservation.checkInDate).inDays;

    // ⬅️ FIXED: Статусы на русском
    final statusInfo = _getStatusInfo(reservation.status);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header с фото и основной инфо
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder изображение
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.hotel,
                    size: 40.sp,
                    color: const Color(0xFF295CDB),
                  ),
                ),
                SizedBox(width: 12.w),

                // ⬅️ FIXED: Expanded для предотвращения overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название отеля
                      Text(
                        reservation.accommodationName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),

                      // Адрес
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14.sp, color: Colors.grey.shade600),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              'Астана, Казахстан',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Цена
                      Text(
                        '${reservation.price} тг /ночь',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF295CDB),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Рейтинг
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        '5.0',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // ⬅️ FIXED: Статус на русском + цвета
          Container(
            padding: EdgeInsets.all(16.w),
            color: statusInfo['color'].withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  statusInfo['icon'],
                  color: statusInfo['color'],
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  statusInfo['text'],
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: statusInfo['color'],
                  ),
                ),
              ],
            ),
          ),

          // Детали
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Детали',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF295CDB),
                  ),
                ),
                SizedBox(height: 12.h),

                _buildDetailRow(
                  Icons.calendar_today,
                  'Даты',
                  '$checkIn - $checkOut',
                ),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.only(left: 26.w),
                  child: Text(
                    '$nights ${_nightsText(nights)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                _buildDetailRow(
                  Icons.people,
                  'Гостей',
                  '${reservation.guestCount}',
                ),
                SizedBox(height: 8.h),

                _buildDetailRow(
                  Icons.hotel,
                  'Номер',
                  reservation.accommodationUnitName,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Детали оплаты
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Детали оплаты',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF295CDB),
                  ),
                ),
                SizedBox(height: 12.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Цена', style: TextStyle(fontSize: 14.sp, color: Colors.black87)),
                    Text('${reservation.price} тг', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8.h),

                Divider(color: Colors.grey.shade300),
                SizedBox(height: 8.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Итого',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${reservation.price} тг',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF295CDB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Построить маршрут

        ],
      ),
    );
  }

  /// ⬅️ NEW: Получение информации о статусе (русский текст + цвет + иконка)
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'WAITING_TO_APPROVE':
        return {
          'text': 'Ожидает подтверждения',
          'color': Colors.orange,
          'icon': Icons.access_time,
        };
      case 'APPROVED':
        return {
          'text': 'Подтверждено',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'REJECTED':
        return {
          'text': 'Отклонено',
          'color': Colors.red,
          'icon': Icons.cancel,
        };
      case 'FINISHED_SUCCESSFUL':
        return {
          'text': 'Завершено успешно',
          'color': Colors.blue,
          'icon': Icons.task_alt,
        };
      case 'PENDING':
        return {
          'text': 'Ожидает подтверждения',
          'color': Colors.orange,
          'icon': Icons.schedule,
        };
      default:
        return {
          'text': status,
          'color': Colors.grey,
          'icon': Icons.info,
        };
    }
  }

  /// ⬅️ FIXED: Detail row без overflow
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.grey.shade600),
        SizedBox(width: 8.w),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper для текста ночей
  String _nightsText(int nights) {
    if (nights == 1) return 'ночь';
    if (nights >= 2 && nights <= 4) return 'ночи';
    return 'ночей';
  }

  /// Open 2GIS
  Future<void> _open2GIS() async {
    final url = Uri.parse('dgis://2gis.ru/routeSearch/rsType/car/to/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть 2GIS')),
        );
      }
    }
  }

  /// Open Yandex GO
  Future<void> _openYandexGO() async {
    final url = Uri.parse('yandexnavi://');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть Yandex GO')),
        );
      }
    }
  }

  /// Empty state widget
  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 56.sp,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Брони отсутствуют',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              isActive
                  ? 'У вас пока нет активных бронирований.\nНачните поиск жилья!'
                  : 'История бронирований пуста.\nСовершите первое бронирование!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}