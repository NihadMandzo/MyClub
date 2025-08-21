import 'package:myclub_desktop/models/stadium_side.dart';

class StadiumSector {
  int id;
  int capacity;
  String code;
  StadiumSide? stadiumSide;

  StadiumSector({
    required this.id,
    required this.capacity,
    required this.code,
    this.stadiumSide,
  });

  // Getter for stadium side name
  String? get sideName => stadiumSide?.name;

  factory StadiumSector.fromJson(Map<String, dynamic> json) {
    return StadiumSector(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      stadiumSide: json['stadiumSide'] != null ? StadiumSide.fromJson(json['stadiumSide']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capacity': capacity,
      'code': code,
      'stadiumSide': stadiumSide?.toJson(),
    };
  }
}
