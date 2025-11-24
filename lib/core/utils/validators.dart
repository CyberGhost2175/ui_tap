/// Utility class for form validation
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }

    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Введите $fieldName';
    }

    return null;
  }

  /// Validate name (only letters)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Введите $fieldName';
    }

    if (value.length < 2) {
      return '$fieldName должно содержать минимум 2 символа';
    }

    return null;
  }

  /// Validate phone number (Kazakhstan format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите номер телефона';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Check if it's a valid length (Kazakhstan: +7 XXX XXX XX XX = 11 digits)
    if (digitsOnly.length < 10) {
      return 'Введите корректный номер телефона';
    }

    return null;
  }

  /// Validate username (alphanumeric, underscore, dash)
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя пользователя';
    }

    if (value.length < 3) {
      return 'Имя пользователя должно содержать минимум 3 символа';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Только буквы, цифры, _ и -';
    }

    return null;
  }
}