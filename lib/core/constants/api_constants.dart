/// API configuration constants
class ApiConstants {
  // 🌍 ENVIRONMENT CONFIGURATION
  static const Environment currentEnvironment = Environment.production;

  // Base URLs
  static const String _localBaseUrl = 'http://10.0.2.2:8080/api';
  static const String _localIosBaseUrl = 'http://localhost:8080/api';
  static const String _prodBaseUrl = 'http://63.178.189.113:8888/api';

  // Get current base URL based on environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.local:
        return _localBaseUrl;
      case Environment.production:
        return _prodBaseUrl;
    }
  }

  // Auth endpoints
  static const String registerEndpoint = '/auth/client/register';
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh'; // ⬅️ НОВОЕ

  // User endpoints
  static const String currentUserEndpoint = '/users/me';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
  };

  // Helper to get full URL
  static String getUrl(String endpoint) => baseUrl + endpoint;
}

/// Environment enum
enum Environment {
  local,
  production,
}