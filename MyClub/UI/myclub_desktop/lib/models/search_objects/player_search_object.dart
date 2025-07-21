import 'base_search_object.dart';

class PlayerSearchObject extends BaseSearchObject {
  String? name;


  PlayerSearchObject({
    this.name,

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
    final map = super.toJson();
    map.addAll({
      'name': name,
    });
    return map;
  }
}
