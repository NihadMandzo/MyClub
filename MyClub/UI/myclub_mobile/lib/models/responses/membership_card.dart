class MembershipCard {
  final int? id;
  final int year;
  final String name;
  final String? description;
  final int targetMembers;
  final double price;
  final DateTime startDate;
  final DateTime? endDate;
  final String? benefits;
  final String? imageUrl;
  final bool isActive;
  final int? totalMembers;

  MembershipCard({
    this.id,
    required this.year,
    required this.name,
    this.description,
    required this.targetMembers,
    required this.price,
    required this.startDate,
    this.endDate,
    this.benefits,
    this.imageUrl,
    this.isActive = true,
    this.totalMembers,
  });

  factory MembershipCard.fromJson(Map<String, dynamic> json) {
    return MembershipCard(
      id: json['id'],
      year: json['year'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      targetMembers: json['targetMembers'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      benefits: json['benefits'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      totalMembers: json['totalMembers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'name': name,
      'description': description,
      'targetMembers': targetMembers,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'benefits': benefits,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'totalMembers': totalMembers,
    };
  }

  double get membershipProgress {
    if (totalMembers == null || targetMembers == 0) return 0.0;
    return (totalMembers! / targetMembers).clamp(0.0, 1.0);
  }

  String get progressText {
    if (totalMembers == null) return '0 / $targetMembers';
    return '$totalMembers / $targetMembers';
  }
}
