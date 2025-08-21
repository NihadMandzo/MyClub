import '../models/responses/product_response.dart';
import '../utility/auth_helper.dart';
import 'base_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductProvider extends BaseProvider<ProductResponse> {
  ProductProvider() : super("Product");

  @override
  ProductResponse fromJson(data) {
    return ProductResponse.fromJson(data);
  }

  Future<List<ProductResponse>> getRecommended() async {
    // Get userId from AuthProvider first, then fallback to SharedPreferences
    int? userId;
    
    // Try to get userId from global auth provider
    final auth = BaseProvider.getGlobalAuthProvider();
    if (auth?.userId != null) {
      userId = auth!.userId;
    } else {
      // Fallback to SharedPreferences
      userId = await AuthHelper.getUserId();
    }
    
    if (userId == null) {
      throw Exception("User not authenticated");
    }
    
    var url = "${BaseProvider.baseUrl}$endpoint/recommender/$userId";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("API GET Request URL: $url");
    print("API GET Request Headers: $headers");
    
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      
      // Convert the response to List<ProductResponse>
      List<ProductResponse> products = [];
      if (data is List) {
        products = data.map((item) => ProductResponse.fromJson(item)).toList();
      }
      
      return products;
    } else {
      throw Exception("Error fetching recommended products");
    }
  }
}
