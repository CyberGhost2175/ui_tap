/// App Settings Model
/// Stores user preferences that persist across app sessions
class AppSettings {
  final String language; // 'ru', 'kk', 'en'
  final bool notificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool newOfferNotificationsEnabled; // Уведомления о новых ответах на заявки
  final bool reservationStatusNotificationsEnabled; // Уведомления о смене статуса бронирования
  final String theme; // 'light', 'dark', 'system'

  AppSettings({
    this.language = 'ru',
    this.notificationsEnabled = true,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.newOfferNotificationsEnabled = true,
    this.reservationStatusNotificationsEnabled = true,
    this.theme = 'light',
  });

  /// Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] as String? ?? 'ru',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      newOfferNotificationsEnabled: json['newOfferNotificationsEnabled'] as bool? ?? true,
      reservationStatusNotificationsEnabled: json['reservationStatusNotificationsEnabled'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'light',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'language': language,
    'notificationsEnabled': notificationsEnabled,
    'pushNotificationsEnabled': pushNotificationsEnabled,
    'emailNotificationsEnabled': emailNotificationsEnabled,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'newOfferNotificationsEnabled': newOfferNotificationsEnabled,
    'reservationStatusNotificationsEnabled': reservationStatusNotificationsEnabled,
    'theme': theme,
  };

  /// Create copy with updated fields
  AppSettings copyWith({
    String? language,
    bool? notificationsEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? newOfferNotificationsEnabled,
    bool? reservationStatusNotificationsEnabled,
    String? theme,
  }) {
    return AppSettings(
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      newOfferNotificationsEnabled: newOfferNotificationsEnabled ?? this.newOfferNotificationsEnabled,
      reservationStatusNotificationsEnabled: reservationStatusNotificationsEnabled ?? this.reservationStatusNotificationsEnabled,
      theme: theme ?? this.theme,
    );
  }

  /// Get language name for display
  String get languageName {
    switch (language) {
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      case 'en':
        return 'English';
      default:
        return 'Русский';
    }
  }

  @override
  String toString() {
    return 'AppSettings(language: $language, notifications: $notificationsEnabled, theme: $theme)';
  }
}