class UserTicketResponse {
  final int id;
  final double totalPrice;
  final DateTime purchaseDate;
  final String qrCodeData;
  final bool isValid;
  // Match Info
  final int matchId;
  final String opponentName;
  final DateTime matchDate;
  final String location;
  // Sector Info
  final String sectorCode;
  final String stadiumSide;

  UserTicketResponse({
    required this.id,
    required this.totalPrice,
    required this.purchaseDate,
    required this.qrCodeData,
    required this.isValid,
    required this.matchId,
    required this.opponentName,
    required this.matchDate,
    required this.location,
    required this.sectorCode,
    required this.stadiumSide,
  });

  factory UserTicketResponse.fromJson(Map<String, dynamic> json) {
    return UserTicketResponse(
      id: json['id'] ?? 0,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] ?? DateTime.now().toIso8601String()),
      qrCodeData: json['qrCodeData'] ?? '',
      isValid: json['isValid'] ?? false,
      matchId: json['matchId'] ?? 0,
      opponentName: json['opponentName'] ?? '',
      matchDate: DateTime.parse(json['matchDate'] ?? DateTime.now().toIso8601String()),
      location: json['location'] ?? '',
      sectorCode: json['sectorCode'] ?? '',
      stadiumSide: json['stadiumSide'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalPrice': totalPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'qrCodeData': qrCodeData,
      'isValid': isValid,
      'matchId': matchId,
      'opponentName': opponentName,
      'matchDate': matchDate.toIso8601String(),
      'location': location,
      'sectorCode': sectorCode,
      'stadiumSide': stadiumSide,
    };
  }

  /// Helper to get formatted match date
  String get formattedMatchDate {
    return '${matchDate.day}.${matchDate.month.toString().padLeft(2, '0')}.${matchDate.year}. ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
  }

  /// Helper to get formatted purchase date
  String get formattedPurchaseDate {
    return '${purchaseDate.day}.${purchaseDate.month.toString().padLeft(2, '0')}.${purchaseDate.year}.';
  }

  /// Helper to get seat info
  String get seatInfo {
    return '$sectorCode, $stadiumSide';
  }
}
