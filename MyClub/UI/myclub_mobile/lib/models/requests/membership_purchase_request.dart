import 'package:myclub_mobile/models/requests/payment_request.dart';
import 'package:myclub_mobile/models/requests/shipping_request.dart';

/// Request model for purchasing membership cards
class MembershipPurchaseRequest extends PaymentRequest {
  final int membershipCardId;
  
  // Gift purchase fields (optional)
  final String? recipientFirstName;
  final String? recipientLastName;
  
  // Physical card delivery
  final bool physicalCardRequested;
  
  // Shipping details (required if physicalCardRequested is true)
  final ShippingRequest? shipping;

  MembershipPurchaseRequest({
    required this.membershipCardId,
    required String type,
    required double amount,
    String? paymentMethod,
    this.recipientFirstName,
    this.recipientLastName,
    this.physicalCardRequested = false,
    this.shipping,
  }) : super(type: type, amount: amount, paymentMethod: paymentMethod);

  @override
  Map<String, dynamic> toJson() {
    return {
      'membershipCardId': membershipCardId,
      'type': type,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'recipientFirstName': recipientFirstName,
      'recipientLastName': recipientLastName,
      'physicalCardRequested': physicalCardRequested,
      'shipping': shipping?.toJson(),
    };
  }

  factory MembershipPurchaseRequest.fromJson(Map<String, dynamic> json) {
    return MembershipPurchaseRequest(
      membershipCardId: json['membershipCardId'] ?? 0,
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'],
      recipientFirstName: json['recipientFirstName'],
      recipientLastName: json['recipientLastName'],
      physicalCardRequested: json['physicalCardRequested'] ?? false,
      shipping: json['shipping'] != null 
          ? ShippingRequest.fromJson(json['shipping']) 
          : null,
    );
  }

  /// Validate if shipping is required and provided
  bool get isShippingValid {
    if (!physicalCardRequested) return true;
    return shipping != null;
  }

  /// Check if this is a gift purchase
  bool get isGiftPurchase {
    return recipientFirstName != null && recipientFirstName!.isNotEmpty ||
           recipientLastName != null && recipientLastName!.isNotEmpty;
  }
}
