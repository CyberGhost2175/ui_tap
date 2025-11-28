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

/// Service for authentication API calls with auto-refresh
class AuthApiService {
  // ⬅️ Singleton pattern для управления таймером
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  // ⬅️ Таймер для автоматического обновления
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshCompleters = [];

  /// ⬅️ НОВЫЙ МЕТОД: Refresh access token
  Future<String?> refreshAccessToken() async {
    print('🔄 Attempting to refresh token...');

    // Предотвращаем одновременные запросы
    if (_isRefreshing) {
      print('⏳ Already refreshing, waiting...');
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshEndpoint}');

      print('📤 Refresh Token Request: $url');

      final response = await http.post(
        url,
        headers: ApiConstants.headers,
      ).timeout(ApiConstants.connectionTimeout);

      print('📥 Refresh Response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Сохраняем новый токен
        await TokenStorage.saveToken(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'], // если есть
          tokenType: data['tokenType'] ?? 'Bearer',
          expiresIn: data['expiresIn'] ?? 900,
        );

        final newToken = data['accessToken'];
        print('✅ Token refreshed successfully');

        // Завершаем все ожидающие запросы
        for (var completer in _refreshCompleters) {
          if (!completer.isCompleted) {
            completer.complete(newToken);
          }
        }
        _refreshCompleters.clear();

        return newToken;
      } else {
        print('❌ Refresh failed: ${response.statusCode}');

        // Refresh провалился - выходим
        await TokenStorage.clearAll();

        for (var completer in _refreshCompleters) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
        _refreshCompleters.clear();

        return null;
      }
    } catch (e) {
      print('❌ Refresh error: $e');

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

  /// ⬅️ НОВЫЙ МЕТОД: Start auto-refresh timer
  void startAutoRefresh() {
    _refreshTimer?.cancel();

    // Обновляем токен каждые 13 минут (780 сек)
    print('⏰ Starting auto-refresh timer (every 13 min)');

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 780),
          (timer) async {
        print('⏰ Auto-refresh triggered');
        await refreshAccessToken();
      },
    );
  }

  /// ⬅️ НОВЫЙ МЕТОД: Stop auto-refresh
  void stopAutoRefresh() {
    print('🛑 Stopping auto-refresh timer');
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Register new user
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');

      print('📤 Registration Request:');
      print('URL: $url');
      print('Headers: ${ApiConstants.headers}');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await http
          .post(
        url,
        headers: ApiConstants.headers,
        body: jsonEncode(request.toJson()),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 Server Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // ⬅️ Запускаем auto-refresh после регистрации
        startAutoRefresh();

        return RegisterResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 400) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Некорректные данные или пользователь уже существует';
          print('❌ Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          print('❌ Error 400 (no JSON): ${response.body}');
          throw Exception('Некорректные данные или пользователь уже существует');
        }
      } else if (response.statusCode == 500) {
        print('❌ Error 500: Server error');
        throw Exception('Ошибка сервера. Попробуйте позже');
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Ошибка регистрации: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception caught: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// Login user
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

      print('📤 Login Request:');
      print('URL: $url');
      print('Body: ${jsonEncode(request.toJson())}');

      final response = await http
          .post(
        url,
        headers: ApiConstants.headers,
        body: jsonEncode(request.toJson()),
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 Server Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('✅ Login successful!');

        // ⬅️ Запускаем auto-refresh после логина
        startAutoRefresh();

        return LoginResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 400) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Некорректные данные';
          print('❌ Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          print('❌ Error 400 (no JSON): ${response.body}');
          throw Exception('Некорректные данные');
        }
      } else if (response.statusCode == 401) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Неверный email или пароль';
          print('❌ Error 401: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          print('❌ Error 401 (no JSON): ${response.body}');
          throw Exception('Неверный email или пароль');
        }
      } else if (response.statusCode == 500) {
        print('❌ Error 500: Server error');
        throw Exception('Ошибка сервера. Попробуйте позже');
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Ошибка входа: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception caught: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// Get current user data
  Future<UserResponse> getCurrentUser(String accessToken) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.currentUserEndpoint}');

      print('📤 Get Current User Request:');
      print('URL: $url');

      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Authorization': 'Bearer $accessToken',
        },
      )
          .timeout(ApiConstants.connectionTimeout);

      print('📥 Server Response:');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('✅ User data loaded successfully');
        return UserResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        print('❌ Error 401: Unauthorized - token invalid or expired');
        throw Exception('Токен недействителен или истек');
      } else if (response.statusCode == 403) {
        print('❌ Error 403: Forbidden');
        throw Exception('Доступ запрещен');
      } else if (response.statusCode == 500) {
        print('❌ Error 500: Internal server error');
        throw Exception('Ошибка сервера. Попробуйте позже');
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Ошибка загрузки данных: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception caught: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка подключения к серверу');
    }
  }

  /// ⬅️ НОВЫЙ МЕТОД: Logout (останавливаем timer)
  Future<void> logout() async {
    stopAutoRefresh();
    await TokenStorage.clearAll();
  }
}