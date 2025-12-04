import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/settings/app_settings.dart';
import '../../data/services/settings_storage.dart';
import 'privacy_policy_screen.dart';
import 'support_screen.dart';

/// Settings Screen with persistent storage
/// All settings are automatically saved and loaded
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await SettingsStorage.loadSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _settings = AppSettings(); // Use defaults
        _isLoading = false;
      });
    }
  }

  /// Update and save language
  Future<void> _updateLanguage(String language) async {
    setState(() {
      _settings = _settings.copyWith(language: language);
    });

    await SettingsStorage.updateLanguage(language);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Язык изменен на ${_settings.languageName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Update and save notifications
  Future<void> _updateNotifications(bool value) async {
    setState(() {
      _settings = _settings.copyWith(notificationsEnabled: value);
    });

    await SettingsStorage.updateNotifications(value);
  }

  /// Update and save push notifications
  Future<void> _updatePushNotifications(bool value) async {
    setState(() {
      _settings = _settings.copyWith(pushNotificationsEnabled: value);
    });

    await SettingsStorage.updatePushNotifications(value);
  }

  /// Update and save email notifications
  Future<void> _updateEmailNotifications(bool value) async {
    setState(() {
      _settings = _settings.copyWith(emailNotificationsEnabled: value);
    });

    await SettingsStorage.updateEmailNotifications(value);
  }

  /// Update and save sound
  Future<void> _updateSound(bool value) async {
    setState(() {
      _settings = _settings.copyWith(soundEnabled: value);
    });

    await SettingsStorage.updateSound(value);
  }

  /// Update and save vibration
  Future<void> _updateVibration(bool value) async {
    setState(() {
      _settings = _settings.copyWith(vibrationEnabled: value);
    });

    await SettingsStorage.updateVibration(value);
  }

  /// Update and save new offer notifications
  Future<void> _updateNewOfferNotifications(bool value) async {
    setState(() {
      _settings = _settings.copyWith(newOfferNotificationsEnabled: value);
    });

    await SettingsStorage.updateNewOfferNotifications(value);
  }

  /// Update and save reservation status notifications
  Future<void> _updateReservationStatusNotifications(bool value) async {
    setState(() {
      _settings = _settings.copyWith(reservationStatusNotificationsEnabled: value);
    });

    await SettingsStorage.updateReservationStatusNotifications(value);
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Section
            // _buildSectionTitle('Язык'),
            // SizedBox(height: 12.h),
            // _buildLanguageTile('Русский', 'ru'),
            // SizedBox(height: 8.h),
            // _buildLanguageTile('Қазақша', 'kk'),
            // SizedBox(height: 8.h),
            // _buildLanguageTile('English', 'en'),
            //
            // SizedBox(height: 32.h),

            // Notifications Section
            _buildSectionTitle('Уведомления'),
            SizedBox(height: 12.h),
            _buildSwitchTile(
              'Все уведомления',
              'Получать уведомления о бронированиях',
              _settings.notificationsEnabled,
              _updateNotifications,
            ),
            SizedBox(height: 8.h),
            _buildSwitchTile(
              'Push-уведомления',
              'Получать push-уведомления на устройство',
              _settings.pushNotificationsEnabled,
              _updatePushNotifications,
              enabled: _settings.notificationsEnabled,
            ),
            SizedBox(height: 8.h),
            _buildSwitchTile(
              'Email уведомления',
              'Получать уведомления на почту',
              _settings.emailNotificationsEnabled,
              _updateEmailNotifications,
              enabled: _settings.notificationsEnabled,
            ),
            SizedBox(height: 8.h),
            _buildSwitchTile(
              'Новые ответы на заявки',
              'Уведомления о новых предложениях от менеджеров',
              _settings.newOfferNotificationsEnabled,
              _updateNewOfferNotifications,
              enabled: _settings.notificationsEnabled,
            ),
            SizedBox(height: 8.h),
            _buildSwitchTile(
              'Изменение статуса бронирования',
              'Уведомления об изменении статуса бронирования',
              _settings.reservationStatusNotificationsEnabled,
              _updateReservationStatusNotifications,
              enabled: _settings.notificationsEnabled,
            ),

            SizedBox(height: 32.h),

            // Sound & Vibration Section
            _buildSectionTitle('Звук и вибрация'),
            SizedBox(height: 12.h),
            _buildSwitchTile(
              'Звук',
              'Звуковые уведомления',
              _settings.soundEnabled,
              _updateSound,
            ),
            SizedBox(height: 8.h),
            _buildSwitchTile(
              'Вибрация',
              'Вибрация при уведомлениях',
              _settings.vibrationEnabled,
              _updateVibration,
            ),

            SizedBox(height: 32.h),

            // Other Section
            _buildSectionTitle('Прочее'),
            SizedBox(height: 12.h),
            _buildActionTile(
              'Политика конфиденциальности',
              Icons.privacy_tip_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 8.h),
            _buildActionTile(
              'Поддержка',
              Icons.help_outline,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 8.h),
            _buildActionTile(
              'О приложении',
              Icons.info_outline,
                  () {
                _showAboutDialog();
              },
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// Section title
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

  /// Language selection tile
  Widget _buildLanguageTile(String title, String langCode) {
    final isSelected = _settings.language == langCode;

    return GestureDetector(
      onTap: () => _updateLanguage(langCode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF295CDB).withOpacity(0.1) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF295CDB) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF295CDB) : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF295CDB),
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  /// Switch tile for settings
  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged, {
        bool enabled = true,
      }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: enabled ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: const Color(0xFF295CDB),
          ),
        ],
      ),
    );
  }

  /// Action tile (with navigation)
  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: const Color(0xFF295CDB),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
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

  /// Show about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('О приложении'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UI Tap'),
            SizedBox(height: 8.h),
            Text(
              'Версия: 1.0.0',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Приложение для поиска и бронирования жилья',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}