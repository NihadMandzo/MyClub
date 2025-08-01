class MatchTicket {
  int? id;
  int? matchId;
  int? stadiumSectorId;
  String? sectorName;
  String? sideName;
  int? totalQuantity;
  int? availableQuantity;
  double? price;
  bool? isActive;

  MatchTicket({this.id, this.matchId, this.stadiumSectorId,
  this.sectorName, this.sideName, this.totalQuantity,
  this.availableQuantity, this.price, this.isActive});

  factory MatchTicket.fromJson(Map<String, dynamic> json) {
    return MatchTicket(
      id: json['id'],
      matchId: json['matchId'],
      stadiumSectorId: json['stadiumSectorId'],
      sectorName: json['sectorName'],
      sideName: json['sideName'],
      totalQuantity: json['totalQuantity'],
      availableQuantity: json['availableQuantity'],
      price: json['price'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'stadiumSectorId': stadiumSectorId,
      'sectorName': sectorName,
      'sideName': sideName,
      'totalQuantity': totalQuantity,
      'availableQuantity': availableQuantity,
      'price': price,
      'isActive': isActive,
    };
  }
}
