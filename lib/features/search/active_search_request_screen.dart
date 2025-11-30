import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/services/search_request_api_service.dart';

/// Screen показывающий активную заявку на поиск жилья
/// Отображается после успешного создания заявки
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

  SearchRequest? _request;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  /// Загрузка заявки с сервера
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
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Отмена заявки
  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку?'),
        content: const Text('Вы уверены, что хотите отменить эту заявку на поиск жилья?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
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
      await _apiService.cancelSearchRequest(widget.requestId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заявка успешно отменена'),
          backgroundColor: Colors.green,
        ),
      );

      // Возвращаемся на главную
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Заявка на поиск',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF295CDB),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: Colors.red,
              ),
              SizedBox(height: 16.h),
              Text(
                'Ошибка загрузки заявки',
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
                onPressed: _loadRequest,
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

    if (_request == null) {
      return Center(child: Text('Заявка не найдена'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success message
          _buildSuccessCard(),
          SizedBox(height: 20.h),

          // Status
          _buildStatusCard(),
          SizedBox(height: 20.h),

          // Main info
          _buildMainInfoCard(),
          SizedBox(height: 20.h),

          // Districts
          if (_request!.districts.isNotEmpty) ...[
            _buildDistrictsCard(),
            SizedBox(height: 20.h),
          ],

          // Services
          if (_request!.services.isNotEmpty) ...[
            _buildServicesCard(),
            SizedBox(height: 20.h),
          ],

          // Conditions
          if (_request!.conditions.isNotEmpty) ...[
            _buildConditionsCard(),
            SizedBox(height: 20.h),
          ],

          // Cancel button
          _buildCancelButton(),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  /// Success card
  Widget _buildSuccessCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF295CDB),
            const Color(0xFF1E46A3),
          ],
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
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 32.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заявка успешно создана!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Ожидайте предложений от менеджеров',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status card
  Widget _buildStatusCard() {
    final status = _request!.statusText;
    final isOpen = _request!.status == 'OPEN_TO_PRICE_REQUEST';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isOpen ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.cancel,
            color: isOpen ? Colors.green : Colors.grey,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статус заявки',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isOpen ? Colors.green : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Main info card
  Widget _buildMainInfoCard() {
    final checkIn = DateFormat('dd MMM yyyy', 'ru').format(
      DateTime.parse(_request!.checkInDate),
    );
    final checkOut = DateFormat('dd MMM yyyy', 'ru').format(
      DateTime.parse(_request!.checkOutDate),
    );

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
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),

          _buildInfoRow(Icons.calendar_today, 'Заезд', checkIn),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.calendar_today_outlined, 'Выезд', checkOut),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.people, 'Гостей', '${_request!.countOfPeople} чел'),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.attach_money, 'Бюджет', '${_request!.price} тг/ночь'),

          if (_request!.fromRating != null || _request!.toRating != null) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              Icons.star,
              'Рейтинг',
              '${_request!.fromRating ?? 0} - ${_request!.toRating ?? 5}',
            ),
          ],

          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.home,
            'Тип жилья',
            _request!.unitTypesText,
          ),

          if (_request!.oneNight) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF295CDB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Одна ночь',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF295CDB),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Districts card
  Widget _buildDistrictsCard() {
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
          Row(
            children: [
              Icon(Icons.location_on, color: const Color(0xFF295CDB), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Районы',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _request!.districts.map((district) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF295CDB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFF295CDB).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  district.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF295CDB),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Services card
  Widget _buildServicesCard() {
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
          Row(
            children: [
              Icon(Icons.room_service, color: const Color(0xFF295CDB), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Услуги',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ..._request!.services.map((service) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    service.value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Conditions card
  Widget _buildConditionsCard() {
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
          Row(
            children: [
              Icon(Icons.info_outline, color: const Color(0xFF295CDB), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Условия проживания',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ..._request!.conditions.map((condition) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    condition.value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Cancel button
  Widget _buildCancelButton() {
    final canCancel = _request!.status == 'OPEN_TO_PRICE_REQUEST';

    if (!canCancel) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _cancelRequest,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          side: const BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Отменить заявку',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  /// Info row widget
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}