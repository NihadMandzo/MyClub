import 'package:myclub_mobile/models/requests/payment_request.dart';

class TicketPurchaseRequest extends PaymentRequest {
  int matchTicketId;

  // Payment method ID for Stripe or null for PayPal

  TicketPurchaseRequest({
    required this.matchTicketId,
    required String type,
    required double amount,
    String? paymentMethod,
  }) : super(type: type, amount: amount, paymentMethod: paymentMethod);

  Map<String, dynamic> toJson() {
    return {
      'matchTicketId': matchTicketId,
      'type': type,
      'amount': amount,
      'paymentMethod': paymentMethod,
    };
  }

  factory TicketPurchaseRequest.fromJson(Map<String, dynamic> json) {
    return TicketPurchaseRequest(
      matchTicketId: json['matchTicketId'] ?? 0,
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'],
    );
  }
}
