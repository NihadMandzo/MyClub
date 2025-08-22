/// Payment response model
class PaymentResponse {
  final String transactionId;
  final String? clientSecret;
  final String? paymentUrl;

  PaymentResponse({
    required this.transactionId,
    this.clientSecret,
    this.paymentUrl,
  });

  /// Create from JSON response
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      transactionId: json['transactionId'] ?? '',
      clientSecret: json['clientSecret'],
      paymentUrl: json['paymentUrl'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'clientSecret': clientSecret,
      'paymentUrl': paymentUrl,
    };
  }
}
