/// Cart item add/update request model
class CartItemUpsertRequest {
  final int productSizeId;
  final int quantity;

  CartItemUpsertRequest({
    required this.productSizeId,
    this.quantity = 1,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'productSizeId': productSizeId,
      'quantity': quantity,
    };
  }

  /// Create from JSON response
  factory CartItemUpsertRequest.fromJson(Map<String, dynamic> json) {
    return CartItemUpsertRequest(
      productSizeId: json['productSizeId'] ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }
}
