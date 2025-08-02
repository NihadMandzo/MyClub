class StadiumSector {
  int id;
  int capacity;
  String code;
  String? sideName;

  StadiumSector({
    required this.id,
    required this.capacity,
    required this.code,
    this.sideName,
  });

  factory StadiumSector.fromJson(Map<String, dynamic> json) {
    return StadiumSector(
      id: json['id'],
      capacity: json['capacity'],
      code: json['code'],
      sideName: json['sideName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capacity': capacity,
      'code': code,
      'sideName': sideName,
    };
  }
}
