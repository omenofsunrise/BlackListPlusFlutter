class CreditStat {
  final int year;
  final int month;
  final int count;

  CreditStat({required this.year, required this.month, required this.count});

  factory CreditStat.fromJson(Map<String, dynamic> json) {
    return CreditStat(
      year: json['year'],
      month: json['month'],
      count: json['count'],
    );
  }
}
