class Comment {
  final int? id;
  final String? content;
  final DateTime? createdAt;
  final String? username;

  
  Comment({
    this.id,
    this.content,
    this.createdAt,
    this.username,
  });


  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      username: json['username'],
    );
  }
     
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt?.toIso8601String(),
      'username': username,
    };
  }
}
