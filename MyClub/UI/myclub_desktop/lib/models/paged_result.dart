class PagedResult<T> {
  int totalCount;
  int currentPage;
  int pageSize;
  List<T> data;

  PagedResult({
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.data,
  });

  int get totalPages => (totalCount / pageSize).ceil();
  bool get hasPrevious => currentPage > 0;
  bool get hasNext => currentPage < totalPages - 1;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult<T>(
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      data: List<T>.from((json['data'] ?? []).map((x) => fromJsonT(x))),
    );
  }
}
