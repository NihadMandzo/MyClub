class StadiumSide {
  final int id;
  final String name;

  StadiumSide({
    required this.id,
    required this.name,
  });

  factory StadiumSide.fromJson(Map<String, dynamic> json) {
    return StadiumSide(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
