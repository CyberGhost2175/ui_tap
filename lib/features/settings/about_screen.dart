import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

/// AboutScreen - information about the application
/// Contains: App description, version, contacts, social media, privacy policy
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF1A1A1A),
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'О нас',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            _buildAppLogo(),
            SizedBox(height: 24.h),

            // App Name & Version
            Text(
              'Ui Tap',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Версия 1.0.0',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 32.h),

            // Description
            _buildDescription(),
            SizedBox(height: 32.h),

            // Features
            _buildFeaturesList(),
            SizedBox(height: 32.h),

            // Contact Information
            _buildContactSection(),
            SizedBox(height: 32.h),


            // Legal Links
            _buildLegalSection(),
            SizedBox(height: 20.h),

            // Copyright
            _buildCopyright(),
          ],
        ),
      ),
    );
  }

  /// App logo container
  Widget _buildAppLogo() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: const Color(0xFF295CDB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Icon(
        Icons.home_work_outlined,
        size: 64.sp,
        color: const Color(0xFF295CDB),
      ),
    );
  }

  /// App description text
  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        'Ui Tap — это современная платформа для поиска и бронирования жилья. '
            'Мы делаем процесс поиска идеального места для проживания простым, '
            'удобным и безопасным.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15.sp,
          height: 1.6,
          color: const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Features list
  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.search,
        'title': 'Удобный поиск',
        'description': 'Быстрый поиск жилья по вашим критериям',
      },
      {
        'icon': Icons.map_outlined,
        'title': 'Интерактивная карта',
        'description': 'Просмотр доступных вариантов на карте',
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Уведомления',
        'description': 'Оповещения о новых предложениях',
      },
      {
        'icon': Icons.verified_user_outlined,
        'title': 'Безопасность',
        'description': 'Проверенные хозяева и объекты',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 16.h),
          child: Text(
            'Наши возможности',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        ...features.map((feature) => _buildFeatureItem(
          icon: feature['icon'] as IconData,
          title: feature['title'] as String,
          description: feature['description'] as String,
        )),
      ],
    );
  }

  /// Single feature item
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: const Color(0xFF295CDB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 24.sp,
              color: const Color(0xFF295CDB),
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
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contact information section
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 16.h),
          child: Text(
            'Контакты',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        _buildContactItem(
          icon: Icons.email_outlined,
          title: 'Email',
          value: 'support@uitap.com',
          onTap: () => _launchEmail('support@uitap.com'),
        ),
        SizedBox(height: 12.h),
        _buildContactItem(
          icon: Icons.phone_outlined,
          title: 'Телефон',
          value: '+7 (777) 123-45-67',
          onTap: () => _launchPhone('+77771234567'),
        ),
        SizedBox(height: 12.h),
        _buildContactItem(
          icon: Icons.language,
          title: 'Веб-сайт',
          value: 'www.uitap.com',
          onTap: () => _launchURL('https://www.uitap.com'),
        ),
      ],
    );
  }

  /// Single contact item
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 20.sp, color: const Color(0xFF295CDB)),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Social media links


  /// Social media button
  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: BoxDecoration(
          color: const Color(0xFF295CDB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          size: 28.sp,
          color: const Color(0xFF295CDB),
        ),
      ),
    );
  }

  /// Legal section (Privacy Policy, Terms)
  Widget _buildLegalSection() {
    return Column(
      children: [
        _buildLegalLink(
          title: 'Политика конфиденциальности',
          onTap: () => _launchURL('https://www.uitap.com/privacy'),
        ),
        SizedBox(height: 12.h),
        _buildLegalLink(
          title: 'Условия использования',
          onTap: () => _launchURL('https://www.uitap.com/terms'),
        ),
      ],
    );
  }

  /// Legal link item
  Widget _buildLegalLink({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF295CDB),
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Copyright text
  Widget _buildCopyright() {
    return Text(
      '© 2025 Ui Tap. Все права защищены.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.sp,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // URL launcher methods

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Поддержка Ui Tap',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}