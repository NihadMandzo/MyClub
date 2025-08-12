class SizeResponse {
  int id;
  String name;

  SizeResponse({
    required this.id,
    required this.name,
  });

  factory SizeResponse.fromJson(Map<String, dynamic> json) {
    return SizeResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
