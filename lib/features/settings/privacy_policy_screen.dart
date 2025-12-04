import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Privacy Policy Screen
/// Displays the privacy policy of the application
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

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
          'Политика конфиденциальности',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Общие положения'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Настоящая Политика конфиденциальности определяет порядок обработки и защиты персональных данных пользователей мобильного приложения UI Tap (далее — «Приложение»).',
            ),
            SizedBox(height: 8.h),
            _buildParagraph(
              'Используя Приложение, вы соглашаетесь с условиями настоящей Политики конфиденциальности.',
            ),

            SizedBox(height: 24.h),
            _buildSectionTitle('2. Собираемые данные'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'При использовании Приложения мы можем собирать следующую информацию:',
            ),
            SizedBox(height: 8.h),
            _buildBulletPoint('Имя и фамилия'),
            _buildBulletPoint('Адрес электронной почты'),
            _buildBulletPoint('Номер телефона'),
            _buildBulletPoint('Данные о бронированиях'),
            _buildBulletPoint('Информация о местоположении (при использовании карты)'),
            _buildBulletPoint('Технические данные устройства'),

            SizedBox(height: 24.h),
            _buildSectionTitle('3. Цели использования данных'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Собранные данные используются для следующих целей:',
            ),
            SizedBox(height: 8.h),
            _buildBulletPoint('Предоставление услуг бронирования жилья'),
            _buildBulletPoint('Обработка заявок и запросов пользователей'),
            _buildBulletPoint('Улучшение качества сервиса'),
            _buildBulletPoint('Отправка уведомлений о статусе бронирований'),
            _buildBulletPoint('Связь с пользователями по вопросам обслуживания'),

            SizedBox(height: 24.h),
            _buildSectionTitle('4. Защита данных'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Мы применяем современные технологии защиты данных, включая шифрование и безопасное хранение информации. Доступ к персональным данным имеют только уполномоченные сотрудники, необходимые для предоставления услуг.',
            ),

            SizedBox(height: 24.h),
            _buildSectionTitle('5. Передача данных третьим лицам'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Мы не передаем ваши персональные данные третьим лицам, за исключением случаев, когда это необходимо для предоставления услуг бронирования (например, передача данных менеджерам по размещению) или требуется по законодательству.',
            ),

            SizedBox(height: 24.h),
            _buildSectionTitle('6. Права пользователей'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Вы имеете право:',
            ),
            SizedBox(height: 8.h),
            _buildBulletPoint('Получать информацию о ваших персональных данных'),
            _buildBulletPoint('Требовать исправления неточных данных'),
            _buildBulletPoint('Требовать удаления ваших данных'),
            _buildBulletPoint('Отозвать согласие на обработку данных'),

            SizedBox(height: 24.h),
            _buildSectionTitle('7. Cookies и аналогичные технологии'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Приложение может использовать cookies и аналогичные технологии для улучшения работы сервиса и персонализации опыта использования.',
            ),

            SizedBox(height: 24.h),
            _buildSectionTitle('8. Изменения в Политике'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Мы оставляем за собой право вносить изменения в настоящую Политику конфиденциальности. О существенных изменениях мы уведомим пользователей через Приложение или по электронной почте.',
            ),

            SizedBox(height: 24.h),
            _buildSectionTitle('9. Контакты'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'По всем вопросам, связанным с обработкой персональных данных, вы можете обращаться по адресу электронной почты: support@uitap.kz',
            ),

            SizedBox(height: 24.h),
            _buildSectionTitle('10. Дата вступления в силу'),
            SizedBox(height: 12.h),
            _buildParagraph(
              'Настоящая Политика конфиденциальности вступает в силу с момента установки Приложения и действует до момента ее отзыва пользователем или изменения администрацией.',
            ),

            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF295CDB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF295CDB), size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Последнее обновление: ${DateTime.now().year}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF295CDB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        color: Colors.black87,
        height: 1.6,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

