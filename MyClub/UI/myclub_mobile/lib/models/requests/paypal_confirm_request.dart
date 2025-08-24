class PayPalConfirmRequest {
  String orderId;

  PayPalConfirmRequest({
    required this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
    };
  }

  factory PayPalConfirmRequest.fromJson(Map<String, dynamic> json) {
    return PayPalConfirmRequest(
      orderId: json['orderId'] ?? '',
    );
  }
}
