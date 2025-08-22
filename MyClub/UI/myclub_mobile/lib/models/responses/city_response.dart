class CityResponse {
  final int id;
  final String name;
  final String? postalCode;
  final int countryId;

  CityResponse({
    required this.id,
    required this.name,
    this.postalCode,
    required this.countryId,
  });

  factory CityResponse.fromJson(Map<String, dynamic> json) {
    return CityResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      postalCode: json['postalCode'],
      countryId: json['country'] != null ? json['country']['id'] ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'postalCode': postalCode,
      'countryId': countryId,
    };
  }
}
