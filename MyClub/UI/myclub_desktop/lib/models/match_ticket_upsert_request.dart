class MatchTicketUpsertRequest {
  int matchId;
  int releasedQuantity;
  double price;
  int stadiumSectorId;
  bool isActive;

  MatchTicketUpsertRequest({
    required this.matchId,
    required this.releasedQuantity,
    required this.price,
    required this.stadiumSectorId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'releasedQuantity': releasedQuantity,
      'price': price,
      'stadiumSectorId': stadiumSectorId,
      'isActive': isActive,
    };
  }
}
