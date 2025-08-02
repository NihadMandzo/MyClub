import 'package:myclub_desktop/models/stadium_sector.dart';

class MatchTicket {
  int? id;
  int? matchId;
  StadiumSector? stadiumSector;
  int? releasedQuantity;
  double? price;
  int? availableQuantity;
  int? usedQuantity;

  MatchTicket({this.id, this.matchId, this.stadiumSector,
  this.releasedQuantity, this.availableQuantity, this.price, this.usedQuantity});

  factory MatchTicket.fromJson(Map<String, dynamic> json) {
    return MatchTicket(
      id: json['id'],
      matchId: json['matchId'],
      stadiumSector: json['stadiumSector'] != null
          ? StadiumSector.fromJson(json['stadiumSector'])
          : null,
      releasedQuantity: json['releasedQuantity'],
      availableQuantity: json['availableQuantity'],
      price: json['price'],
      usedQuantity: json['usedQuantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'stadiumSector': stadiumSector?.toJson(),
      'releasedQuantity': releasedQuantity,
      'availableQuantity': availableQuantity,
      'price': price,
      'usedQuantity': usedQuantity,
    };
  }
}
