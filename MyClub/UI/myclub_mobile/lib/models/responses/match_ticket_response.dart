import 'package:myclub_mobile/models/responses/stadium_sector_response.dart';

class MatchTicketResponse {
  int id;
  int matchId;
  StadiumSectorResponse? stadiumSector;
  int releasedQuantity;
  double price;
  int availableQuantity;
  int usedQuantity;

  MatchTicketResponse({
    required this.id,
    required this.matchId,
    this.stadiumSector,
    required this.releasedQuantity,
    required this.price,
    required this.availableQuantity,
    required this.usedQuantity,
  });

  factory MatchTicketResponse.fromJson(Map<String, dynamic> json) {
    return MatchTicketResponse(
      id: json['id'] ?? 0,
      matchId: json['matchId'] ?? 0,
      stadiumSector: json['stadiumSector'] != null 
          ? StadiumSectorResponse.fromJson(json['stadiumSector']) 
          : null,
      releasedQuantity: json['releasedQuantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      availableQuantity: json['availableQuantity'] ?? 0,
      usedQuantity: json['usedQuantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'stadiumSector': stadiumSector?.toJson(),
      'releasedQuantity': releasedQuantity,
      'price': price,
      'availableQuantity': availableQuantity,
      'usedQuantity': usedQuantity,
    };
  }
}

