import 'package:myclub_desktop/models/search_objects/base_search_object.dart';

class MembershipSearchObject extends BaseSearchObject {

  bool? includeInactive;

  MembershipSearchObject({
    String? fts,
    int? page,
    int? pageSize,
    bool includeTotalCount = true,
    bool retrieveAll = false,
    bool? includeInactive,
  }) : super(
    page: page,
    pageSize: pageSize,
    fts: fts,
    includeTotalCount: includeTotalCount,
    retrieveAll: retrieveAll,
  );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    

    
    if (includeInactive != null) {
      json['IncludeInactive'] = includeInactive;
    }
    
    return json;
  }
}