/// Payment response model
class PaymentResponse {
  final String transactionId;
  final String? clientSecret;
  final String? approvalUrl; // For PayPal approval redirect

  PaymentResponse({
    required this.transactionId,
    this.clientSecret,
    this.approvalUrl,
  });

  /// Create from JSON response
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      transactionId: json['transactionId'] ?? '',
      clientSecret: json['clientSecret'],
      approvalUrl: json['approvalUrl'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'clientSecret': clientSecret,
      'approvalUrl': approvalUrl,
    };
  }
}
