import '../search_objects/base_search_object.dart';

class ProductSearchObject extends BaseSearchObject {
  String? barCode;
  String? fTS;
  List<int>? categoryIds;
  List<int>? colorIds;
  List<int>? sizeIds;
  double? minPrice;
  double? maxPrice;

  ProductSearchObject({
    this.barCode,
    this.fTS,
    this.categoryIds,
    this.colorIds,
    this.sizeIds,
    this.minPrice,
    this.maxPrice,
    String? fts,
    int? page = 0,
    int? pageSize = 10,
    bool includeTotalCount = true,
    bool retrieveAll = false,
  }) : super(
          fts: fts,
          page: page,
          pageSize: pageSize,
          includeTotalCount: includeTotalCount,
          retrieveAll: retrieveAll,
        );

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    
    if (barCode != null) data['barCode'] = barCode;
    if (fTS != null) data['fTS'] = fTS;

    if (categoryIds != null && categoryIds!.isNotEmpty) {
      data['categoryIds'] = categoryIds;
    }
    if (colorIds != null && colorIds!.isNotEmpty) {
      data['colorIds'] = colorIds;
    }
    if (sizeIds != null && sizeIds!.isNotEmpty) {
      data['sizeIds'] = sizeIds;
    }
    if (minPrice != null) data['minPrice'] = minPrice;
    if (maxPrice != null) data['maxPrice'] = maxPrice;
    
    return data;
  }
}
