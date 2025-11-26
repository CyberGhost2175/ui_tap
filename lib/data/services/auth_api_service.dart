import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/auth/register_request.dart';
import '../models/auth/register_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/user/user_response.dart';

/// Service for authentication API calls
class AuthApiService {
  /// Register new user
  ///
  /// Returns [RegisterResponse] on success (201)
  /// Throws [Exception] on error (400, 500)
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');

      // 🔍 DEBUG: Log request details
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

      // 🔍 DEBUG: Log response details
      print('📥 Server Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      // Success - user registered
      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return RegisterResponse.fromJson(jsonResponse);
      }
      // Bad request - validation error or user already exists
      else if (response.statusCode == 400) {
        // API может вернуть сообщение об ошибке в теле ответа
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Некорректные данные или пользователь уже существует';
          print('❌ Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          print('❌ Error 400 (no JSON): ${response.body}');
          throw Exception('Некорректные данные или пользователь уже существует');
        }
      }
      // Internal server error
      else if (response.statusCode == 500) {
        print('❌ Error 500: Server error');
        print('Response body: ${response.body}');
        throw Exception('Ошибка сервера. Попробуйте позже');
      }
      // Other errors
      else {
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
  ///
  /// POST /auth/login
  /// Returns [LoginResponse] on success (200)
  /// Throws [Exception] on error (400, 401, 500)
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

      // 🔍 DEBUG: Log request details
      print('📤 Login Request:');
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

      // 🔍 DEBUG: Log response details
      print('📥 Server Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Success - user logged in
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('✅ Login successful!');
        return LoginResponse.fromJson(jsonResponse);
      }
      // Bad request - validation error
      else if (response.statusCode == 400) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Некорректные данные';
          print('❌ Error 400: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          print('❌ Error 400 (no JSON): ${response.body}');
          throw Exception('Некорректные данные');
        }
      }
      // Unauthorized - wrong credentials
      else if (response.statusCode == 401) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Неверный email или пароль';
          print('❌ Error 401: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          print('❌ Error 401 (no JSON): ${response.body}');
          throw Exception('Неверный email или пароль');
        }
      }
      // Internal server error
      else if (response.statusCode == 500) {
        print('❌ Error 500: Server error');
        print('Response body: ${response.body}');
        throw Exception('Ошибка сервера. Попробуйте позже');
      }
      // Other errors
      else {
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
  ///
  /// Requires: Authorization Bearer token
  /// Returns [UserResponse] on success (200)
  /// Throws [Exception] on error (401, 403, 500)
  Future<UserResponse> getCurrentUser(String accessToken) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.currentUserEndpoint}');

      // 🔍 DEBUG: Log request details
      print('📤 Get Current User Request:');
      print('URL: $url');
      print('Authorization: Bearer ${accessToken.substring(0, 20)}...');

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

      // 🔍 DEBUG: Log response details
      print('📥 Server Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Success - got user data
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('✅ User data loaded successfully');
        return UserResponse.fromJson(jsonResponse);
      }
      // Unauthorized - token invalid or expired
      else if (response.statusCode == 401) {
        print('❌ Error 401: Unauthorized - token invalid or expired');
        throw Exception('Токен недействителен или истек');
      }
      // Forbidden
      else if (response.statusCode == 403) {
        print('❌ Error 403: Forbidden');
        throw Exception('Доступ запрещен');
      }
      // Server error
      else if (response.statusCode == 500) {
        print('❌ Error 500: Internal server error');
        throw Exception('Ошибка сервера. Попробуйте позже');
      }
      // Other errors
      else {
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
}