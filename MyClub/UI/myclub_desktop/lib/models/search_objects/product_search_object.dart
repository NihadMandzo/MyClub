class ProductSearchObject {
  final String? name;
  final String? fts;
  final int? categoryId;
  final int? colorId;
  final double? minPrice;
  final double? maxPrice;
  final bool? isActive;
  final int? page;
  final int? pageSize;

  ProductSearchObject({
    this.name,
    this.fts,
    this.categoryId,
    this.colorId,
    this.minPrice,
    this.maxPrice,
    this.isActive,
    this.page,
    this.pageSize,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> params = {};
    
    if (name != null) params['name'] = name;
    if (fts != null) params['fts'] = fts;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (colorId != null) params['colorId'] = colorId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (isActive != null) params['isActive'] = isActive;
    if (page != null) params['page'] = page;
    if (pageSize != null) params['pageSize'] = pageSize;
    
    return params;
  }
}
