class OrderItem {
  final int id;
  final int orderId;
  final int productSizeId;
  final String productName;
  final String sizeName;
  final int quantity;
  final double unitPrice;
  final double? discount;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productSizeId,
    required this.productName,
    required this.sizeName,
    required this.quantity,
    required this.unitPrice,
    this.discount,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      productSizeId: json['productSizeId'] as int,
      productName: json['productName'] as String,
      sizeName: json['sizeName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discount: json['discount'] != null 
          ? (json['discount'] as num).toDouble() 
          : null,
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
      'discount': discount,
      'subtotal': subtotal,
    };
  }
}
