import 'package:myclub_desktop/models/comment.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class CommentProvider extends BaseProvider<Comment> {
  CommentProvider() : super('Comment');

  @override
  Comment fromJson(data) {
    return Comment.fromJson(data);
  }
}
