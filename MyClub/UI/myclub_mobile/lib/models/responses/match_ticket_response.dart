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

class StadiumSectorResponse {
  int id;
  String name;
  String description;
  int capacity;

  StadiumSectorResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.capacity,
  });

  factory StadiumSectorResponse.fromJson(Map<String, dynamic> json) {
    return StadiumSectorResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      capacity: json['capacity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity': capacity,
    };
  }
}
