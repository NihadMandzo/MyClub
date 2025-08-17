class OrderItemResponse {
  final int id;
  final int orderId;
  final int productSizeId;
  final String productName;
  final String sizeName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItemResponse({
    required this.id,
    required this.orderId,
    required this.productSizeId,
    required this.productName,
    required this.sizeName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      id: json['id'],
      orderId: json['orderId'],
      productSizeId: json['productSizeId'],
      productName: json['productName'] ?? '',
      sizeName: json['sizeName'] ?? '',
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productSizeId': productSizeId,
      'productName': productName,
      'sizeName': sizeName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }
}
