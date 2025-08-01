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
  
}
