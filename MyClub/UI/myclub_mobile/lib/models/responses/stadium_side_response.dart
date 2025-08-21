class StadiumSideResponse {
  int id;
  String name;

  StadiumSideResponse({
    required this.id,
    required this.name,
  });

  factory StadiumSideResponse.fromJson(Map<String, dynamic> json) {
    return StadiumSideResponse(
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
