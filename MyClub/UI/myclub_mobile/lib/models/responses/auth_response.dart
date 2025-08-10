class AuthResponse {
  final int userId;
  final String token;
  final int roleId;
  final String roleName;

  AuthResponse({
    required this.userId,
    required this.token,
    required this.roleId,
    required this.roleName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'],
      token: json['token'],
      roleId: json['roleId'],
      roleName: json['roleName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'token': token,
      'roleId': roleId,
      'roleName': roleName,
    };
  }
}
