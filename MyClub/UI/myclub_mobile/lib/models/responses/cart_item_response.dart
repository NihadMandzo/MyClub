/// Cart item response model
class CartItemResponse {
  final int id;
  final int cartId;
  final int productSizeId;
  final String productName;
  final String sizeName;
  final double price;
  final String imageUrl;
  final int quantity;
  final DateTime addedAt;
  final double subtotal;

  CartItemResponse({
    required this.id,
    required this.cartId,
    required this.productSizeId,
    required this.productName,
    required this.sizeName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.addedAt,
    required this.subtotal,
  });

  /// Create from JSON response
  factory CartItemResponse.fromJson(Map<String, dynamic> json) {
    return CartItemResponse(
      id: json['id'] ?? 0,
      cartId: json['cartId'] ?? 0,
      productSizeId: json['productSizeId'] ?? 0,
      productName: json['productName'] ?? '',
      sizeName: json['sizeName'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      quantity: json['quantity'] ?? 0,
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'productSizeId': productSizeId,
      'productName': productName,
      'sizeName': sizeName,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'subtotal': subtotal,
    };
  }
}
