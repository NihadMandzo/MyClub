/// Abstract base class for payment requests
abstract class PaymentRequest {
  final String type; // "Stripe" or "PayPal"
  final double amount;
  final String? paymentMethod;

  PaymentRequest({
    required this.type,
    required this.amount,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'paymentMethod': paymentMethod,
    };
  }
}
