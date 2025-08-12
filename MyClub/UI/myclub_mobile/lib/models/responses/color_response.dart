class ColorResponse {
  int id;
  String name;
  String hexCode;

  ColorResponse({
    required this.id,
    required this.name,
    required this.hexCode,
  });

  factory ColorResponse.fromJson(Map<String, dynamic> json) {
    return ColorResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      hexCode: json['hexCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hexCode': hexCode,
    };
  }
}
