import 'asset_response.dart';
import 'category_response.dart';
import 'color_response.dart';
import 'product_size_response.dart';

class ProductResponse {
  int id;
  String name;
  String description;
  String barCode;
  double price;
  ColorResponse color;
  bool isActive;
  DateTime createdAt;
  double? rating;
  CategoryResponse category;
  AssetResponse primaryImageUrl;
  List<AssetResponse> imageUrls;
  List<ProductSizeResponse> sizes;

  ProductResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.barCode,
    required this.price,
    required this.color,
    required this.isActive,
    required this.createdAt,
    this.rating,
    required this.category,
    required this.primaryImageUrl,
    required this.imageUrls,
    required this.sizes,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      barCode: json['barCode'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      color: ColorResponse.fromJson(json['color'] ?? {}),
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      rating: json['rating']?.toDouble(),
      category: CategoryResponse.fromJson(json['category'] ?? {}),
      primaryImageUrl: AssetResponse.fromJson(json['primaryImageUrl'] ?? {}),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((item) => AssetResponse.fromJson(item))
              .toList() ??
          [],
      sizes: (json['sizes'] as List<dynamic>?)
              ?.map((item) => ProductSizeResponse.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barCode': barCode,
      'price': price,
      'color': color.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'category': category.toJson(),
      'primaryImageUrl': primaryImageUrl.toJson(),
      'imageUrls': imageUrls.map((item) => item.toJson()).toList(),
      'sizes': sizes.map((item) => item.toJson()).toList(),
    };
  }
}
