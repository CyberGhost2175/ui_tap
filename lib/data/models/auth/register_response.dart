/// Model for registration response
///
/// API returns:
/// {
///   "accessToken": "string",
///   "expiresIn": 0,
///   "tokenType": "string"
/// }
class RegisterResponse {
  final String accessToken;
  final int expiresIn;
  final String tokenType;

  RegisterResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  /// Parse from JSON response
  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      accessToken: json['accessToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      tokenType: json['tokenType'] ?? 'Bearer',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'expiresIn': expiresIn,
      'tokenType': tokenType,
    };
  }

  /// Get full authorization header value
  String get authorizationHeader => '$tokenType $accessToken';
}