/// Register response model for /auth/client/register endpoint
///
/// Response (201):
/// {
///   "accessToken": "eyJhbG...",
///   "refreshToken": "eyJhbG...",  // 30-day token
///   "expiresIn": 900,
///   "tokenType": "Bearer"
/// }
class RegisterResponse {
  final String accessToken;
  final String refreshToken; // ⬅️ НОВОЕ: 30-дневный refresh token
  final int expiresIn; // in seconds (900 = 15 minutes)
  final String tokenType;

  RegisterResponse({
    required this.accessToken,
    required this.refreshToken, // ⬅️ ОБЯЗАТЕЛЬНОЕ ПОЛЕ
    required this.expiresIn,
    required this.tokenType,
  });

  /// Create from JSON response
  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String, // ⬅️ Парсим refreshToken
      expiresIn: json['expiresIn'] as int,
      tokenType: json['tokenType'] as String,
    );
  }

  /// Convert to JSON (for debugging/storage)
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'tokenType': tokenType,
  };

  @override
  String toString() {
    return 'RegisterResponse(accessToken: ${accessToken.substring(0, 20)}..., '
        'refreshToken: ${refreshToken.substring(0, 20)}..., '
        'expiresIn: $expiresIn, tokenType: $tokenType)';
  }
}