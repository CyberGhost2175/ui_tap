import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 Enhanced Token Storage Service with Refresh Token Support
///
/// Features:
/// 1. 🔒 Secure storage for sensitive tokens (flutter_secure_storage)
/// 2. 📦 Shared preferences for user data
/// 3. ⏰ Token expiration tracking
/// 4. 🔄 Refresh token support
class TokenStorage {
  // ⬅️ Secure storage for tokens
  static const _secureStorage = FlutterSecureStorage();

  // Token keys (secure storage)
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenTypeKey = 'token_type';

  // Expiration key (shared preferences)
  static const String _expiresAtKey = 'expires_at';

  // User data keys (shared preferences)
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _userUsernameKey = 'user_username';

  /// 💾 Save tokens after login/registration
  ///
  /// Stores access token and refresh token securely
  static Future<void> saveToken({
    required String accessToken,
    String? refreshToken,
    required String tokenType,
    required int expiresIn,
  }) async {
    print('💾 [STORAGE] Saving tokens...');

    // Calculate expiration timestamp
    final expiresAt = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    // Save tokens to secure storage
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);

    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      print('✅ [STORAGE] Refresh token saved');
    }

    await _secureStorage.write(key: _tokenTypeKey, value: tokenType);

    // Save expiration to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expiresAtKey, expiresAt);

    print('✅ [STORAGE] Tokens saved (expires in $expiresIn sec)');
  }

  /// 👤 Save user data
  static Future<void> saveUserData({
    String? userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    String? username,
  }) async {
    print('💾 [STORAGE] Saving user data...');

    final prefs = await SharedPreferences.getInstance();

    if (userId != null) await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userFirstNameKey, firstName);
    await prefs.setString(_userLastNameKey, lastName);
    if (phone != null) await prefs.setString(_userPhoneKey, phone);
    if (username != null) await prefs.setString(_userUsernameKey, username);

    print('✅ [STORAGE] User data saved');
  }

  /// 🔑 Get access token
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// 🔄 Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// 🏷️ Get token type (usually "Bearer")
  static Future<String?> getTokenType() async {
    final type = await _secureStorage.read(key: _tokenTypeKey);
    return type ?? 'Bearer';
  }

  /// 🔐 Get full Authorization header value
  ///
  /// Returns: "Bearer <token>"
  static Future<String?> getAuthorizationHeader() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final type = await getTokenType();
    return '$type $token';
  }

  /// ⏰ Check if token is expired
  ///
  /// Returns true if token will expire in less than 60 seconds
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (expiresAt == null) {
      print('⚠️ [STORAGE] No expiration time found');
      return true;
    }

    // Add 60 second buffer for refresh before actual expiration
    const bufferMs = 60 * 1000;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isExpired = now >= (expiresAt - bufferMs);

    if (isExpired) {
      print('⚠️ [STORAGE] Token is expired or expires soon');
    }

    return isExpired;
  }

  /// ✅ Check if user is logged in
  ///
  /// Returns true if user has valid token or refresh token
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();

    // No access token at all
    if (accessToken == null) {
      print('❌ [STORAGE] No access token');
      return false;
    }

    // Has refresh token - always considered logged in
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      print('✅ [STORAGE] User logged in (has refresh token)');
      return true;
    }

    // Check if access token is still valid
    final isExpired = await isTokenExpired();
    if (!isExpired) {
      print('✅ [STORAGE] User logged in (token valid)');
      return true;
    }

    print('❌ [STORAGE] Token expired and no refresh token');
    return false;
  }

  /// 👤 Get user data
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

  /// ⏱️ Get time until token expires (in seconds)
  ///
  /// Returns null if no expiration time set
  static Future<int?> getTimeUntilExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (expiresAt == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = expiresAt - now;

    return diff > 0 ? (diff / 1000).round() : 0;
  }

  /// 🗑️ Clear all tokens and user data (logout)
  static Future<void> clearAll() async {
    print('🗑️ [STORAGE] Clearing all data...');

    // Clear secure storage
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenTypeKey);

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiresAtKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userFirstNameKey);
    await prefs.remove(_userLastNameKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userUsernameKey);

    print('✅ [STORAGE] All data cleared');
  }

  /// 📊 Get token info for debugging
  static Future<Map<String, dynamic>> getTokenInfo() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    final timeUntilExpiration = await getTimeUntilExpiration();
    final isExpired = await isTokenExpired();

    return {
      'hasAccessToken': accessToken != null,
      'hasRefreshToken': refreshToken != null,
      'timeUntilExpiration': timeUntilExpiration,
      'isExpired': isExpired,
    };
  }
}