import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../data/services/search_request_api_service.dart';
import '../../data/services/price_request_api_service.dart'; // ⬅️ ДОБАВЛЕНО
import 'price_requests_screen.dart';

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
  final PriceRequestApiService _priceApiService = PriceRequestApiService(); // ⬅️ ДОБАВЛЕНО

  SearchRequest? _request;
  bool _isLoading = true;
  String? _error;
  int _previousWaitingCount = 0; // ⬅️ ДОБАВЛЕНО: Счетчик предложений

  @override
  void initState() {
    super.initState();
    _loadRequest(showToastForNewOffers: false); // ⬅️ ИЗМЕНЕНО: без тостера при первой загрузке
  }

  /// Загрузка заявки с сервера
  Future<void> _loadRequest({bool showToastForNewOffers = true}) async { // ⬅️ ИЗМЕНЕНО: параметр добавлен
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = await _apiService.getSearchRequestById(widget.requestId);

      // ⬅️ ДОБАВЛЕНО: Проверяем количество новых предложений
      if (showToastForNewOffers && _request != null) {
        await _checkForNewOffers();
      }

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

  /// ⬅️ НОВОЕ: Проверка новых предложений и показ тостера
  Future<void> _checkForNewOffers() async {
    try {
      final priceRequests = await _priceApiService.getPriceRequestsBySearchRequest(
        widget.requestId,
      );

      // Считаем предложения со статусом WAITING
      final waitingCount = priceRequests
          .where((pr) => pr.clientResponseStatus == 'WAITING')
          .length;

      // Если появились новые предложения - показываем тостер
      if (waitingCount > _previousWaitingCount) {
        final newOffersCount = waitingCount - _previousWaitingCount;

        if (!mounted) return;

        // ⬅️ ПРОСТОЙ ОРАНЖЕВЫЙ ТОСТЕР (как на скриншоте)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                // Иконка часов
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
                // Текст
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ожидает ответа',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        newOffersCount == 1
                            ? 'Получено предложение от менеджера'
                            : 'Получено $newOffersCount предложений',
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
            margin: EdgeInsets.only(
              bottom: 80,
              left: 16,
              right: 16,
            ),
          ),
        );
      }

      _previousWaitingCount = waitingCount;
    } catch (e) {
      print('❌ [CHECK OFFERS] Error: $e');
    }
  }

  /// 💰 Изменение цены
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
            Text(
              'Изменить цену',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Текущая цена: ${_request!.price} тг/ночь',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Новая цена',
                labelStyle: TextStyle(
                  color: const Color(0xFF295CDB),
                  fontWeight: FontWeight.w500,
                ),
                suffixText: 'тг/ночь',
                suffixStyle: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: const Color(0xFF295CDB), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                ),
              ),
              autofocus: true,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18.sp,
                    color: const Color(0xFF295CDB),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Можно изменить только цену. Другие параметры изменить нельзя.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF295CDB),
                        fontWeight: FontWeight.w500,
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
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final price = int.tryParse(priceController.text);
              if (price != null && price > 0) {
                Navigator.pop(context, price);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите корректную цену'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF295CDB),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Сохранить',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (newPrice == null || newPrice == _request!.price) return;

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
                'Обновляем цену...',
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
      await _apiService.updateSearchRequestPrice(widget.requestId, newPrice);

      if (!mounted) return;

      // Закрываем loader
      Navigator.pop(context);

      // Показываем success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Цена обновлена: $newPrice тг/ночь'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Перезагружаем заявку
      await _loadRequest();
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

          // Action buttons
          _buildActionButtons(),
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

  /// 🔘 Action buttons (Update Price + Cancel + View Offers)
  Widget _buildActionButtons() {
    final canModify = _request!.status == 'OPEN_TO_PRICE_REQUEST';

    if (!canModify) return const SizedBox.shrink();

    return Column(
      children: [
        // View Price Requests button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              // Navigate to Price Requests screen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PriceRequestsScreen(
                    searchRequest: _request!,
                  ),
                ),
              );
              // ⬅️ ИЗМЕНЕНО: Reload с проверкой новых предложений
              _loadRequest(showToastForNewOffers: true);
            },
            icon: Icon(Icons.local_offer, size: 20.sp, color: Colors.white),
            label: Text(
              'Посмотреть предложения',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // Update Price button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _updatePrice,
            icon: Icon(Icons.edit, size: 20.sp, color: Colors.white),
            label: Text(
              'Изменить цену',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF295CDB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _cancelRequest,
            icon: Icon(Icons.cancel, size: 20.sp, color: Colors.white),
            label: Text(
              'Отменить заявку',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
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