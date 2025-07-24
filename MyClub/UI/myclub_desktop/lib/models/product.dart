import 'package:myclub_desktop/models/category.dart';
import 'package:myclub_desktop/models/color.dart' as model;
import 'package:myclub_desktop/models/asset.dart';
import 'package:myclub_desktop/models/product_size.dart';

class Product {
  final int? id;
  final String? name;
  final String? description;
  final String? barCode;
  final double? price;
  final model.Color? color;
  final bool? isActive;
  final DateTime? createdAt;
  final double? rating;
  final Category? category;
  final Asset? primaryImageUrl;
  final List<Asset>? imageUrls;
  final List<ProductSize>? sizes;

  Product({
    this.id,
    this.name,
    this.description,
    this.barCode,
    this.price,
    this.color,
    this.isActive,
    this.createdAt,
    this.rating,
    this.category,
    this.primaryImageUrl,
    this.imageUrls,
    this.sizes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      barCode: json['barCode'],
      price: json['price']?.toDouble(),
      color: json['color'] != null ? model.Color.fromJson(json['color']) : null,
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      rating: json['rating']?.toDouble(),
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      primaryImageUrl: json['primaryImageUrl'] != null ? Asset.fromJson(json['primaryImageUrl']) : null,
      imageUrls: json['imageUrls'] != null 
          ? List<Asset>.from(json['imageUrls'].map((x) => Asset.fromJson(x))) 
          : null,
      sizes: json['sizes'] != null 
          ? List<ProductSize>.from(json['sizes'].map((x) => ProductSize.fromJson(x))) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barCode': barCode,
      'price': price,
      'color': color?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'rating': rating,
      'category': category?.toJson(),
      'primaryImageUrl': primaryImageUrl?.toJson(),
    };
  }
}
