class BaseSearchObject {
  String? fts;
  int? page;
  int? pageSize;
  bool includeTotalCount;
  bool retrieveAll;

  BaseSearchObject({
    this.fts,
    this.page = 0,
    this.pageSize = 10,
    this.includeTotalCount = true,
    this.retrieveAll = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'fts': fts,
      'page': page,
      'pageSize': pageSize,
      'includeTotalCount': includeTotalCount,
      'retrieveAll': retrieveAll,
    };
  }
}
