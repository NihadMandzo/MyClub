/// Order item insert request model
class OrderItemInsertRequest {
  final int productSizeId;
  final int quantity;
  final double unitPrice;

  OrderItemInsertRequest({
    required this.productSizeId,
    required this.quantity,
    required this.unitPrice,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'productSizeId': productSizeId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  /// Create from JSON response
  factory OrderItemInsertRequest.fromJson(Map<String, dynamic> json) {
    return OrderItemInsertRequest(
      productSizeId: json['productSizeId'] ?? 0,
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
    );
  }
}
