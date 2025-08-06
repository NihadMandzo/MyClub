import 'package:myclub_desktop/models/order_item.dart';

class Order {
  final int id;
  final String? orderNumber;
  final int userId;
  final String userFullName;
  final int? paymentId;
  final DateTime orderDate;
  final String orderState;
  final double totalAmount;
  final double originalAmount;
  final double discountAmount;
  final bool hasMembershipDiscount;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingPostalCode;
  final String? shippingCountry;
  final String paymentMethod;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final String? notes;
  final List<OrderItem> orderItems;

  Order({
    required this.id,
    this.orderNumber,
    required this.userId,
    required this.userFullName,
    this.paymentId,
    required this.orderDate,
    required this.orderState,
    required this.totalAmount,
    required this.originalAmount,
    required this.discountAmount,
    required this.hasMembershipDiscount,
    this.shippingAddress,
    this.shippingCity,
    this.shippingPostalCode,
    this.shippingCountry,
    required this.paymentMethod,
    this.shippedDate,
    this.deliveredDate,
    this.notes,
    required this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderNumber: json['orderNumber'] as String?,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      paymentId: json['paymentId'] as int?,
      orderDate: DateTime.parse(json['orderDate'] as String),
      orderState: json['orderState'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      originalAmount: (json['originalAmount'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      hasMembershipDiscount: json['hasMembershipDiscount'] as bool,
      shippingAddress: json['shippingAddress'] as String?,
      shippingCity: json['shippingCity'] as String?,
      shippingPostalCode: json['shippingPostalCode'] as String?,
      shippingCountry: json['shippingCountry'] as String?,
      paymentMethod: json['paymentMethod'] as String,
      shippedDate: json['shippedDate'] != null 
          ? DateTime.parse(json['shippedDate'] as String) 
          : null,
      deliveredDate: json['deliveredDate'] != null 
          ? DateTime.parse(json['deliveredDate'] as String) 
          : null,
      notes: json['notes'] as String?,
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
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
      'shippingCity': shippingCity,
      'shippingPostalCode': shippingPostalCode,
      'shippingCountry': shippingCountry,
      'paymentMethod': paymentMethod,
      'shippedDate': shippedDate?.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'notes': notes,
      'orderItems': orderItems.map((e) => e.toJson()).toList(),
    };
  }
}

