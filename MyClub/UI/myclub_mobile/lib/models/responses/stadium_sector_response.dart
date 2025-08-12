
class StadiumSectorResponse {
  int id;
  String code;
  String sideName;
  int capacity;

  StadiumSectorResponse({
    required this.id,
    required this.code,
    required this.sideName,
    required this.capacity,
  });

  factory StadiumSectorResponse.fromJson(Map<String, dynamic> json) {
    return StadiumSectorResponse(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      sideName: json['sideName'] ?? '',
      capacity: json['capacity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'sideName': sideName,
      'capacity': capacity,
    };
  }
}
