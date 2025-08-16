import 'package:myclub_mobile/models/responses/country_response.dart';
import 'package:myclub_mobile/models/responses/position_response.dart';

class PlayerResponse {
  final int id;
  final String fullName;
  final PositionResponse position;
  final int age;
  final CountryResponse nationality;
  final String? imageUrl;
  final int height; // Height in centimeters
  final int weight; // Weight in kilograms
  final String? biography;
  final DateTime? dateOfBirth;
  final int number; // Player's jersey number

  PlayerResponse({
    required this.id,
    required this.fullName,
    required this.position,
    required this.age,
    required this.nationality,
    this.imageUrl,
    required this.height,
    required this.weight,
    this.biography,
    this.dateOfBirth,
    required this.number,
  });

  factory PlayerResponse.fromJson(Map<String, dynamic> json) {
    return PlayerResponse(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      position: json['position'] != null ? PositionResponse.fromJson(json['position']) : PositionResponse(id: 0, name: '', isPlayer: false),
      age: json['age'] ?? 0,
      nationality: json['nationality'] != null ? CountryResponse.fromJson(json['nationality']) : CountryResponse(id: 0, name: '', code: ''),
      imageUrl: json['imageUrl'],
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      biography: json['biography'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      number: json['number'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'position': position.toJson(),
      'age': age,
      'nationality': nationality.toJson(),
      'imageUrl': imageUrl,
      'height': height,
      'weight': weight,
      'biography': biography,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'number': number,
    };
  }
}
