import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/services/search_request_api_service.dart';

/// Screen to display search request details
class SearchRequestDetailScreen extends StatefulWidget {
  final int requestId;

  const SearchRequestDetailScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<SearchRequestDetailScreen> createState() => _SearchRequestDetailScreenState();
}

class _SearchRequestDetailScreenState extends State<SearchRequestDetailScreen> {
  final SearchRequestApiService _apiService = SearchRequestApiService();

  SearchRequest? _request;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequest();
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
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrice() async {
    final controller = TextEditingController(
      text: _request?.price.toString() ?? '',
    );

    final newPrice = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить цену'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Новая цена (KZT)',
            hintText: 'Введите цену',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = int.tryParse(controller.text);
              Navigator.pop(context, price);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newPrice != null && newPrice > 0) {
      try {
        final updated = await _apiService.updatePrice(widget.requestId, newPrice);
        setState(() => _request = updated);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Цена успешно обновлена'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку?'),
        content: const Text('Вы уверены, что хотите отменить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.cancelSearchRequest(widget.requestId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка успешно отменена'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload request
        _loadRequest();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Заявка #${widget.requestId}'),
        backgroundColor: const Color(0xFF2853AF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequest,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
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
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2853AF),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final request = _request!;
    final dateFormat = DateFormat('d MMMM yyyy', 'ru');

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(request),
          SizedBox(height: 16.h),

          // Main Info Card
          _buildInfoCard(
            title: 'Основная информация',
            children: [
              _buildInfoRow('Заезд', dateFormat.format(DateTime.parse(request.checkInDate))),
              _buildInfoRow('Выезд', dateFormat.format(DateTime.parse(request.checkOutDate))),
              _buildInfoRow('Цена', '${request.price} KZT'),
              _buildInfoRow('Гостей', '${request.countOfPeople} чел.'),
              _buildInfoRow('Тип жилья', request.unitTypesText),
              if (request.fromRating != null || request.toRating != null)
                _buildInfoRow(
                  'Рейтинг',
                  '${request.fromRating ?? 0} - ${request.toRating ?? 5} ⭐',
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Districts Card
          if (request.districts.isNotEmpty)
            _buildInfoCard(
              title: 'Районы',
              children: request.districts
                  .map((d) => _buildChip(d.name))
                  .toList(),
            ),
          SizedBox(height: 16.h),

          // Services Card
          if (request.services.isNotEmpty)
            _buildInfoCard(
              title: 'Дополнительные услуги',
              children: request.services
                  .map((s) => _buildChip(s.value, color: Colors.blue))
                  .toList(),
            ),
          SizedBox(height: 16.h),

          // Conditions Card
          if (request.conditions.isNotEmpty)
            _buildInfoCard(
              title: 'Условия проживания',
              children: request.conditions
                  .map((c) => _buildChip(c.value, color: Colors.green))
                  .toList(),
            ),
          SizedBox(height: 16.h),

          // Author Info
          _buildInfoCard(
            title: 'Автор заявки',
            children: [
              _buildInfoRow('Имя', request.authorName),
              _buildInfoRow('ID', '#${request.authorId}'),
              _buildInfoRow(
                'Создано',
                DateFormat('d MMMM yyyy, HH:mm', 'ru')
                    .format(DateTime.parse(request.createdAt)),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Action Buttons
          if (request.status == 'OPEN_TO_PRICE_REQUEST') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updatePrice,
                icon: const Icon(Icons.edit),
                label: const Text('Изменить цену'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2853AF),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelRequest,
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text('Отменить заявку'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SearchRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статус',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  request.statusText,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {Color? color}) {
    return Container(
      margin: EdgeInsets.only(right: 8.w, bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF2853AF)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color ?? const Color(0xFF2853AF),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color ?? const Color(0xFF2853AF),
        ),
      ),
    );
  }
}