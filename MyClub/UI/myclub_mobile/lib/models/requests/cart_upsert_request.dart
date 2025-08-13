import 'cart_item_upsert_request.dart';

/// Cart add/update request model
class CartUpsertRequest {
  final int userId;
  final List<CartItemUpsertRequest> items;

  CartUpsertRequest({
    required this.userId,
    this.items = const [],
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Create from JSON response
  factory CartUpsertRequest.fromJson(Map<String, dynamic> json) {
    return CartUpsertRequest(
      userId: json['userId'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItemUpsertRequest.fromJson(item))
              .toList() ??
          [],
    );
  }
}
