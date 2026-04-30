class PaymentStat {
  final int year;
  final int month;
  final double assumed;
  final double notAssumed;
  final double total;

  PaymentStat({
    required this.year,
    required this.month,
    required this.assumed,
    required this.notAssumed,
    required this.total,
  });

  factory PaymentStat.fromJson(Map<String, dynamic> json) {
    return PaymentStat(
      year: json['year'],
      month: json['month'],
      assumed: (json['assumed'] as num).toDouble(),
      notAssumed: (json['notAssumed'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}
