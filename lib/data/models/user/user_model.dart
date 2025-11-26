/// User model representing authenticated user data
class UserModel {
  final String? id;
  final String email;
  final String? firstName;  // Теперь nullable
  final String? lastName;   // Теперь nullable
  final String? phone;
  final String? username;

  UserModel({
    this.id,
    required this.email,
    this.firstName,  // Убрали required
    this.lastName,   // Убрали required
    this.phone,
    this.username,
  });

  /// Create from storage map
  factory UserModel.fromStorage(Map<String, String?> data) {
    return UserModel(
      id: data['userId'],
      email: data['email'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      phone: data['phone'],
      username: data['username'],
    );
  }

  /// Get full name
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}';

  /// Check if user data is complete
  bool get isComplete =>
      email.isNotEmpty &&
          (firstName?.isNotEmpty ?? false) &&
          (lastName?.isNotEmpty ?? false);
}