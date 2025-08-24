class PayPalCheckResponse {
  String orderId;
  String status;

  PayPalCheckResponse({
    required this.orderId,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'status': status,
    };
  }

  factory PayPalCheckResponse.fromJson(Map<String, dynamic> json) {
    return PayPalCheckResponse(
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? '',
    );
  }

  bool get isApproved => status == 'APPROVED';
}
