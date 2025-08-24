/// Abstract base class for payment requests
abstract class PaymentRequest {
  final String type; // "Stripe" or "PayPal"
  final double amount;
  final String? paymentMethod;
  final String? returnUrl; // For PayPal return URL
  final String? cancelUrl; // For PayPal cancel URL

  PaymentRequest({
    required this.type,
    required this.amount,
    this.paymentMethod,
    this.returnUrl,
    this.cancelUrl,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
      'amount': amount,
    };
    
    if (paymentMethod != null) {
      json['paymentMethod'] = paymentMethod!;
    }
    if (returnUrl != null) {
      json['returnUrl'] = returnUrl!;
    }
    if (cancelUrl != null) {
      json['cancelUrl'] = cancelUrl!;
    }
    
    return json;
  }
}
