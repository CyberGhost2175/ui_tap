import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/price_request_models.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/services/price_request_api_service.dart';

/// Экран показывающий предложения цен от менеджеров
class PriceRequestsScreen extends StatefulWidget {
  final SearchRequest searchRequest;

  const PriceRequestsScreen({
    Key? key,
    required this.searchRequest,
  }) : super(key: key);

  @override
  State<PriceRequestsScreen> createState() => _PriceRequestsScreenState();
}

class _PriceRequestsScreenState extends State<PriceRequestsScreen> {
  final PriceRequestApiService _apiService = PriceRequestApiService();

  List<PriceRequest> _priceRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPriceRequests();
  }

  /// Загрузка предложений цен
  Future<void> _loadPriceRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _apiService.getPriceRequestsBySearchRequest(
        widget.searchRequest.id,
      );

      setState(() {
        _priceRequests = requests;
        _isLoading = false;
      });

      print('✅ [PRICE REQUESTS] Loaded ${requests.length} requests');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      print('❌ [PRICE REQUESTS] Error: $e');
    }
  }

  /// Принять предложение
  Future<void> _acceptPriceRequest(PriceRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 24.sp,
            ),
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
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Номер: ${request.accommodationUnitName}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
              ),
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
                  Icon(
                    Icons.attach_money,
                    color: Colors.green,
                    size: 20.sp,
                  ),
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
              'После принятия будет создана заявка на бронирование.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Принять',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16.h),
              Text(
                'Принимаем предложение...',
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
      await _apiService.acceptPriceRequest(request.id);

      if (!mounted) return;

      // Закрываем loader
      Navigator.pop(context);

      // Показываем success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Предложение принято! Создана заявка на бронирование.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Перезагружаем список
      await _loadPriceRequests();
    } catch (e) {
      if (!mounted) return;

      // Закрываем loader
      Navigator.pop(context);

      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Отклонить предложение
  Future<void> _rejectPriceRequest(PriceRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Colors.red,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Отклонить предложение?',
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
          'Вы уверены, что хотите отклонить это предложение?',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Отклонить',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'Отклоняем предложение...',
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
      await _apiService.rejectPriceRequest(request.id);

      if (!mounted) return;

      // Закрываем loader
      Navigator.pop(context);

      // Показываем success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Предложение отклонено'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Перезагружаем список
      await _loadPriceRequests();
    } catch (e) {
      if (!mounted) return;

      // Закрываем loader
      Navigator.pop(context);

      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Предложения от менеджеров',
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
                onPressed: _loadPriceRequests,
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

    if (_priceRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16.h),
              Text(
                'Пока нет предложений',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Менеджеры еще не откликнулись на вашу заявку',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPriceRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _priceRequests.length,
        itemBuilder: (context, index) {
          final request = _priceRequests[index];
          return _buildPriceRequestCard(request);
        },
      ),
    );
  }

  /// Карточка предложения цены
  Widget _buildPriceRequestCard(PriceRequest request) {
    final statusColor = _getStatusColor(request.clientResponseStatus);
    final canRespond = request.canRespond;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
          // Header with status
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(request.clientResponseStatus),
                  color: statusColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  request.statusText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM, HH:mm', 'ru').format(request.createdAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accommodation name
                Text(
                  request.accommodationName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),

                // Unit name
                Text(
                  request.accommodationUnitName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),

                SizedBox(height: 12.h),

                // Price
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF295CDB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: const Color(0xFF295CDB),
                        size: 20.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${request.price} тг/ночь',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF295CDB),
                        ),
                      ),
                    ],
                  ),
                ),

                // Buttons (только если можно ответить)
                if (canRespond) ...[
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Отклонить',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Принять',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Получить цвет статуса
  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'WAITING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Получить иконку статуса
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'WAITING':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}