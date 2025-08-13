import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/requests/cart_item_upsert_request.dart';
import '../models/responses/cart_response.dart';
import '../models/responses/cart_item_response.dart';
import '../providers/user_provider.dart';
import 'base_provider.dart';

/// Provider for cart-related API operations
class CartProvider extends BaseProvider<CartResponse> {
  CartProvider() : super("Cart");

  @override
  CartResponse fromJson(data) {
    return CartResponse.fromJson(data);
  }

  /// Get current user's cart with membership discount calculation
  Future<CartResponse?> getCurrentUserCart() async {
    var url = "${BaseProvider.baseUrl}$endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      // Check if response indicates empty cart
      var data = jsonDecode(response.body);
      if (data is Map && data.containsKey('message') && data['message'] == 'Cart is empty') {
        return null;
      }
      
      // Check for active membership to apply discount
      bool hasActiveMembership = false;
      try {
        final userProvider = UserProvider();
        userProvider.setContext(context);
        hasActiveMembership = await userProvider.hasActiveUserMembership();
      } catch (e) {
        print('Error checking membership status: $e');
        hasActiveMembership = false; // Default to no discount on error
      }
      
      // Add membership information to the data before creating CartResponse
      data['hasActiveMembership'] = hasActiveMembership;
      
      return CartResponse.fromJson(data);
    } else {
      throw Exception("Greška tokom dohvatanja korpe");
    }
  }

  /// Add item to current user's cart
  Future<CartItemResponse> addToCart(CartItemUpsertRequest request) async {
    var url = "${BaseProvider.baseUrl}$endpoint/items";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request.toJson());
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return CartItemResponse.fromJson(data);
    } else {
      throw Exception("Greška tokom dodavanja proizvoda u korpu");
    }
  }

  /// Update item in current user's cart
  Future<CartItemResponse> updateCartItem(int itemId, CartItemUpsertRequest request) async {
    var url = "${BaseProvider.baseUrl}$endpoint/items/$itemId";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request.toJson());
    var response = await http.put(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return CartItemResponse.fromJson(data);
    } else {
      throw Exception("Greška tokom ažuriranja stavke u korpi");
    }
  }

  /// Remove item from current user's cart
  Future<void> removeFromCart(int itemId) async {
    var url = "${BaseProvider.baseUrl}$endpoint/items/$itemId";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.delete(uri, headers: headers);

    if (!isValidResponse(response)) {
      throw Exception("Greška tokom uklanjanja stavke iz korpe");
    }
  }

  /// Clear current user's cart
  Future<void> clearCart() async {
    var url = "${BaseProvider.baseUrl}$endpoint/clear";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.delete(uri, headers: headers);

    if (!isValidResponse(response)) {
      throw Exception("Greška tokom brisanja korpe");
    }
  }
}
