import 'package:myclub_desktop/models/position.dart';
import 'package:myclub_desktop/models/country.dart';

class Player {
  int? id;
  String? fullName;
  Position? position;
  int? age;
  Country? nationality;
  String? imageUrl;
  int? height;
  int? weight;
  String? biography;
  DateTime? dateOfBirth;
  int? number;

  Player({
    this.id,
    this.fullName,
    this.position,
    this.age,
    this.nationality,
    this.imageUrl,
    this.height,
    this.weight,
    this.biography,
    this.dateOfBirth,
    this.number,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      fullName: json['fullName'],
      position: json['position'] != null ? Position.fromJson(json['position']) : null,
      age: json['age'],
      nationality: json['nationality'] != null ? Country.fromJson(json['nationality']) : null,
      imageUrl: json['imageUrl'],
      height: json['height'],
      weight: json['weight'],
      biography: json['biography'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      number: json['number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'position': position?.toJson(),
      'age': age,
      'nationality': nationality?.toJson(),
      'imageUrl': imageUrl,
      'height': height,
      'weight': weight,
      'biography': biography,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'number': number,
    };
  }
}
