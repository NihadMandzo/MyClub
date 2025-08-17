import 'city_response.dart';
import 'order_item_response.dart';

class OrderResponse {
  final int id;
  final int userId;
  final String userFullName;
  final int? paymentId;
  final DateTime orderDate;
  final String orderState;
  final double totalAmount;
  final double originalAmount;
  final double discountAmount;
  final bool hasMembershipDiscount;
  final String shippingAddress;
  final CityResponse? shippingCity;
  final String paymentMethod;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final String notes;
  final List<OrderItemResponse> orderItems;

  OrderResponse({
    required this.id,
    required this.userId,
    required this.userFullName,
    this.paymentId,
    required this.orderDate,
    required this.orderState,
    required this.totalAmount,
    required this.originalAmount,
    required this.discountAmount,
    required this.hasMembershipDiscount,
    required this.shippingAddress,
    this.shippingCity,
    required this.paymentMethod,
    this.shippedDate,
    this.deliveredDate,
    required this.notes,
    required this.orderItems,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'],
      userId: json['userId'],
      userFullName: json['userFullName'] ?? '',
      paymentId: json['paymentId'],
      orderDate: DateTime.parse(json['orderDate']),
      orderState: json['orderState'] ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      originalAmount: (json['originalAmount'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      hasMembershipDiscount: json['hasMembershipDiscount'] ?? false,
      shippingAddress: json['shippingAddress'] ?? '',
      shippingCity: json['shippingCity'] != null 
          ? CityResponse.fromJson(json['shippingCity'])
          : null,
      paymentMethod: json['paymentMethod'] ?? '',
      shippedDate: json['shippedDate'] != null 
          ? DateTime.parse(json['shippedDate'])
          : null,
      deliveredDate: json['deliveredDate'] != null 
          ? DateTime.parse(json['deliveredDate'])
          : null,
      notes: json['notes'] ?? '',
      orderItems: (json['orderItems'] as List<dynamic>?)
          ?.map((item) => OrderItemResponse.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'paymentId': paymentId,
      'orderDate': orderDate.toIso8601String(),
      'orderState': orderState,
      'totalAmount': totalAmount,
      'originalAmount': originalAmount,
      'discountAmount': discountAmount,
      'hasMembershipDiscount': hasMembershipDiscount,
      'shippingAddress': shippingAddress,
      'shippingCity': shippingCity?.toJson(),
      'paymentMethod': paymentMethod,
      'shippedDate': shippedDate?.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'notes': notes,
      'orderItems': orderItems.map((item) => item.toJson()).toList(),
    };
  }

  /// Formatted order date for display
  String get formattedOrderDate {
    return '${orderDate.day}.${orderDate.month}.${orderDate.year}.';
  }

  /// Formatted shipped date for display
  String get formattedShippedDate {
    if (shippedDate == null) return 'Nije poslano';
    return '${shippedDate!.day}.${shippedDate!.month}.${shippedDate!.year}.';
  }

  /// Formatted delivered date for display
  String get formattedDeliveredDate {
    if (deliveredDate == null) return 'Nije dostavljeno';
    return '${deliveredDate!.day}.${deliveredDate!.month}.${deliveredDate!.year}.';
  }

  /// Check if order is delivered
  bool get isDelivered {
    return orderState.toLowerCase() == 'dostavljeno' || 
           orderState.toLowerCase() == 'delivered' || 
           deliveredDate != null;
  }

  /// Check if order is shipped
  bool get isShipped {
    return orderState.toLowerCase() == 'poslano' || 
           orderState.toLowerCase() == 'shipped' || 
           shippedDate != null || 
           isDelivered;
  }

  /// Check if order is active (not delivered)
  bool get isActive {
    return !isDelivered;
  }

  /// Get status color based on order state
  String get statusColor {
    switch (orderState.toString()) {
      case 'Završeno':
        return 'green';
      case 'Dostava':
        return 'orange';
      case 'Procesiranje':
        return 'blue';
      case 'Potvrđeno':
        return 'cyan';
      case 'Otkazano':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get main product name (first item)
  String get mainProductName {
    if (orderItems.isEmpty) return 'Nepoznat proizvod';
    return orderItems.first.productName;
  }

  /// Get order summary (e.g., "3 proizvoda")
  String get orderSummary {
    if (orderItems.isEmpty) return 'Nema proizvoda';
    
    final totalQuantity = orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
    
    if (totalQuantity == 1) {
      return '1 proizvod';
    } else if (totalQuantity < 5) {
      return '$totalQuantity proizvoda';
    } else {
      return '$totalQuantity proizvoda';
    }
  }
}
