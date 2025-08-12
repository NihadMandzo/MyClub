import '../models/responses/category_response.dart';
import 'base_provider.dart';

class CategoryProvider extends BaseProvider<CategoryResponse> {
  CategoryProvider() : super("Category");

  @override
  CategoryResponse fromJson(data) {
    return CategoryResponse.fromJson(data);
  }
}
