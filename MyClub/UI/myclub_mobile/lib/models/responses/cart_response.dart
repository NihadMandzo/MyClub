import 'cart_item_response.dart';

/// Cart response model
class CartResponse {
  final int id;
  final int userId;
  final String userFullName;
  final List<CartItemResponse> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double totalAmount;
  final bool hasActiveMembership;
  final double membershipDiscount;
  final double finalAmount;

  CartResponse({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.items,
    required this.createdAt,
    this.updatedAt,
    required this.totalAmount,
    this.hasActiveMembership = false,
    this.membershipDiscount = 0.0,
    double? finalAmount,
  }) : finalAmount = finalAmount ?? totalAmount;

  /// Create from JSON response
  factory CartResponse.fromJson(Map<String, dynamic> json) {
    final totalAmount = (json['totalAmount'] ?? 0.0).toDouble();
    final hasActiveMembership = json['hasActiveMembership'] == true;
    final membershipDiscount = hasActiveMembership ? totalAmount * 0.20 : 0.0;
    final finalAmount = totalAmount - membershipDiscount;

    return CartResponse(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItemResponse.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      totalAmount: totalAmount,
      hasActiveMembership: hasActiveMembership,
      membershipDiscount: membershipDiscount,
      finalAmount: finalAmount,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'totalAmount': totalAmount,
      'hasActiveMembership': hasActiveMembership,
      'membershipDiscount': membershipDiscount,
      'finalAmount': finalAmount,
    };
  }

  /// Get total items count
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => items.isNotEmpty;
}
