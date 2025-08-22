class QRValidationResponse {
  final bool isValid;
  final String message;

  QRValidationResponse({
    required this.isValid,
    required this.message,
  });

  factory QRValidationResponse.fromJson(Map<String, dynamic> json) {
    return QRValidationResponse(
      isValid: json['isValid'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'message': message,
    };
  }
}
