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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      sideName: json['sideName']?.toString(),
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
