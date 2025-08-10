class PagedResult<T> {
  List<T>? result;
  int? count;

  PagedResult({this.result, this.count});

  PagedResult.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    if (json['result'] != null) {
      result = <T>[];
      json['result'].forEach((v) {
        result!.add(fromJsonT(v));
      });
    }
    count = json['count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (result != null) {
      data['result'] = result!.map((v) => v).toList();
    }
    data['count'] = count;
    return data;
  }
}
