/// Login request model for /auth/login endpoint
///
/// Request body:
/// {
///   "email": "vlad400@mail.ru",
///   "password": "Test222"
/// }
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}