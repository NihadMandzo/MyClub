class ForgotPasswordRequest {
  final String username;

  ForgotPasswordRequest({
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
    };
  }
}
