class PlayerForm {
  String firstName;
  String lastName;
  int number;
  DateTime? dateOfBirth;
  String position;
  int? height;
  int? weight;
  String? biography;
  String nationality;
  dynamic imageUrl; // This can be a file or a string URL
  
  PlayerForm({
    required this.firstName,
    required this.lastName,
    required this.number,
    this.dateOfBirth,
    required this.position,
    this.height,
    this.weight,
    this.biography,
    required this.nationality,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'number': number,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'position': position,
      'height': height,
      'weight': weight,
      'biography': biography,
      'nationality': nationality,
      // imageUrl handling will be done separately for file upload
    };
  }
}
