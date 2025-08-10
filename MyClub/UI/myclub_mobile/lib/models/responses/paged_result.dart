class PagedResult<T> {
  List<T>? result;
  int? count;
  int? totalCount;
  int? currentPage;
  int? pageSize;
  int? totalPages;
  bool? hasPrevious;
  bool? hasNext;

  PagedResult({
    this.result, 
    this.count,
    this.totalCount,
    this.currentPage,
    this.pageSize,
    this.totalPages,
    this.hasPrevious,
    this.hasNext,
  });

  PagedResult.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    // Handle both 'data' and 'result' arrays for backward compatibility
    if (json['data'] != null) {
      result = <T>[];
      json['data'].forEach((v) {
        result!.add(fromJsonT(v));
      });
    } else if (json['result'] != null) {
      result = <T>[];
      json['result'].forEach((v) {
        result!.add(fromJsonT(v));
      });
    }
    
    count = json['count'];
    totalCount = json['totalCount'];
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
    hasPrevious = json['hasPrevious'];
    hasNext = json['hasNext'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (result != null) {
      data['result'] = result!.map((v) => v).toList();
    }
    data['count'] = count;
    data['totalCount'] = totalCount;
    data['currentPage'] = currentPage;
    data['pageSize'] = pageSize;
    data['totalPages'] = totalPages;
    data['hasPrevious'] = hasPrevious;
    data['hasNext'] = hasNext;
    return data;
  }
}
