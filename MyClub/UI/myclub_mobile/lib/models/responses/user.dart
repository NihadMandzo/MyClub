class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? token;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
    this.token,
  });

  /// Helper property for display purposes
  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'token': token,
    };
  }
}
