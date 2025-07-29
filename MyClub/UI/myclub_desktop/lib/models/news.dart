import 'dart:typed_data';

import 'package:myclub_desktop/models/asset.dart';
import 'package:myclub_desktop/models/comment.dart';

class News {
  int id;
  String title;
  DateTime date;
  Asset? primaryImage;
  String content;
  String? videoUrl;
  String username;
  List<Asset> images;
  List<Comment> comments;

  News({
    required this.id,
    required this.title,
    required this.date,
    this.primaryImage,
    required this.content,
    this.videoUrl,
    required this.username,
    required this.images,
    required this.comments,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      primaryImage: json['primaryImage'] != null
          ? Asset.fromJson(json['primaryImage'])
          : null,
      content: json['content'] ?? '',
      videoUrl: json['videoUrl'],
      username: json['username'] ?? '',
      images: json['images'] != null
          ? (json['images'] as List).map((e) => Asset.fromJson(e)).toList()
          : [],
      comments: json['comments'] != null
          ? (json['comments'] as List).map((e) => Comment.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'primaryImage': primaryImage?.toJson(),
      'content': content,
      'videoUrl': videoUrl,
      'username': username,
      'images': images.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}
