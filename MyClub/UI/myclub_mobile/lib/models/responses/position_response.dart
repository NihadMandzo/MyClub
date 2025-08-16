class PositionResponse {
  int id;
  String name;
  bool isPlayer;

  PositionResponse({
    required this.id,
    required this.name,
    required this.isPlayer,
  });

  factory PositionResponse.fromJson(Map<String, dynamic> json) {
    return PositionResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isPlayer: json['isPlayer'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPlayer': isPlayer,
    };
  }
}
