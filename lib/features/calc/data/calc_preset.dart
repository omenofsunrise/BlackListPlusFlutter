import 'package:blacklist_plus_flutter/features/calc/data/calculation_mode.dart';

class CalcPreset {
  final String id;
  final String title;
  final int amount;
  final int months;
  final int initial;
  final int percent;
  final int round;
  final CalculationMode mode;

  const CalcPreset({
    required this.id,
    required this.title,
    required this.amount,
    required this.months,
    required this.initial,
    required this.percent,
    required this.round,
    required this.mode,
  });

  CalcPreset copyWith({
    String? title,
    int? amount,
    int? months,
    int? initial,
    int? percent,
    int? round,
    CalculationMode? mode,
  }) {
    return CalcPreset(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      months: months ?? this.months,
      initial: initial ?? this.initial,
      percent: percent ?? this.percent,
      round: round ?? this.round,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'months': months,
        'initial': initial,
        'percent': percent,
        'round': round,
        'mode': mode.storageKey,
      };

  factory CalcPreset.fromJson(Map<String, dynamic> json) {
    return CalcPreset(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toInt(),
      months: (json['months'] as num).toInt(),
      initial: (json['initial'] as num? ?? 0).toInt(),
      percent: (json['percent'] as num).toInt(),
      round: (json['round'] as num? ?? 50).toInt(),
      mode: CalculationModeX.parse(json['mode'] as String?),
    );
  }
}
