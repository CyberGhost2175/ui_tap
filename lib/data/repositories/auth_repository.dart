import '../models/auth/register_request.dart';
import '../models/auth/register_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../services/auth_api_service.dart';

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
        phoneNumber: phoneNumber,
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

  /// Save access token to local storage
  /// Call this after successful registration
  Future<void> saveAccessToken(String token) async {
    // TODO: Implement token storage using SharedPreferences or FlutterSecureStorage
    // Example:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('access_token', token);
  }
}