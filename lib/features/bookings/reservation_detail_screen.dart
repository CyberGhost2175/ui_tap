import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/reservations/reservation_models.dart';
import '../../data/services/reservation_api_service.dart';

/// Reservation Detail Screen
/// Shows full reservation information and allows cancellation
class ReservationDetailScreen extends StatefulWidget {
  final int reservationId;

  const ReservationDetailScreen({
    Key? key,
    required this.reservationId,
  }) : super(key: key);

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final ReservationApiService _apiService = ReservationApiService();
  
  Reservation? _reservation;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservation = await _apiService.getReservationById(widget.reservationId);
      setState(() {
        _reservation = reservation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      print('❌ [RESERVATION DETAIL] Error: $e');
    }
  }

  Future<void> _cancelReservation() async {
    // Проверяем, можно ли отменить
    if (_reservation == null) return;

    final canCancel = _reservation!.status == 'WAITING_TO_APPROVE' || 
                      _reservation!.status == 'APPROVED';

    if (!canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Невозможно отменить бронирование с текущим статусом'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Проверяем дату заезда (минимум 1 день до заезда)
    final now = DateTime.now();
    final checkIn = _reservation!.checkInDate;
    final daysUntilCheckIn = checkIn.difference(now).inDays;

    if (daysUntilCheckIn < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Отмена невозможна - менее 1 дня до заезда'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Показываем диалог подтверждения
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Отменить бронирование?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
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
              'Вы уверены, что хотите отменить это бронирование?',
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Отмена возможна минимум за 1 день до заезда',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Отменить бронирование'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await _apiService.cancelReservation(widget.reservationId);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('Бронирование успешно отменено'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Обновляем данные
      await _loadReservation();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Детали бронирования',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: const Color(0xFF295CDB)))
          : _error != null
          ? _buildErrorState()
          : _reservation == null
          ? Center(child: Text('Бронирование не найдено'))
          : SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус
            _buildStatusCard(),
            SizedBox(height: 20.h),

            // Основная информация
            _buildMainInfoCard(),
            SizedBox(height: 20.h),

            // Информация о размещении
            _buildAccommodationCard(),
            SizedBox(height: 20.h),

            // Детали оплаты
            _buildPaymentCard(),
            SizedBox(height: 20.h),

            // Кнопка отмены (показываем для активных бронирований)
            if (_isActiveReservation()) _buildCancelButton(),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

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
              onPressed: _loadReservation,
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

  Widget _buildStatusCard() {
    final statusInfo = _getStatusInfo(_reservation!.status);
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: statusInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: statusInfo['color'],
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusInfo['icon'],
            color: statusInfo['color'],
            size: 32.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статус бронирования',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  statusInfo['text'],
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: statusInfo['color'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard() {
    final checkIn = DateFormat('dd MMM yyyy', 'ru').format(_reservation!.checkInDate);
    final checkOut = DateFormat('dd MMM yyyy', 'ru').format(_reservation!.checkOutDate);
    final nights = _reservation!.checkOutDate.difference(_reservation!.checkInDate).inDays;
    final createdAt = DateFormat('dd MMM yyyy, HH:mm', 'ru').format(_reservation!.createdAt);
    final updatedAt = DateFormat('dd MMM yyyy, HH:mm', 'ru').format(_reservation!.updatedAt);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          Text(
            'Основная информация',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.calendar_today, 'Дата заезда', checkIn),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.calendar_today_outlined, 'Дата выезда', checkOut),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.hotel, 'Количество ночей', '$nights ${_nightsText(nights)}'),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.people, 'Количество гостей', '${_reservation!.guestCount} чел'),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey.shade300),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.access_time, 'Создано', createdAt),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.update, 'Обновлено', updatedAt),
        ],
      ),
    );
  }

  Widget _buildAccommodationCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          Text(
            'Информация о размещении',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.hotel, 'Отель', _reservation!.accommodationName),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.bed, 'Номер', _reservation!.accommodationUnitName),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.person, 'Клиент', _reservation!.clientName),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          Text(
            'Детали оплаты',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Цена за ночь',
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
              Text(
                '${_reservation!.price} тг',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Нужна оплата',
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
              Text(
                _reservation!.needToPay ? 'Да' : 'Нет',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: _reservation!.needToPay ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_reservation!.price} тг',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF295CDB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    final canCancel = _canCancel();
    final cancelReason = _getCancelReason();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: (_isCancelling || !canCancel) ? null : _cancelReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: canCancel ? Colors.red : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: _isCancelling
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Отменить бронирование',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (!canCancel && cancelReason != null) ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    cancelReason,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
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
      case 'CANCELED':
        return {
          'text': 'Отменено',
          'color': Colors.grey,
          'icon': Icons.block,
        };
      default:
        return {
          'text': status,
          'color': Colors.grey,
          'icon': Icons.info,
        };
    }
  }

  bool _isActiveReservation() {
    if (_reservation == null) return false;
    // Показываем кнопку для активных бронирований
    return _reservation!.status == 'WAITING_TO_APPROVE' || 
           _reservation!.status == 'APPROVED';
  }

  bool _canCancel() {
    if (_reservation == null) return false;
    
    // Можно отменить только в статусах WAITING_TO_APPROVE или APPROVED
    final canCancelStatus = _reservation!.status == 'WAITING_TO_APPROVE' || 
                            _reservation!.status == 'APPROVED';
    
    if (!canCancelStatus) return false;

    // Проверяем дату заезда (минимум 1 день до заезда)
    final now = DateTime.now();
    final checkIn = _reservation!.checkInDate;
    final daysUntilCheckIn = checkIn.difference(now).inDays;

    return daysUntilCheckIn >= 1;
  }

  String? _getCancelReason() {
    if (_reservation == null) return null;
    
    // Проверяем статус
    final canCancelStatus = _reservation!.status == 'WAITING_TO_APPROVE' || 
                            _reservation!.status == 'APPROVED';
    
    if (!canCancelStatus) {
      return 'Невозможно отменить бронирование с текущим статусом';
    }

    // Проверяем дату заезда
    final now = DateTime.now();
    final checkIn = _reservation!.checkInDate;
    final daysUntilCheckIn = checkIn.difference(now).inDays;

    if (daysUntilCheckIn < 1) {
      return 'Отмена невозможна - менее 1 дня до заезда';
    }

    return null; // Можно отменить
  }

  String _nightsText(int nights) {
    if (nights == 1) return 'ночь';
    if (nights >= 2 && nights <= 4) return 'ночи';
    return 'ночей';
  }
}

