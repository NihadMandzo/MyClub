class ClubResponse {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final DateTime? establishedDate;
  final String? stadiumName;
  final String? stadiumLocation;
  final int? numberOfTitles;


  ClubResponse({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.establishedDate,
    this.stadiumName,
    this.stadiumLocation,
    this.numberOfTitles,
  });

  factory ClubResponse.fromJson(Map<String, dynamic> json) {
    return ClubResponse(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      establishedDate: json['establishedDate'] != null
          ? DateTime.parse(json['establishedDate'])
          : null,
      stadiumName: json['stadiumName'],
      stadiumLocation: json['stadiumLocation'],
      numberOfTitles: json['numberOfTitles'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'establishedDate': establishedDate?.toIso8601String(),
      'stadiumName': stadiumName,
      'stadiumLocation': stadiumLocation,
      'numberOfTitles': numberOfTitles,
    };
  }

  ClubResponse copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    DateTime? establishedDate,
    String? stadiumName,
    String? stadiumLocation,
    int? numberOfTitles,
  }) {
    return ClubResponse(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      establishedDate: establishedDate ?? this.establishedDate,
      stadiumName: stadiumName ?? this.stadiumName,
      stadiumLocation: stadiumLocation ?? this.stadiumLocation,
      numberOfTitles: numberOfTitles ?? this.numberOfTitles,
    );
  }
}
