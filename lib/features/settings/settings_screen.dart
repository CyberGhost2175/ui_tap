import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// SettingsScreen - app settings and preferences
/// Contains: Dark mode, Payment methods, Notifications, Language, Support, About
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Настройки',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        children: [
          // Dark mode toggle
          _buildToggleItem(
            icon: Icons.dark_mode_outlined,
            title: 'Тёмный режим',
            value: _isDarkMode,
            onChanged: (val) {
              setState(() {
                _isDarkMode = val;
              });
              // TODO: Implement theme switching
            },
          ),
          SizedBox(height: 12.h),

          // Divider
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 12.h),

          // Payment methods
          _buildNavigationItem(
            icon: Icons.credit_card_outlined,
            title: 'Способ оплаты',
            onTap: () {
              // TODO: Navigate to payment methods screen
              _showComingSoonDialog('Способы оплаты');
            },
          ),
          SizedBox(height: 12.h),

          // Notifications
          _buildNavigationItem(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            onTap: () {
              // TODO: Navigate to notifications settings
              _showComingSoonDialog('Настройки уведомлений');
            },
          ),
          SizedBox(height: 12.h),

          // Support
          _buildNavigationItem(
            icon: Icons.help_outline,
            title: 'Тех. Поддержка',
            onTap: () {
              // TODO: Navigate to support screen
              _showComingSoonDialog('Техническая поддержка');
            },
          ),
          SizedBox(height: 12.h),

          // Language
          _buildNavigationItem(
            icon: Icons.language,
            title: 'Язык',
            subtitle: 'Русский',
            onTap: () {
              // TODO: Navigate to language selection
              _showLanguageDialog();
            },
          ),
          SizedBox(height: 12.h),

          // Divider
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 12.h),

          // About
          _buildNavigationItem(
            icon: Icons.info_outline,
            title: 'О нас',
            onTap: () {
              // TODO: Navigate to about screen
              _showComingSoonDialog('О приложении');
            },
          ),
          SizedBox(height: 40.h),

          // Logout button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  /// Toggle item (e.g., Dark mode)
  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 22.sp, color: const Color(0xFF295CDB)),
          ),
          SizedBox(width: 12.w),

          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),

          // Switch
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF295CDB),
          ),
        ],
      ),
    );
  }

  /// Navigation item (with arrow)
  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 22.sp, color: const Color(0xFF295CDB)),
            ),
            SizedBox(width: 12.w),

            // Title & Subtitle
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
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              size: 24.sp,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Logout button
  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        _showLogoutDialog();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'Выйти',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
        ),
      ),
    );
  }

  /// Show coming soon dialog
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          feature,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Эта функция скоро будет доступна',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Понятно',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF295CDB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show language selection dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Выберите язык',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Русский', isSelected: true),
            _buildLanguageOption('Қазақ', isSelected: false),
            _buildLanguageOption('English', isSelected: false),
          ],
        ),
      ),
    );
  }

  /// Language option in dialog
  Widget _buildLanguageOption(String language, {required bool isSelected}) {
    return InkWell(
      onTap: () {
        // TODO: Implement language switching
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF295CDB) : Colors.grey.shade400,
              size: 22.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              language,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Выход',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите выйти из аккаунта?',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement logout logic
              Navigator.pop(context);
              // Navigate to login screen
            },
            child: Text(
              'Выйти',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}