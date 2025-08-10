import '../models/responses/news_response.dart';
import 'base_provider.dart';

class NewsProvider extends BaseProvider<NewsResponse> {
  NewsProvider() : super("News");

  @override
  NewsResponse fromJson(data) {
    return NewsResponse.fromJson(data);
  }
}
