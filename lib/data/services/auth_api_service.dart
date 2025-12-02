import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth/register_request.dart';
import '../models/auth/register_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/user/user_response.dart';
import 'token_storage.dart';
import 'dio_client.dart';

class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshCompleters = [];

  Dio get _dio => DioClient().dio;

  /// 🔄 Refresh access token using cookies
  Future<String?> refreshAccessToken() async {
    print('🔄 [REFRESH] Attempting to refresh token...');

    if (_isRefreshing) {
      print('⏳ [REFRESH] Already refreshing, waiting...');
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      print('📤 [REFRESH] POST ${ApiConstants.refreshEndpoint}');
      print('🍪 [REFRESH] Cookies will be sent automatically by Dio');

      // Отправляем запрос БЕЗ параметров
      // Cookies с refreshToken отправляются автоматически!
      final response = await _dio.post(
        ApiConstants.refreshEndpoint,
      );

      print('📥 [REFRESH] Status: ${response.statusCode}');
      print('📥 [REFRESH] Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String?;
        final tokenType = data['tokenType'] as String? ?? 'Bearer';
        final expiresIn = data['expiresIn'] as int? ?? 900;

        print('✅ [REFRESH] Got new tokens');
        print('   - accessToken length: ${newAccessToken.length}');
        print('   - refreshToken: ${newRefreshToken != null ? 'updated' : 'same'}');

        // Сохраняем только accessToken (refreshToken в cookie)
        await TokenStorage.saveToken(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? '',
          tokenType: tokenType,
          expiresIn: expiresIn,
        );

        print('✅ [REFRESH] Token refreshed successfully');

        _completeWaitingRequests(newAccessToken);
        return newAccessToken;

      } else {
        print('❌ [REFRESH] Failed: ${response.statusCode}');
        _completeWaitingRequests(null);
        return null;
      }
    } on DioException catch (e) {
      print('❌ [REFRESH] DioException: ${e.message}');
      print('   Response: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        print('🚪 [REFRESH] Refresh token expired, logging out');
        await logout();
      }

      _completeWaitingRequests(null);
      return null;
    } catch (e, stackTrace) {
      print('❌ [REFRESH] Error: $e');
      print('   Stack: $stackTrace');
      _completeWaitingRequests(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  void _completeWaitingRequests(String? token) {
    for (var completer in _refreshCompleters) {
      if (!completer.isCompleted) {
        completer.complete(token);
      }
    }
    _refreshCompleters.clear();
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('📤 [LOGIN] POST ${ApiConstants.loginEndpoint}');

      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: request.toJson(),
      );

      print('📥 [LOGIN] Status: ${response.statusCode}');
      print('🍪 [LOGIN] Cookies saved automatically by Dio');

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);

        print('💾 [STORAGE] Saving accessToken...');

        await TokenStorage.saveToken(
          accessToken: loginResponse.accessToken,
          refreshToken: loginResponse.refreshToken,
          tokenType: loginResponse.tokenType,
          expiresIn: loginResponse.expiresIn,
        );

        print('✅ [LOGIN] Login successful');

        startAutoRefresh();

        return loginResponse;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [LOGIN] Error: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Неверный email или пароль');
      }
      throw Exception('Ошибка входа');
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      print('📤 [REGISTER] POST ${ApiConstants.registerEndpoint}');

      final response = await _dio.post(
        ApiConstants.registerEndpoint,
        data: request.toJson(),
      );

      print('📥 [REGISTER] Status: ${response.statusCode}');
      print('🍪 [REGISTER] Cookies saved automatically by Dio');

      if (response.statusCode == 201) {
        final registerResponse = RegisterResponse.fromJson(response.data);

        await TokenStorage.saveToken(
          accessToken: registerResponse.accessToken,
          refreshToken: registerResponse.refreshToken,
          tokenType: registerResponse.tokenType,
          expiresIn: registerResponse.expiresIn,
        );

        print('✅ [REGISTER] Registration successful');

        startAutoRefresh();

        return registerResponse;
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [REGISTER] Error: ${e.message}');
      throw Exception('Ошибка регистрации');
    }
  }

  Future<UserResponse> getCurrentUser(String accessToken) async {
    try {
      print('📤 [GET USER] GET ${ApiConstants.currentUserEndpoint}');

      final response = await _dio.get(
        ApiConstants.currentUserEndpoint,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      print('📥 [GET USER] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return UserResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to get user');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        print('⚠️ [GET USER] Token expired, refreshing...');
        final newToken = await refreshAccessToken();
        if (newToken != null) {
          return getCurrentUser(newToken);
        }
        throw Exception('Токен истек. Войдите снова.');
      }
      throw Exception('Ошибка загрузки данных');
    }
  }

  Future<void> logout() async {
    print('🚪 [LOGOUT] Logging out...');
    stopAutoRefresh();
    await TokenStorage.clearAll();
    await DioClient().clearCookies();
    print('✅ [LOGOUT] Logged out');
  }

  void startAutoRefresh() {
    stopAutoRefresh();
    print('⏰ [AUTO-REFRESH] Starting timer (every 13 minutes)');
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 780),
          (timer) async {
        print('⏰ [AUTO-REFRESH] Refreshing...');
        final newToken = await refreshAccessToken();
        if (newToken == null) {
          print('❌ [AUTO-REFRESH] Failed, stopping');
          stopAutoRefresh();
        } else {
          print('✅ [AUTO-REFRESH] Success');
        }
      },
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> initAutoRefresh() async {
    print('🚀 [INIT] Initializing auto-refresh...');
    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (!isLoggedIn) {
      print('❌ [INIT] Not logged in');
      return;
    }
    startAutoRefresh();
    print('✅ [INIT] Auto-refresh initialized');
  }
}