/// Request model for confirming an order after payment
class ConfirmOrderRequest {
  final String transactionId;

  ConfirmOrderRequest({
    required this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
    };
  }

  factory ConfirmOrderRequest.fromJson(Map<String, dynamic> json) {
    return ConfirmOrderRequest(
      transactionId: json['transactionId'] as String,
    );
  }
}
