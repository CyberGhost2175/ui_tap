import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/auth/register_request.dart';
import '../models/auth/register_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/user/user_response.dart';
import 'token_storage.dart';

/// 🔄 Enhanced Authentication API Service with Auto-Refresh
///
/// Features:
/// 1. ⏰ Automatic token refresh every 13 minutes (before expiration)
/// 2. 🔒 Prevents concurrent refresh requests
/// 3. 🔄 Auto-refresh on app startup if token is about to expire
/// 4. 🚫 Graceful logout on refresh failure
class AuthApiService {
  // ⬅️ Singleton pattern
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  // ⬅️ Auto-refresh timer
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshCompleters = [];

  /// 🔄 Refresh access token using refresh token endpoint
  ///
  /// Returns new access token on success, null on failure
  Future<String?> refreshAccessToken() async {
    print('🔄 [REFRESH] Attempting to refresh token...');

    // Prevent concurrent refresh requests
    if (_isRefreshing) {
      print('⏳ [REFRESH] Already refreshing, waiting for result...');
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshEndpoint}');

      print('📤 [REFRESH] POST $url');

      final response = await http.post(
        url,
        headers: ApiConstants.headers,
      ).timeout(ApiConstants.connectionTimeout);

      print('📥 [REFRESH] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract tokens from response
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;
        final tokenType = data['tokenType'] as String? ?? 'Bearer';
        final expiresIn = data['expiresIn'] as int? ?? 900;

        // Save new tokens
        await TokenStorage.saveToken(
          accessToken: accessToken,
          refreshToken: refreshToken,
          tokenType: tokenType,
          expiresIn: expiresIn,
        );

        print('✅ [REFRESH] Token refreshed successfully');
        print('📝 [REFRESH] Expires in: $expiresIn seconds');

        // Complete all waiting requests
        for (var completer in _refreshCompleters) {
          if (!completer.isCompleted) {
            completer.complete(accessToken);
          }
        }
        _refreshCompleters.clear();

        return accessToken;
      } else {
        print('❌ [REFRESH] Failed: ${response.statusCode}');
        print('Response: ${response.body}');

        // Refresh failed - clear tokens and logout
        await TokenStorage.clearAll();

        // Complete all waiting requests with null
        for (var completer in _refreshCompleters) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
        _refreshCompleters.clear();

        return null;
      }
    } catch (e) {
      print('❌ [REFRESH] Error: $e');

      // Complete all waiting requests with null
      for (var completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
      _refreshCompleters.clear();

      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// ⏰ Start automatic token refresh timer
  ///
  /// Refreshes token every 13 minutes (780 seconds)
  /// Token expires in 15 minutes (900 seconds), so we refresh 2 min before
  void startAutoRefresh() {
    stopAutoRefresh(); // Cancel existing timer

    print('⏰ [AUTO-REFRESH] Starting timer (every 13 minutes)');

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 780), // 13 minutes
          (timer) async {
        print('⏰ [AUTO-REFRESH] Timer triggered');
        final newToken = await refreshAccessToken();

        if (newToken == null) {
          print('❌ [AUTO-REFRESH] Failed to refresh - stopping timer');
          stopAutoRefresh();
        }
      },
    );
  }

  /// 🛑 Stop automatic token refresh timer
  void stopAutoRefresh() {
    if (_refreshTimer != null) {
      print('🛑 [AUTO-REFRESH] Stopping timer');
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  /// 🚀 Initialize auto-refresh on app startup
  ///
  /// Call this when app starts to check if token needs refresh
  Future<void> initAutoRefresh() async {
    print('🚀 [INIT] Initializing auto-refresh...');

    final isLoggedIn = await TokenStorage.isLoggedIn();

    if (!isLoggedIn) {
      print('❌ [INIT] User not logged in, skipping auto-refresh');
      return;
    }

    // Check if token is about to expire
    final timeUntilExpiration = await TokenStorage.getTimeUntilExpiration();
    print('📊 [INIT] Time until expiration: $timeUntilExpiration seconds');

    if (timeUntilExpiration != null && timeUntilExpiration < 120) {
      // Token expires in less than 2 minutes - refresh immediately
      print('⚠️ [INIT] Token expires soon, refreshing now...');
      await refreshAccessToken();
    }

    // Start auto-refresh timer
    startAutoRefresh();
  }

  /// 📝 Register new user
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');

      print('📤 [REGISTER] POST $url');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await http
          .post(
        url,
        headers: ApiConstants.headers,
        body: jsonEncode(request.toJson()),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [REGISTER] Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        // ⬅️ Start auto-refresh after registration
        startAutoRefresh();

        return RegisterResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Ошибка регистрации';
        throw Exception(errorMessage);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера');
      } else {
        throw Exception('Ошибка регистрации: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения');
    }
  }

  /// 🔐 Login user
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

      print('📤 [LOGIN] POST $url');
      print('Email: ${request.email}');

      final response = await http
          .post(
        url,
        headers: ApiConstants.headers,
        body: jsonEncode(request.toJson()),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 [LOGIN] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // ⬅️ Start auto-refresh after login
        startAutoRefresh();

        return LoginResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Неверный email или пароль');
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера');
      } else {
        throw Exception('Ошибка входа: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения');
    }
  }

  /// 👤 Get current user data
  Future<UserResponse> getCurrentUser(String accessToken) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.currentUserEndpoint}');

      print('📤 [GET USER] GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(ApiConstants.connectionTimeout);

      print('📥 [GET USER] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return UserResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        // Token expired - try to refresh
        print('⚠️ [GET USER] Token expired, refreshing...');
        final newToken = await refreshAccessToken();

        if (newToken != null) {
          // Retry with new token
          return getCurrentUser(newToken);
        }

        throw Exception('Токен истек');
      } else if (response.statusCode == 403) {
        throw Exception('Доступ запрещен');
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера');
      } else {
        throw Exception('Ошибка загрузки данных: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка подключения');
    }
  }

  /// 🚪 Logout user
  Future<void> logout() async {
    print('🚪 [LOGOUT] Logging out...');
    stopAutoRefresh();
    await TokenStorage.clearAll();
    print('✅ [LOGOUT] Logged out successfully');
  }
}