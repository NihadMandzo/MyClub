import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/search_objects/base_search_object.dart';
import '../models/responses/match_response.dart';
import '../models/responses/paged_result.dart';
import '../models/search_objects/match_search_object.dart';
import 'base_provider.dart';

class MatchProvider extends BaseProvider<MatchResponse> {
  MatchProvider() : super("Match");

  @override
  MatchResponse fromJson(data) {
    return MatchResponse.fromJson(data);
  }

Future<PagedResult<MatchResponse>> getPastMatches() async {
    try {
      var url = "${BaseProvider.baseUrl}${endpoint}/past";
      
      // Add query parameters to get all items
      var queryParams = {
        'retrieveAll': 'true',
      };
      
      var uri = Uri.parse(url).replace(queryParameters: queryParams);
      var headers = createHeaders();

      print("API GET Request URL: $uri");
      print("API GET Request Headers: $headers");

      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);

        return PagedResult<MatchResponse>.fromJson(
          data,
          (item) => fromJson(item),
        );
      } else {
        throw Exception("Greška tokom dohvatanja podataka");
      }
    } catch (e) {
      throw Exception("Greška pri dohvatanju predstojećih utakmica: $e");
    }
  }

  /// Get upcoming matches (matches without results)
  Future<PagedResult<MatchResponse>> getUpcomingMatches() async {
   try {
      var url = "${BaseProvider.baseUrl}${endpoint}/upcoming";
      
      // Add query parameters to get all items
      var queryParams = {
        'retrieveAll': 'true',
      };
      
      var uri = Uri.parse(url).replace(queryParameters: queryParams);
      var headers = createHeaders();

      print("API GET Request URL: $uri");
      print("API GET Request Headers: $headers");

      var response = await http.get(uri, headers: headers);

      if (isValidResponse(response)) {
        var data = jsonDecode(response.body);

        return PagedResult<MatchResponse>.fromJson(
          data,
          (item) => fromJson(item),
        );
      } else {
        throw Exception("Greška tokom dohvatanja podataka");
      }
    } catch (e) {
      throw Exception("Greška pri dohvatanju predstojećih utakmica: $e");
    }
  }

  /// Get all matches for a specific club
  Future<List<MatchResponse>> getMatchesForClub(int clubId) async {
    try {
      final searchObject = BaseSearchObject(
        retrieveAll: true,
      );
      final result = await get(searchObject: searchObject);
      return result.result ?? [];
    } catch (e) {
      throw Exception("Greška pri dohvatanju utakmica za klub: $e");
    }
  }
}
