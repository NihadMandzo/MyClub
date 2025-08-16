import 'package:myclub_desktop/models/match_ticket.dart';

class Match {
  int? id;
  DateTime? matchDate;
  String? opponentName;
  String? status;
  int? clubId;
  String? clubName;
  String? location;
  String? description;
  MatchTicket? ticket;
  List<MatchTicket>? tickets;
  MatchResult? result;

  Match({this.id, this.matchDate, this.opponentName, this.status,
  this.clubId, this.clubName, this.location, this.description, 
  this.ticket, this.tickets, this.result});

  factory Match.fromJson(Map<String, dynamic> json) {
    List<MatchTicket>? tickets;
    
    if (json['tickets'] != null) {
      try {
        // Check if tickets is a List
        if (json['tickets'] is List) {
          tickets = (json['tickets'] as List)
              .map((ticket) => MatchTicket.fromJson(ticket))
              .toList();
        } else if (json['tickets'] is Map) {
          // If it's a Map, it might be a single ticket object or empty object
          Map<String, dynamic> ticketsMap = json['tickets'] as Map<String, dynamic>;
          if (ticketsMap.isNotEmpty) {
            // Try to convert single ticket map to list
            tickets = [MatchTicket.fromJson(ticketsMap)];
          } else {
            tickets = [];
          }
        } else {
          tickets = [];
        }
      } catch (e) {
        print("Error parsing tickets: $e");
        tickets = [];
      }
    } else {
      tickets = [];
    }

    return Match(
      id: json['id'],
      matchDate: DateTime.tryParse(json['matchDate'] ?? ''),
      opponentName: json['opponentName'],
      status: json['status'],
      clubId: json['clubId'],
      clubName: json['clubName'],
      location: json['location'],
      description: json['description'],
      ticket: json['ticket'] != null ? MatchTicket.fromJson(json['ticket']) : null,
      tickets: tickets,
      result: json['result'] != null ? MatchResult.fromJson(json['result']) : null,
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
      'result': result?.toJson(),
    };
  }
}

class MatchResult {
  int? homeGoals;
  int? awayGoals;

  MatchResult({this.homeGoals, this.awayGoals});

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      homeGoals: json['homeGoals'],
      awayGoals: json['awayGoals'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
    };
  }
}
