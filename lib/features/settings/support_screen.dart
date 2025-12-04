import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

/// Support Screen
/// Provides contact information and support options
class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final subject = _subjectController.text.trim();
    final body = _messageController.text.trim();
    final email = _emailController.text.trim();

    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Заполните тему и сообщение'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailBody = body + (email.isNotEmpty ? '\n\nEmail для ответа: $email' : '');
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@uitap.kz',
      queryParameters: {
        'subject': subject,
        'body': emailBody,
      },
    );

    try {
      // Пытаемся открыть почтовый клиент
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        // Если не удалось, показываем диалог с копированием
        _showCopyEmailDialog(subject, emailBody);
      }
    } catch (e) {
      // Если произошла ошибка, показываем диалог с копированием
      if (mounted) {
        _showCopyEmailDialog(subject, emailBody);
      }
    }
  }

  void _showCopyEmailDialog(String subject, String body) {
    final fullText = 'Тема: $subject\n\n$body\n\nEmail: support@uitap.kz';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Почтовый клиент не найден',
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
              'Скопируйте текст сообщения и отправьте его на адрес:',
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: SelectableText(
                'support@uitap.kz',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF295CDB),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Текст сообщения:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: SelectableText(
                'Тема: $subject\n\n$body',
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: fullText));
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text('Текст скопирован в буфер обмена'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF295CDB),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy, size: 18.sp, color: Colors.white),
                SizedBox(width: 6.w),
                Text('Скопировать', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callSupport() async {
    final phoneUri = Uri.parse('tel:+77001234567');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw Exception('Не удалось открыть телефонный клиент');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          'Поддержка',
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
            // Contact Information Section
            _buildSectionTitle('Контактная информация'),
            SizedBox(height: 16.h),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'support@uitap.kz',
              onTap: null,
            ),
            SizedBox(height: 12.h),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Телефон',
              subtitle: '+7 (700) 123-45-67',
              onTap: null,
            ),
            SizedBox(height: 12.h),
            _buildContactCard(
              icon: Icons.access_time_outlined,
              title: 'Время работы',
              subtitle: 'Пн-Пт: 9:00 - 18:00',
              onTap: null,
            ),

            SizedBox(height: 32.h),

            // Send Message Section


            SizedBox(height: 32.h),

            // FAQ Section
            _buildSectionTitle('Часто задаваемые вопросы'),
            SizedBox(height: 16.h),
            _buildFAQItem(
              question: 'Как отменить бронирование?',
              answer: 'Вы можете отменить бронирование в разделе "Мои брони". Выберите нужное бронирование и нажмите кнопку "Отменить".',
            ),
            SizedBox(height: 12.h),
            _buildFAQItem(
              question: 'Как изменить данные профиля?',
              answer: 'Перейдите в раздел "Профиль", нажмите на иконку редактирования и внесите необходимые изменения.',
            ),
            SizedBox(height: 12.h),
            _buildFAQItem(
              question: 'Как создать новую заявку на поиск?',
              answer: 'На главном экране заполните форму поиска: выберите даты, количество гостей, тип размещения и нажмите "Найти".',
            ),
            SizedBox(height: 12.h),
            _buildFAQItem(
              question: 'Что делать, если не приходят уведомления?',
              answer: 'Проверьте настройки уведомлений в разделе "Настройки". Убедитесь, что уведомления включены в настройках устройства.',
            ),

            SizedBox(height: 32.h),

            // Additional Info
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xFF295CDB), size: 24.sp),
                      SizedBox(width: 12.w),
                      Text(
                        'Полезная информация',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Мы стараемся отвечать на все обращения в течение 24 часов в рабочие дни. Если ваш вопрос срочный, пожалуйста, позвоните нам по указанному телефону.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                      height: 1.5,
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF295CDB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF295CDB),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF295CDB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: maxLines > 1 ? 16.h : 14.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: const Color(0xFF295CDB), size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 28.w),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

