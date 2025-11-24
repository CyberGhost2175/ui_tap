import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and managing authentication tokens
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _expiresAtKey = 'expires_at';

  // User data keys
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _userUsernameKey = 'user_username';

  /// Save token after successful login/registration
  static Future<void> saveToken({
    required String accessToken,
    required String tokenType,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Calculate expiration time
    final expiresAt = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_tokenTypeKey, tokenType);
    await prefs.setInt(_expiresAtKey, expiresAt);
  }

  /// Save user data
  static Future<void> saveUserData({
    String? userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (userId != null) await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userFirstNameKey, firstName);
    await prefs.setString(_userLastNameKey, lastName);
    if (phone != null) await prefs.setString(_userPhoneKey, phone);
    if (username != null) await prefs.setString(_userUsernameKey, username);
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get token type (usually "Bearer")
  static Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey) ?? 'Bearer';
  }

  /// Get full Authorization header value
  static Future<String?> getAuthorizationHeader() async {
    final token = await getAccessToken();
    final type = await getTokenType();

    if (token == null) return null;
    return '$type $token';
  }

  /// Check if token is expired
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (expiresAt == null) return true;

    return DateTime.now().millisecondsSinceEpoch >= expiresAt;
  }

  /// Check if user is logged in (has valid token)
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;

    return !(await isTokenExpired());
  }

  /// Get user data
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'userId': prefs.getString(_userIdKey),
      'email': prefs.getString(_userEmailKey),
      'firstName': prefs.getString(_userFirstNameKey),
      'lastName': prefs.getString(_userLastNameKey),
      'phone': prefs.getString(_userPhoneKey),
      'username': prefs.getString(_userUsernameKey),
    };
  }

  /// Clear all stored tokens and user data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_expiresAtKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userFirstNameKey);
    await prefs.remove(_userLastNameKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userUsernameKey);
  }

  /// Get time until token expires (in seconds)
  static Future<int?> getTimeUntilExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (expiresAt == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = expiresAt - now;

    return diff > 0 ? (diff / 1000).round() : 0;
  }
}