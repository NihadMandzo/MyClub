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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
      matchId: json['matchId'] is int ? json['matchId'] : int.tryParse(json['matchId']?.toString() ?? '0'),
      stadiumSector: json['stadiumSector'] != null
          ? StadiumSector.fromJson(json['stadiumSector'])
          : null,
      releasedQuantity: json['releasedQuantity'] is int 
          ? json['releasedQuantity'] 
          : int.tryParse(json['releasedQuantity']?.toString() ?? '0'),
      availableQuantity: json['availableQuantity'] is int 
          ? json['availableQuantity'] 
          : int.tryParse(json['availableQuantity']?.toString() ?? '0'),
      price: json['price'] is double 
          ? json['price'] 
          : double.tryParse(json['price']?.toString() ?? '0.0'),
      usedQuantity: json['usedQuantity'] is int 
          ? json['usedQuantity'] 
          : int.tryParse(json['usedQuantity']?.toString() ?? '0') ?? 0,
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
