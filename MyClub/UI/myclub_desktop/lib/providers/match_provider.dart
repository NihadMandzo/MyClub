import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/match.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class MatchProvider extends BaseProvider<Match> {
  MatchProvider() : super("Match");

  @override
  Match fromJson(data) {
    return Match.fromJson(data);
  }

  Future<Match> UpdateMatchResult(int matchId, MatchResult matchResult) async {
    var url = "${BaseProvider.baseUrl}$endpoint/result/$matchId";
    var headers = createHeaders();
    var body = matchResult.toJson();

    var response = await http.put(Uri.parse(url), headers: headers, body: jsonEncode(body));

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Error updating match result");
    }
  }

  Future<List<Match>> getUpcomingMatches() async {
    var url = "${BaseProvider.baseUrl}$endpoint/upcoming";
    var headers = createHeaders();

    var response = await http.get(Uri.parse(url), headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body) as List;
      return data.map((item) => fromJson(item)).toList();
    } else {
      throw Exception("Error fetching upcoming matches");
    }
  }

  Future<void> addTicketsForMatch(int matchId, List<Map<String, dynamic>> tickets) async {
    var url = "${BaseProvider.baseUrl}$endpoint/tickets/$matchId";
    var headers = createHeaders();

    var response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(tickets));

    if (!isValidResponse(response)) {
      throw Exception("Error adding tickets for match");
    }
  }

  Future<List<Map<String, dynamic>>> getTicketsForMatch(int matchId) async {
    var url = "${BaseProvider.baseUrl}$endpoint/$matchId/tickets";
    var headers = createHeaders();

    var response = await http.get(Uri.parse(url), headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Error fetching tickets for match");
    }
  }
  
}
