/// API configuration constants
class ApiConstants {
  // 🌍 ENVIRONMENT CONFIGURATION
  // Change this to switch between environments
  static const Environment currentEnvironment = Environment.production;

  // Base URLs
  static const String _localBaseUrl = 'http://10.0.2.2:8080/api'; // Android Emulator
  static const String _localIosBaseUrl = 'http://localhost:8080/api'; // iOS Simulator

  // Production URLs
  // ⚠️ USING IP ADDRESS because domain 'inlive-hotel.kz' has DNS issues!
  static const String _prodBaseUrl = 'http://63.178.189.113:8888/api'; // Production IP (from Swagger)

  // Alternative: Use domain when DNS is fixed
  // static const String _prodBaseUrl = 'https://inlive-hotel.kz/api';

  // Get current base URL based on environment and platform
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.local:
      // For iOS simulator, use localhost; for Android, use 10.0.2.2
      // You can detect platform here if needed
        return _localBaseUrl; // or _localIosBaseUrl for iOS
      case Environment.production:
        return _prodBaseUrl;
    }
  }

  // Auth endpoints
  static const String registerEndpoint = '/auth/client/register';
  static const String loginEndpoint = '/auth/login'; // ✅ БЕЗ /client!

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
  local,      // http://localhost:8080/api (development)
  production, // https://inlive-hotel.kz/api (production)
}