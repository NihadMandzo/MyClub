import 'match_ticket_response.dart';

class MatchResponse {
  int id;
  DateTime matchDate;
  String opponentName;
  String status;
  int clubId;
  String clubName;
  String location;
  String description;
  MatchResultResponse? result;
  List<MatchTicketResponse> tickets;

  MatchResponse({
    required this.id,
    required this.matchDate,
    required this.opponentName,
    required this.status,
    required this.clubId,
    required this.clubName,
    required this.location,
    required this.description,
    this.result,
    required this.tickets,
  });

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    return MatchResponse(
      id: json['id'] ?? 0,
      matchDate: DateTime.parse(json['matchDate'] ?? DateTime.now().toIso8601String()),
      opponentName: json['opponentName'] ?? '',
      status: json['status'] ?? '',
      clubId: json['clubId'] ?? 0,
      clubName: json['clubName'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      result: json['result'] != null ? MatchResultResponse.fromJson(json['result']) : null,
      tickets: (json['tickets'] as List<dynamic>?)
          ?.map((ticket) => MatchTicketResponse.fromJson(ticket))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchDate': matchDate.toIso8601String(),
      'opponentName': opponentName,
      'status': status,
      'clubId': clubId,
      'clubName': clubName,
      'location': location,
      'description': description,
      'result': result?.toJson(),
      'tickets': tickets.map((ticket) => ticket.toJson()).toList(),
    };
  }
}

class MatchResultResponse {
  int homeGoals;
  int awayGoals;

  MatchResultResponse({
    required this.homeGoals,
    required this.awayGoals,
  });

  factory MatchResultResponse.fromJson(Map<String, dynamic> json) {
    return MatchResultResponse(
      homeGoals: json['homeGoals'] ?? 0,
      awayGoals: json['awayGoals'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
    };
  }
}
