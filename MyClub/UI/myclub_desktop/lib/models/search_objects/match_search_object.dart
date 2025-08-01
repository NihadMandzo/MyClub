import 'package:myclub_desktop/models/search_objects/base_search_object.dart';

class MatchSearchObject extends BaseSearchObject {
  String? status;
  String? opponentName;
  DateTime? matchDateFrom;
  DateTime? matchDateTo;

  MatchSearchObject({
    super.fts,
    super.page = 0,
    super.pageSize = 10,
    super.includeTotalCount = true,
    super.retrieveAll = false,
    this.status,
    this.opponentName,
    this.matchDateFrom,
    this.matchDateTo,
  });

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    if (status != null) json['status'] = status;
    if (opponentName != null) json['opponentName'] = opponentName;
    if (matchDateFrom != null) json['matchDateFrom'] = matchDateFrom!.toIso8601String();
    if (matchDateTo != null) json['matchDateTo'] = matchDateTo!.toIso8601String();
    return json;
  }
}
