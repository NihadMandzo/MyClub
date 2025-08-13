import 'size_response.dart';

class ProductSizeResponse {
  int productSizeId;
  int quantity;
  SizeResponse size;

  ProductSizeResponse({
    required this.productSizeId,
    required this.quantity,
    required this.size,
  });

  factory ProductSizeResponse.fromJson(Map<String, dynamic> json) {
    return ProductSizeResponse(
      productSizeId: json['productSizeId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      size: SizeResponse.fromJson(json['size'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productSizeId': productSizeId,
      'quantity': quantity,
      'size': size.toJson(),
    };
  }
}
