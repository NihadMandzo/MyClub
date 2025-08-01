class MembershipCard {
  final int id;
  final int year;
  final String name;
  final String? description;
  final int totalMembers;
  final int targetMembers;
  final double price;
  final DateTime startDate;
  final DateTime? endDate;
  final String? benefits;
  final String? imageUrl;
  final bool isActive;
  final bool isCurrent;
  final double progressPercentage;

  MembershipCard({
    required this.id,
    required this.year,
    required this.name,
    this.description,
    required this.totalMembers,
    required this.targetMembers,
    required this.price,
    required this.startDate,
    this.endDate,
    this.benefits,
    this.imageUrl,
    required this.isActive,
    required this.isCurrent,
    required this.progressPercentage,
  });

  factory MembershipCard.fromJson(Map<String, dynamic> json) {
    return MembershipCard(
      id: json['id'],
      year: json['year'],
      name: json['name'],
      description: json['description'],
      totalMembers: json['totalMembers'],
      targetMembers: json['targetMembers'],
      price: json['price']?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      benefits: json['benefits'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'],
      isCurrent: json['isCurrent'],
      progressPercentage: json['progressPercentage']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'name': name,
      'description': description,
      'totalMembers': totalMembers,
      'targetMembers': targetMembers,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'benefits': benefits,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isCurrent': isCurrent,
      'progressPercentage': progressPercentage,
    };
  }
}

class MembershipCardForm {
  final int? year;        // [Required]
  final String? name;     // [Required], [MaxLength(100)]
  final String? description;
  final int? targetMembers; // [Required]
  final double? price;    // [Required], [Range(0.01, double.MaxValue)]
  final DateTime? startDate; // [Required]
  final DateTime? endDate;
  final String? benefits;
  final dynamic image;    // IFormFile in backend
  final bool? keepImage;  // Default: false
  final bool? isActive;   // Default: true

  MembershipCardForm({
    this.year,
    this.name,
    this.description,
    this.targetMembers,
    this.price,
    this.startDate,
    this.endDate,
    this.benefits,
    this.image,
    this.isActive = true,
    this.keepImage = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'name': name,
      'description': description,
      'targetMembers': targetMembers,
      'price': price,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'benefits': benefits,
      'isActive': isActive ?? true,
      'image': image, // This can be a file or a string URL
      'keepImage': keepImage ?? false, // Indicate if the image should be kept
      // image handling will be done separately for file upload
    };
  }
}
