import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings/app_settings.dart';

/// Settings Storage Service
/// Manages app settings persistence using SharedPreferences
class SettingsStorage {
  // Storage keys
  static const String _settingsKey = 'app_settings';

  /// Save settings
  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
    print('💾 Settings saved: $settings');
  }

  /// Load settings
  static Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString == null) {
        print('📦 No saved settings found, using defaults');
        return AppSettings(); // Return default settings
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = AppSettings.fromJson(json);
      print('✅ Settings loaded: $settings');
      return settings;
    } catch (e) {
      print('❌ Error loading settings: $e');
      return AppSettings(); // Return default settings on error
    }
  }

  /// Update language
  static Future<void> updateLanguage(String language) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(language: language);
    await saveSettings(updated);
  }

  /// Update notifications enabled
  static Future<void> updateNotifications(bool enabled) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(notificationsEnabled: enabled);
    await saveSettings(updated);
  }

  /// Update push notifications
  static Future<void> updatePushNotifications(bool enabled) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(pushNotificationsEnabled: enabled);
    await saveSettings(updated);
  }

  /// Update email notifications
  static Future<void> updateEmailNotifications(bool enabled) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(emailNotificationsEnabled: enabled);
    await saveSettings(updated);
  }

  /// Update sound
  static Future<void> updateSound(bool enabled) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(soundEnabled: enabled);
    await saveSettings(updated);
  }

  /// Update vibration
  static Future<void> updateVibration(bool enabled) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(vibrationEnabled: enabled);
    await saveSettings(updated);
  }

  /// Update theme
  static Future<void> updateTheme(String theme) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(theme: theme);
    await saveSettings(updated);
  }

  /// Get current language
  static Future<String> getCurrentLanguage() async {
    final settings = await loadSettings();
    return settings.language;
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await loadSettings();
    return settings.notificationsEnabled;
  }

  /// Reset settings to defaults
  static Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    print('🔄 Settings reset to defaults');
  }

  /// Clear all settings (for logout)
  /// Note: Settings usually persist across logins, but can be cleared if needed
  static Future<void> clearSettings() async {
    await resetSettings();
  }
}