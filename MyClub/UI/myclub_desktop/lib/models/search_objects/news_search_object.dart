import 'package:myclub_desktop/models/search_objects/base_search_object.dart';

class NewsSearchObject extends BaseSearchObject {
  DateTime? fromDate;
  DateTime? toDate;
  String? title;
  String? username;

  NewsSearchObject({
    this.fromDate,
    this.toDate,
    this.title,
    this.username,
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
    
    if (fromDate != null) {
      json['fromDate'] = fromDate!.toIso8601String();
    }
    
    if (toDate != null) {
      json['toDate'] = toDate!.toIso8601String();
    }
    
    if (title != null) {
      json['title'] = title;
    }
    
    if (username != null) {
      json['username'] = username;
    }
    
    return json;
  }
}
