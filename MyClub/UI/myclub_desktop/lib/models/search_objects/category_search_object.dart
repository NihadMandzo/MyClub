import 'package:myclub_desktop/models/search_objects/base_search_object.dart';

class CategorySearchObject extends BaseSearchObject {
  String? name;

  CategorySearchObject({
    this.name,
    String? fts,
    int? page,
    int? pageSize,
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
    var json = super.toJson();
    json['name'] = name;
    return json;
  }
}
