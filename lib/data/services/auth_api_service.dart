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

/// ⬅️ FIXED: Проверка наличия refreshToken перед refresh
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
      // ⬅️ НОВОЕ: Проверяем наличие refreshToken в cookies
      final hasToken = await DioClient().hasRefreshToken();
      if (!hasToken) {
        print('❌ [REFRESH] No refreshToken cookie found!');
        print('🚪 [REFRESH] Logging out...');
        await logout();
        _completeWaitingRequests(null);
        _isRefreshing = false;
        return null;
      }

      print('📤 [REFRESH] POST ${ApiConstants.refreshEndpoint}');
      print('🍪 [REFRESH] Cookies will be sent automatically by Dio');

      // Отправляем запрос БЕЗ параметров
      // Cookies с refreshToken отправляются автоматически!
      final response = await _dio.post(
        ApiConstants.refreshEndpoint,
      );

      print('📥 [REFRESH] Status: ${response.statusCode}');
      print('📥 [REFRESH] Response keys: ${response.data?.keys}');

      if (response.statusCode == 200) {
        final data = response.data;

        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String?;
        final tokenType = data['tokenType'] as String? ?? 'Bearer';
        final expiresIn = data['expiresIn'] as int? ?? 900;

        print('✅ [REFRESH] Got new tokens');
        print('   - accessToken length: ${newAccessToken.length}');
        print('   - refreshToken: ${newRefreshToken != null ? 'updated' : 'same'}');
        print('   - expiresIn: $expiresIn sec');

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
      print('   Status: ${e.response?.statusCode}');
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

        // ⬅️ НОВОЕ: Запускаем auto-refresh СРАЗУ после логина
        startAutoRefresh();

        // ⬅️ DEBUG: Проверяем cookies
        await DioClient().printSavedCookies();  // ⬅️ Убрали _

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

        // ⬅️ НОВОЕ: Запускаем auto-refresh СРАЗУ после регистрации
        startAutoRefresh();

        // ⬅️ DEBUG: Проверяем cookies
        await DioClient().printSavedCookies();  // ⬅️ Убрали _

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

  /// PUT /users/me - обновление профиля текущего пользователя
  Future<UserResponse> updateCurrentUser(
    String accessToken, {
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      print('📤 [UPDATE USER] PUT ${ApiConstants.currentUserEndpoint}');

      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      };

      final response = await _dio.put(
        ApiConstants.currentUserEndpoint,
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      print('📥 [UPDATE USER] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Бэкенд может вернуть обновленный профиль; если нет — просто повторно дернем /users/me
        if (response.data is Map<String, dynamic>) {
          return UserResponse.fromJson(response.data as Map<String, dynamic>);
        } else {
          // Если боди нет, запрашиваем свежий профиль
          return getCurrentUser(accessToken);
        }
      } else {
        throw Exception('Не удалось обновить профиль');
      }
    } on DioException catch (e) {
      print('❌ [UPDATE USER] Error: ${e.message}');
      if (e.response?.statusCode == 400) {
        throw Exception('Некорректные данные запроса');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Токен истек. Войдите снова.');
      }
      throw Exception('Ошибка обновления профиля');
    }
  }

  /// PUT /users/me/photo - загрузка аватара (multipart/form-data)
  Future<void> uploadProfilePhoto(String accessToken, String filePath) async {
    try {
      print('📤 [USER PHOTO] PUT /users/me/photo');

      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.put(
        '/users/me/photo',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('📥 [USER PHOTO] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Не удалось загрузить фото');
      }
    } on DioException catch (e) {
      print('❌ [USER PHOTO] Error: ${e.message}');
      if (e.response?.statusCode == 400) {
        throw Exception('Некорректный файл или формат');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      }
      throw Exception('Ошибка загрузки фото профиля');
    }
  }

  /// DELETE /users/me/photo - удалить аватар
  Future<void> deleteProfilePhoto(String accessToken) async {
    try {
      print('🗑️ [USER PHOTO] DELETE /users/me/photo');

      final response = await _dio.delete(
        '/users/me/photo',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      print('📥 [USER PHOTO DELETE] Status: ${response.statusCode}');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Не удалось удалить фото');
      }
    } on DioException catch (e) {
      print('❌ [USER PHOTO DELETE] Error: ${e.message}');
      if (e.response?.statusCode == 400) {
        throw Exception('У пользователя нет фото');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      }
      throw Exception('Ошибка удаления фото профиля');
    }
  }

  Future<void> logout() async {
    print('🚪 [LOGOUT] Logging out...');
    stopAutoRefresh();
    await TokenStorage.clearAll();
    await DioClient().clearCookies();
    print('✅ [LOGOUT] Logged out');
  }

  /// ⬅️ UPDATED: Auto-refresh каждые 13 минут (780 сек)
  void startAutoRefresh() {
    stopAutoRefresh();
    print('⏰ [AUTO-REFRESH] Starting timer (every 13 minutes)');

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 780),  // 13 минут
          (timer) async {
        print('⏰ [AUTO-REFRESH] Time to refresh (13 min passed)');

        // ⬅️ НОВОЕ: Проверяем наличие refreshToken перед refresh
        final hasToken = await DioClient().hasRefreshToken();
        if (!hasToken) {
          print('❌ [AUTO-REFRESH] No refreshToken, stopping');
          stopAutoRefresh();
          return;
        }

        final newToken = await refreshAccessToken();
        if (newToken == null) {
          print('❌ [AUTO-REFRESH] Failed, stopping');
          stopAutoRefresh();
        } else {
          print('✅ [AUTO-REFRESH] Success, next refresh in 13 min');
        }
      },
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('⏹️ [AUTO-REFRESH] Stopped');
  }

  Future<void> initAutoRefresh() async {
    print('🚀 [INIT] Initializing auto-refresh...');

    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (!isLoggedIn) {
      print('❌ [INIT] Not logged in');
      return;
    }

    // ⬅️ НОВОЕ: Проверяем наличие refreshToken
    final hasToken = await DioClient().hasRefreshToken();
    if (!hasToken) {
      print('❌ [INIT] No refreshToken cookie, logout');
      await logout();
      return;
    }

    // ⬅️ НОВОЕ: Проверяем, не истек ли token
    final isExpired = await TokenStorage.isTokenExpired();
    if (isExpired) {
      print('⚠️ [INIT] Token expired, refreshing immediately');
      final newToken = await refreshAccessToken();
      if (newToken == null) {
        print('❌ [INIT] Failed to refresh, logout');
        await logout();
        return;
      }
    }

    startAutoRefresh();
    print('✅ [INIT] Auto-refresh initialized');
  }
}