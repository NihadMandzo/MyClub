import 'package:myclub_desktop/models/match_ticket.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class MatchTicketProvider extends BaseProvider<MatchTicket> {
  MatchTicketProvider() : super("MatchTicket");

  @override
  MatchTicket fromJson(data) {
    return MatchTicket.fromJson(data);
  }
}
