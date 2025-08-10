/// User registration/update request model
class UserUpsertRequest {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final bool isActive;
  final String? password;
  final int? roleId;

  UserUpsertRequest({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.isActive = true,
    this.password,
    this.roleId,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'isActive': isActive,
      if (password != null) 'password': password,
      if (roleId != null) 'roleId': roleId,
    };
  }

  /// Create from JSON response
  factory UserUpsertRequest.fromJson(Map<String, dynamic> json) {
    return UserUpsertRequest(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      isActive: json['isActive'] ?? true,
      password: json['password'],
      roleId: json['roleId'],
    );
  }
}
