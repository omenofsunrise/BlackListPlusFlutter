class Debt {
  final int id;
  final String debtEndingAt;
  final bool payed;
  final String? creatorId;
  final int blacklistId;

  const Debt({
    required this.id,
    required this.debtEndingAt,
    required this.payed,
    required this.blacklistId,
    this.creatorId,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: (json['id'] as num?)?.toInt() ?? 0,
      debtEndingAt: (json['debt_ending_at'] ?? json['debtEndingAt'] ?? '')
          .toString(),
      payed: json['payed'] == true,
      creatorId: (json['creator_id'] ?? json['creatorId'])?.toString(),
      blacklistId:
          (json['blacklist_id'] as num?)?.toInt() ??
          (json['blacklistId'] as num?)?.toInt() ??
          0,
    );
  }
}
