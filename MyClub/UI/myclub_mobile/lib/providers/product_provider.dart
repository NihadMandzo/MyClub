import '../models/responses/product_response.dart';
import 'base_provider.dart';

class ProductProvider extends BaseProvider<ProductResponse> {
  ProductProvider() : super("Product");

  @override
  ProductResponse fromJson(data) {
    return ProductResponse.fromJson(data);
  }
}
