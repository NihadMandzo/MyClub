class Color {
  int? id;
  String? name;
  String? hexCode;

  Color({this.id, this.name, this.hexCode});

  factory Color.fromJson(Map<String, dynamic> json) {
    return Color(
      id: json['id'],
      name: json['name'],
      hexCode: json['hexCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hexCode': hexCode,
    };
  }
}
