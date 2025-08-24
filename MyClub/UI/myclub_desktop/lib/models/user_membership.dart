import 'package:intl/intl.dart';
import 'package:myclub_desktop/models/city.dart';
import 'package:myclub_desktop/models/country.dart';

class UserMembership {
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
  final String? recipientFullName;
  final String? recipientEmail;
  final String? shippingAddress;
  final City? shippingCity;
  final String? paymentMethod;
  final DateTime? shippedDate;
  final bool isShipped;
  final double paymentAmount;
  final bool isPaid;
  final DateTime? paymentDate;

  const UserMembership({
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
    this.recipientFullName,
    this.recipientEmail,
    this.shippingAddress,
  this.shippingCity,
  this.paymentMethod,
    this.shippedDate,
    required this.isShipped,
    required this.paymentAmount,
    required this.isPaid,
    this.paymentDate,
  });

  factory UserMembership.fromJson(Map<String, dynamic> json) {
    return UserMembership(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      membershipCardId: json['membershipCardId'] as int,
      membershipName: json['membershipName'] as String,
      year: json['year'] as int,
      joinDate: DateTime.parse(json['joinDate'] as String),
      isRenewal: json['isRenewal'] as bool,
      previousMembershipId: json['previousMembershipId'] as int?,
      physicalCardRequested: json['physicalCardRequested'] as bool,
      recipientFullName: json['recipientFullName'] as String?,
      recipientEmail: json['recipientEmail'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      shippingCity: (() {
        final sc = json['shippingCity'] as Map<String, dynamic>?;
        if (sc == null) return null;
        final countryJson = sc['country'] as Map<String, dynamic>?;
        final country = countryJson != null
            ? Country.fromJson(countryJson)
            : Country(id: 0, name: '', code: '');
        return City(
          id: (sc['id'] as int?) ?? 0,
          name: (sc['name'] as String?) ?? '',
          postalCode: (sc['postalCode'] as String?) ?? '',
          country: country,
        );
      })(),
      paymentMethod: json['paymentMethod'] as String?,
      shippedDate: json['shippedDate'] != null
          ? DateTime.parse(json['shippedDate'] as String)
          : null,
      isShipped: json['isShipped'] as bool,
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      isPaid: json['isPaid'] as bool,
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'] as String)
          : null,
    );
  }

  String get formattedJoinDate => DateFormat('MMM dd, yyyy').format(joinDate);
  String get formattedShippedDate =>
      shippedDate != null ? DateFormat('MMM dd, yyyy').format(shippedDate!) : '-';
  String get paymentAmountText => '\$${paymentAmount.toStringAsFixed(2)}';
}
