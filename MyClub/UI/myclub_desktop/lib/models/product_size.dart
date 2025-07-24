import 'package:myclub_desktop/models/size.dart';

class ProductSize {
  final int? quantity;
  final Size? size;

  ProductSize({
    this.quantity,
    this.size,
  });

  // For creating product sizes in the UI
  factory ProductSize.create({int? sizeId, int? quantity}) {
    return ProductSize(
      size: sizeId != null ? Size(id: sizeId) : null,
      quantity: quantity,
    );
  }

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      quantity: json['quantity'],
      size: json['size'] != null ? Size.fromJson(json['size']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'size': size?.toJson(),
    };
  }
}
