class StadiumSide {
  final int id;
  final String name;

  StadiumSide({
    required this.id,
    required this.name,
  });

  factory StadiumSide.fromJson(Map<String, dynamic> json) {
    return StadiumSide(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
