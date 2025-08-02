import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/order.dart';
import 'package:myclub_desktop/models/paged_result.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class OrderProvider extends BaseProvider<Order> {
  OrderProvider() : super("Order");

@override
  Order fromJson(data) {
    return Order.fromJson(data);
  }
}
