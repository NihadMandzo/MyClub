class UserMembershipCardResponse {
  final int id;
  final String membershipCardName;
  final int year;
  final String userFullName;
  final DateTime joinDate;
  final String membershipNumber;
  final String cardImageUrl;
  final bool isActive;
  final DateTime validUntil;
  final String qrCodeData;

  UserMembershipCardResponse({
    required this.id,
    required this.membershipCardName,
    required this.year,
    required this.userFullName,
    required this.joinDate,
    required this.membershipNumber,
    required this.cardImageUrl,
    required this.isActive,
    required this.validUntil,
    required this.qrCodeData,
  });

  factory UserMembershipCardResponse.fromJson(Map<String, dynamic> json) {
    return UserMembershipCardResponse(
      id: json['id'] ?? 0,
      membershipCardName: json['membershipCardName'] ?? '',
      year: json['year'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      joinDate: json['joinDate'] != null 
          ? DateTime.parse(json['joinDate']) 
          : DateTime.now(),
      membershipNumber: json['membershipNumber'] ?? '',
      cardImageUrl: json['cardImageUrl'] ?? '',
      isActive: json['isActive'] ?? false,
      validUntil: json['validUntil'] != null 
          ? DateTime.parse(json['validUntil']) 
          : DateTime.now(),
      qrCodeData: json['qrCodeData'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'membershipCardName': membershipCardName,
      'year': year,
      'userFullName': userFullName,
      'joinDate': joinDate.toIso8601String(),
      'membershipNumber': membershipNumber,
      'cardImageUrl': cardImageUrl,
      'isActive': isActive,
      'validUntil': validUntil.toIso8601String(),
      'qrCodeData': qrCodeData,
    };
  }

  /// Check if membership card is currently valid
  bool get isValid => isActive && validUntil.isAfter(DateTime.now());

  /// Get formatted join date
  String get formattedJoinDate => "${joinDate.day}.${joinDate.month}.${joinDate.year}.";

  /// Get formatted valid until date
  String get formattedValidUntil => "${validUntil.day}.${validUntil.month}.${validUntil.year}.";
}
