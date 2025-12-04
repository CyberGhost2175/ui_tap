import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../services/settings_storage.dart';

/// Local Notification Service
/// Works without Firebase - shows notifications when app is open or in background
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions (Android 13+)
    if (await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false) {
      print('✅ [NOTIFICATIONS] Android permissions granted');
    }

    // Request permissions (iOS)
    if (await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
        false) {
      print('✅ [NOTIFICATIONS] iOS permissions granted');
    }

    _isInitialized = true;
    print('✅ [NOTIFICATIONS] Service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 [NOTIFICATIONS] Notification tapped: ${response.payload}');
    // Можно добавить навигацию на нужный экран
  }

  /// Show notification about new offer
  Future<void> showNewOfferNotification({
    required int requestId,
    required String accommodationName,
    required int price,
  }) async {
    // Проверяем настройки пользователя
    final settings = await SettingsStorage.loadSettings();
    
    if (!settings.notificationsEnabled || !settings.newOfferNotificationsEnabled) {
      print('🔕 [NOTIFICATIONS] Notifications disabled by user');
      return;
    }

    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_offers_channel',
      'Новые предложения',
      channelDescription: 'Уведомления о новых предложениях на ваши заявки',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Notification details
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _notifications.show(
      requestId, // ID уведомления (используем ID заявки)
      'Новое предложение!',
      '$accommodationName\n${price} тг/ночь',
      details,
      payload: 'request_$requestId',
    );

    print('📬 [NOTIFICATIONS] New offer notification shown for request $requestId');
  }

  /// Show notification about reservation status change
  Future<void> showReservationStatusNotification({
    required int reservationId,
    required String statusText,
    required String accommodationName,
  }) async {
    // Проверяем настройки пользователя
    final settings = await SettingsStorage.loadSettings();
    
    if (!settings.notificationsEnabled || !settings.reservationStatusNotificationsEnabled) {
      print('🔕 [NOTIFICATIONS] Notifications disabled by user');
      return;
    }

    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reservation_status_channel',
      'Статус бронирования',
      channelDescription: 'Уведомления об изменении статуса бронирования',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Notification details
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _notifications.show(
      10000 + reservationId, // ID уведомления (10000 + ID бронирования)
      'Статус бронирования изменен',
      '$accommodationName\n$statusText',
      details,
      payload: 'reservation_$reservationId',
    );

    print('📬 [NOTIFICATIONS] Reservation status notification shown for reservation $reservationId');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🗑️ [NOTIFICATIONS] All notifications cancelled');
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    print('🗑️ [NOTIFICATIONS] Notification $id cancelled');
  }
}

