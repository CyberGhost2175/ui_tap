import 'dart:convert';

/// JWT Token Decoder
/// Extracts user data from JWT access token
class JwtDecoder {
  /// Decode JWT token and extract payload
  ///
  /// JWT format: header.payload.signature
  /// We only need the payload (middle part)
  static Map<String, dynamic>? decode(String token) {
    try {
      // Split token into parts
      final parts = token.split('.');

      if (parts.length != 3) {
        print('❌ Invalid JWT token format');
        return null;
      }

      // Get payload (second part)
      final payload = parts[1];

      // Base64 decode
      // JWT uses base64Url encoding, so we need to normalize it
      String normalized = base64.normalize(payload);

      // Decode
      final decoded = utf8.decode(base64.decode(normalized));

      // Parse JSON
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      print('✅ JWT decoded successfully');
      print('Payload: $payloadMap');

      return payloadMap;
    } catch (e) {
      print('❌ Error decoding JWT: $e');
      return null;
    }
  }

  /// Extract user data from JWT payload
  ///
  /// Returns a map with user information:
  /// - email
  /// - firstName (from given_name)
  /// - lastName (from family_name)
  /// - username (from preferred_username)
  static Map<String, String?> extractUserData(String token) {
    final payload = decode(token);

    if (payload == null) {
      return {
        'email': null,
        'firstName': null,
        'lastName': null,
        'username': null,
      };
    }

    // Extract fields from Keycloak JWT
    // Keycloak uses these field names:
    // - email: "email"
    // - given_name: "Akhan"
    // - family_name: "Dulatbay"
    // - preferred_username: "akhan228@mail.ru"
    // - name: "Akhan Dulatbay" (full name)

    return {
      'email': payload['email'] as String?,
      'firstName': payload['given_name'] as String?,
      'lastName': payload['family_name'] as String?,
      'username': payload['preferred_username'] as String?,
      'fullName': payload['name'] as String?,
    };
  }

  /// Check if token is expired
  ///
  /// JWT contains 'exp' field with expiration timestamp
  static bool isTokenExpired(String token) {
    final payload = decode(token);

    if (payload == null || payload['exp'] == null) {
      return true;
    }

    final exp = payload['exp'] as int;
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();

    return now.isAfter(expirationDate);
  }

  /// Get token expiration time
  static DateTime? getExpirationTime(String token) {
    final payload = decode(token);

    if (payload == null || payload['exp'] == null) {
      return null;
    }

    final exp = payload['exp'] as int;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }
}