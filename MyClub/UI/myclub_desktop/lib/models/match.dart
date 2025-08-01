import 'package:myclub_desktop/models/match_ticket.dart';

class Match {
  int? id;
  DateTime? matchDate;
  String? opponentName;
  String? status;
  String? clubId;
  String? clubName;
  String? location;
  String? description;
  MatchTicket? ticket;

  Match({this.id, this.matchDate, this.opponentName, this.status,
  this.clubId, this.clubName, this.location, this.description, this.ticket});

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      matchDate: DateTime.tryParse(json['matchDate'] ?? ''),
      opponentName: json['opponentName'],
      status: json['status'],
      clubId: json['clubId'],
      clubName: json['clubName'],
      location: json['location'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchDate': matchDate?.toIso8601String(),
      'opponentName': opponentName,
      'status': status,
      'clubId': clubId,
      'clubName': clubName,
      'location': location,
      'description': description,
    };
  }
}
