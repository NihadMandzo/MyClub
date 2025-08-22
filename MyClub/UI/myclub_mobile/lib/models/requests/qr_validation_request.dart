class QRValidationRequest {
  final String qrCodeData;

  QRValidationRequest({
    required this.qrCodeData,
  });

  Map<String, dynamic> toJson() {
    return {
      'qrCodeData': qrCodeData,
    };
  }
}
