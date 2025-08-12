class PlayerResponse {
  final int id;
  final String fullName;
  final String position;
  final int age;
  final String nationality;
  final String? imageUrl;
  final int height; // Height in centimeters
  final int weight; // Weight in kilograms
  final String? biography;
  final DateTime? dateOfBirth;
  final int number; // Player's jersey number

  PlayerResponse({
    required this.id,
    required this.fullName,
    required this.position,
    required this.age,
    required this.nationality,
    this.imageUrl,
    required this.height,
    required this.weight,
    this.biography,
    this.dateOfBirth,
    required this.number,
  });

  factory PlayerResponse.fromJson(Map<String, dynamic> json) {
    return PlayerResponse(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      position: json['position'] ?? '',
      age: json['age'] ?? 0,
      nationality: json['nationality'] ?? '',
      imageUrl: json['imageUrl'],
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      biography: json['biography'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      number: json['number'] ?? 0,
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

  /// Check if this player is coaching staff
  bool get isCoachingStaff {
    final positionLower = position.toLowerCase();
    return positionLower == 'trener' || positionLower == 'stručni štab';
  }

  /// Check if this player is a regular player
  bool get isPlayer {
    return !isCoachingStaff;
  }
}
