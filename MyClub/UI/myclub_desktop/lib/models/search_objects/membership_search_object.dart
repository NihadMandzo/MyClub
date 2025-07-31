import 'package:myclub_desktop/models/search_objects/base_search_object.dart';

class MembershipSearchObject extends BaseSearchObject {

  bool? includeInactive;

  MembershipSearchObject({
    String? fts,
    int? page,
    int? pageSize,
    bool includeTotalCount = true,
    bool retrieveAll = false,
    this.includeInactive = false, // Use 'this' to assign to field
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
    // Always include the parameter with its current value
    json['IncludeInactive'] = includeInactive;
    return json;
  }
}