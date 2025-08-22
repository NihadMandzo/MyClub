import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/responses/city_response.dart';
import '../models/responses/paged_result.dart';
import 'base_provider.dart';

class CityProvider extends BaseProvider<CityResponse> {
  CityProvider() : super("City");

  @override
  CityResponse fromJson(data) {
    return CityResponse.fromJson(data);
  }
}
