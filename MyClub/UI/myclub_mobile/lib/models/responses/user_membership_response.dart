class UserMembershipResponse {
  final int id;
  final int userId;
  final String userFullName;
  final int membershipCardId;
  final String membershipName;
  final int year;
  final DateTime joinDate;
  final bool isRenewal;
  final int? previousMembershipId;
  final bool physicalCardRequested;
  final String recipientFullName;
  final String recipientEmail;
  final String? shippingAddress;
  final String paymentMethod;
  final DateTime? shippedDate;
  final bool isShipped;
  final double paymentAmount;

  UserMembershipResponse({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.membershipCardId,
    required this.membershipName,
    required this.year,
    required this.joinDate,
    required this.isRenewal,
    this.previousMembershipId,
    required this.physicalCardRequested,
    required this.recipientFullName,
    required this.recipientEmail,
    this.shippingAddress,
    required this.paymentMethod,
    this.shippedDate,
    required this.isShipped,
    required this.paymentAmount,
  });

  factory UserMembershipResponse.fromJson(Map<String, dynamic> json) {
    return UserMembershipResponse(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      membershipCardId: json['membershipCardId'] ?? 0,
      membershipName: json['membershipName'] ?? '',
      year: json['year'] ?? 0,
      joinDate: json['joinDate'] != null 
          ? DateTime.parse(json['joinDate']) 
          : DateTime.now(),
      isRenewal: json['isRenewal'] ?? false,
      previousMembershipId: json['previousMembershipId'],
      physicalCardRequested: json['physicalCardRequested'] ?? false,
      recipientFullName: json['recipientFullName'] ?? '',
      recipientEmail: json['recipientEmail'] ?? '',
      shippingAddress: json['shippingAddress'],
      paymentMethod: json['paymentMethod'] ?? '',
      shippedDate: json['shippedDate'] != null 
          ? DateTime.parse(json['shippedDate']) 
          : null,
      isShipped: json['isShipped'] ?? false,
      paymentAmount: (json['paymentAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'membershipCardId': membershipCardId,
      'membershipName': membershipName,
      'year': year,
      'joinDate': joinDate.toIso8601String(),
      'isRenewal': isRenewal,
      'previousMembershipId': previousMembershipId,
      'physicalCardRequested': physicalCardRequested,
      'recipientFullName': recipientFullName,
      'recipientEmail': recipientEmail,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'shippedDate': shippedDate?.toIso8601String(),
      'isShipped': isShipped,
      'paymentAmount': paymentAmount,
    };
  }
}
