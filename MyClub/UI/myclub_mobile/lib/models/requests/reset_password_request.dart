class ResetPasswordRequest {
  final String username;
  final String resetCode;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.username,
    required this.resetCode,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'resetCode': resetCode,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}
