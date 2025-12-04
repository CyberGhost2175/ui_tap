import '../models/auth/register_request.dart';
import '../models/auth/register_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/user/user_response.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage.dart';

/// Repository for authentication operations
/// Implements business logic and error handling
class AuthRepository {
  final AuthApiService _apiService;

  AuthRepository({AuthApiService? apiService})
      : _apiService = apiService ?? AuthApiService();

  /// Register new user
  ///
  /// Returns [RegisterResponse] with access token on success (201)
  /// Returns error message on failure (400, 500)
  Future<({RegisterResponse? response, String? error})> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final request = RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        phoneNumber: phoneNumber, // ⬅️ ИСПРАВЛЕНО: phoneNumber вместо phone
      );

      final response = await _apiService.register(request);

      return (response: response, error: null);
    } on Exception catch (e) {
      return (response: null, error: e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      return (response: null, error: 'Неизвестная ошибка');
    }
  }

  /// Login user
  ///
  /// Returns [LoginResponse] with access token on success (200)
  /// Returns error message on failure (400, 401, 500)
  Future<({LoginResponse? response, String? error})> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final response = await _apiService.login(request);

      return (response: response, error: null);
    } on Exception catch (e) {
      return (response: null, error: e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      return (response: null, error: 'Неизвестная ошибка');
    }
  }

  /// Get current user data from backend
  ///
  /// Returns [UserResponse] with user data on success (200)
  /// Returns error message on failure (401, 403, 500)
  Future<({UserResponse? response, String? error})> getCurrentUser() async {
    try {
      // Get access token from storage
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null) {
        return (response: null, error: 'Токен не найден');
      }

      final response = await _apiService.getCurrentUser(accessToken);

      return (response: response, error: null);
    } on Exception catch (e) {
      return (response: null, error: e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      return (response: null, error: 'Неизвестная ошибка');
    }
  }

  /// Обновить профиль текущего пользователя (PUT /users/me)
  Future<({UserResponse? response, String? error})> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null) {
        return (response: null, error: 'Токен не найден');
      }

      final response = await _apiService.updateCurrentUser(
        accessToken,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
      );

      return (response: response, error: null);
    } on Exception catch (e) {
      return (response: null, error: e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      return (response: null, error: 'Неизвестная ошибка');
    }
  }

  /// Загрузить фото профиля (PUT /users/me/photo)
  Future<({bool success, String? error})> uploadProfilePhoto(String filePath) async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null) {
        return (success: false, error: 'Токен не найден');
      }

      await _apiService.uploadProfilePhoto(accessToken, filePath);
      return (success: true, error: null);
    } on Exception catch (e) {
      return (success: false, error: e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      return (success: false, error: 'Неизвестная ошибка');
    }
  }

  /// Удалить фото профиля (DELETE /users/me/photo)
  Future<({bool success, String? error})> deleteProfilePhoto() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null) {
        return (success: false, error: 'Токен не найден');
      }

      await _apiService.deleteProfilePhoto(accessToken);
      return (success: true, error: null);
    } on Exception catch (e) {
      return (success: false, error: e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      return (success: false, error: 'Неизвестная ошибка');
    }
  }

  /// ⬅️ НОВЫЙ МЕТОД: Logout
  Future<void> logout() async {
    await _apiService.logout();
  }
}