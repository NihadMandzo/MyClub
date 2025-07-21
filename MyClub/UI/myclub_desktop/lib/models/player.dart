class Player {
  int? id;
  String? fullName;
  String? position;
  int? age;
  String? nationality;
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
      position: json['position'],
      age: json['age'],
      nationality: json['nationality'],
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
      'position': position,
      'age': age,
      'nationality': nationality,
      'imageUrl': imageUrl,
      'height': height,
      'weight': weight,
      'biography': biography,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'number': number,
    };
  }
}
