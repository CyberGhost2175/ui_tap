/// User Response from GET /users/me endpoint
class UserResponse {
  final int id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  /// URL аватара пользователя (может быть null)
  final String? photoUrl;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  /// Create from JSON
  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (photoUrl != null) 'photoUrl': photoUrl,
  };

  @override
  String toString() {
    return 'UserResponse(id: $id, username: $username, email: $email, firstName: $firstName, lastName: $lastName, phone: $phoneNumber, photoUrl: $photoUrl)';
  }
}