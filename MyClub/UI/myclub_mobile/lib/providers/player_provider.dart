import 'package:myclub_mobile/models/responses/player_response.dart';
import 'package:myclub_mobile/models/search_objects/base_search_object.dart';
import 'base_provider.dart';

class PlayerProvider extends BaseProvider<PlayerResponse> {
  PlayerProvider() : super("Player");

  @override
  PlayerResponse fromJson(data) {
    return PlayerResponse.fromJson(data);
  }

  /// Get players with retrieveAll set to true by default
  Future<List<PlayerResponse>> getPlayers({BaseSearchObject? searchObject}) async {
    final search = searchObject ?? BaseSearchObject();
    search.retrieveAll = true; // Set retrieveAll to true as requested
    
    final result = await get(searchObject: search);
    return result.result ?? [];
  }

 
}
