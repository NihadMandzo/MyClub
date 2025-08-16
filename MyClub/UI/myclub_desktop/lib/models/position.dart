class Position {
  final int id;
  final String name;
  final bool isPlayer;

  Position({
    required this.id,
    required this.name,
    required this.isPlayer,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as int,
      name: json['name'] as String,
      isPlayer: json['isPlayer'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPlayer': isPlayer,
    };
  }
}
