/// Shipping information request model
class ShippingRequest {
  final String? shippingAddress;
  final int cityId;
  final String? shippingPostalCode;

  ShippingRequest({
    this.shippingAddress,
    required this.cityId,
    this.shippingPostalCode,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'shippingAddress': shippingAddress,
      'cityId': cityId,
      'shippingPostalCode': shippingPostalCode,
    };
  }

  /// Create from JSON response
  factory ShippingRequest.fromJson(Map<String, dynamic> json) {
    return ShippingRequest(
      shippingAddress: json['shippingAddress'],
      cityId: json['cityId'] ?? 0,
      shippingPostalCode: json['shippingPostalCode'],
    );
  }
}
