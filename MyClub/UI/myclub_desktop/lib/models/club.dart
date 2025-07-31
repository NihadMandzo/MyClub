class Club {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;

  Club({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  Club copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
