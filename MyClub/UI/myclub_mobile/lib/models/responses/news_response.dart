import 'asset_response.dart';
import 'comment_response.dart';

class NewsResponse {
  int id;
  String title;
  DateTime date;
  AssetResponse? primaryImage;
  String? videoUrl;
  String content;
  String username;
  List<AssetResponse> images;
  List<CommentResponse> comments;

  NewsResponse({
    required this.id,
    required this.title,
    required this.date,
    this.primaryImage,
    this.videoUrl,
    required this.content,
    required this.username,
    required this.images,
    required this.comments,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      primaryImage: json['primaryImage'] != null 
          ? AssetResponse.fromJson(json['primaryImage']) 
          : null,
      videoUrl: json['videoUrl'],
      content: json['content'] ?? '',
      username: json['username'] ?? '',
      images: json['images'] != null
          ? (json['images'] as List)
              .map((item) => AssetResponse.fromJson(item))
              .toList()
          : [],
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((item) => CommentResponse.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'primaryImage': primaryImage?.toJson(),
      'videoUrl': videoUrl,
      'content': content,
      'username': username,
      'images': images.map((item) => item.toJson()).toList(),
      'comments': comments.map((item) => item.toJson()).toList(),
    };
  }
}
