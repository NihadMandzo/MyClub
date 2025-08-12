import 'size_response.dart';

class ProductSizeResponse {
  int quantity;
  SizeResponse size;

  ProductSizeResponse({
    required this.quantity,
    required this.size,
  });

  factory ProductSizeResponse.fromJson(Map<String, dynamic> json) {
    return ProductSizeResponse(
      quantity: json['quantity'] ?? 0,
      size: SizeResponse.fromJson(json['size'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'size': size.toJson(),
    };
  }
}
