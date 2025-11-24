/// Login response model for /auth/login endpoint
///
/// Response (200):
/// {
///   "accessToken": "eyJhbG...",
///   "expiresIn": 900,
///   "tokenType": "Bearer"
/// }
class LoginResponse {
  final String accessToken;
  final int expiresIn; // in seconds (900 = 15 minutes)
  final String tokenType;

  LoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  /// Create from JSON response
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      expiresIn: json['expiresIn'] as int,
      tokenType: json['tokenType'] as String,
    );
  }

  /// Convert to JSON (for debugging/storage)
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresIn': expiresIn,
    'tokenType': tokenType,
  };
}