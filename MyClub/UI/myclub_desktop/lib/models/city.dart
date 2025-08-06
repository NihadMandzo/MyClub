import 'package:myclub_desktop/models/country.dart';

class City {
  final int id;
  final String name;
  final String postalCode;
  final Country country;

  City({
    required this.id,
    required this.name,
    required this.postalCode,
    required this.country,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
      postalCode: json['postalCode'] as String,
      country: Country.fromJson(json['country'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'postalCode': postalCode,
      'country': country.toJson(),
    };
  }
}
