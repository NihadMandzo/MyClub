class CommentResponse {
  int id;
  String content;
  DateTime createdAt;
  String username;

  CommentResponse({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.username,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'username': username,
    };
  }
}
