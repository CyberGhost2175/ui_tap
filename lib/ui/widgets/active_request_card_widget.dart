import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/search/search_request_models.dart';
import '../../features/search/active_search_request_screen.dart';

/// 📋 Компактная карточка активной заявки для горизонтального скролла
///
/// Отображает активную заявку пользователя
/// Оптимизирована для показа в списке
class ActiveRequestCardWidget extends StatelessWidget {
  final SearchRequest request;
  final VoidCallback? onRefresh;

  const ActiveRequestCardWidget({
    Key? key,
    required this.request,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checkInDate = DateFormat('dd MMM', 'ru').format(
      DateTime.parse(request.checkInDate),
    );
    final checkOutDate = DateFormat('dd MMM', 'ru').format(
      DateTime.parse(request.checkOutDate),
    );

    // Определяем цвет статуса
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

    return GestureDetector(
      onTap: () {
        // Переход на экран заявки
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveSearchRequestScreen(
              requestId: request.id,
            ),
          ),
        ).then((_) {
          // После возврата обновляем данные
          if (onRefresh != null) {
            onRefresh!();
          }
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
                  '#${request.id}',
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
                  '${request.countOfPeople} чел',
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
                    request.unitTypesText,
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
                  '${request.price} тг/ночь',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h), // ⬅️ Уменьшил с 10 до 8

            // Districts
            if (request.districts.isNotEmpty) ...[
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: request.districts.take(3).map((district) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      district.name,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 6.h), // ⬅️ Уменьшил с 8 до 6
            ],

            // Footer hint
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 12.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Нажмите для деталей',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}