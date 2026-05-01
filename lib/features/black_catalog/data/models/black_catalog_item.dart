import 'package:blacklist_plus_flutter/features/black_catalog/data/models/debt.dart';

class BlackCatalogItem {
  final int id;
  final String fullname;
  final String? doc;
  final String? address;
  final String? birthdate;
  final String? comment;
  final bool? isSwindler;
  final String? creatorId;
  final List<Debt> debts;

  const BlackCatalogItem({
    required this.id,
    required this.fullname,
    this.doc,
    this.address,
    this.birthdate,
    this.comment,
    this.isSwindler,
    this.creatorId,
    this.debts = const [],
  });

  factory BlackCatalogItem.fromJson(Map<String, dynamic> json) {
    final rawDebts = json['debts'];
    final debts = <Debt>[];
    if (rawDebts is List) {
      for (final raw in rawDebts) {
        if (raw is Map) {
          debts.add(Debt.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return BlackCatalogItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullname: (json['fullname'] ?? '').toString(),
      doc: (json['doc'])?.toString(),
      address: (json['address'])?.toString(),
      birthdate: (json['birthdate'])?.toString(),
      comment: (json['comment'])?.toString(),
      isSwindler: json['is_swindler'] is bool
          ? json['is_swindler'] as bool
          : (json['isSwindler'] is bool ? json['isSwindler'] as bool : null),
      creatorId: (json['creator_id'] ?? json['creatorId'])?.toString(),
      debts: debts,
    );
  }

  List<Debt> get activeDebts {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return debts.where((d) {
      final end = DateTime.tryParse(d.debtEndingAt);
      if (end == null) return false;
      final endStart = DateTime(end.year, end.month, end.day);
      return !endStart.isBefore(todayStart);
    }).toList();
  }

  List<Debt> get expiredDebts {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return debts.where((d) {
      final end = DateTime.tryParse(d.debtEndingAt);
      if (end == null) return false;
      final endStart = DateTime(end.year, end.month, end.day);
      return endStart.isBefore(todayStart);
    }).toList();
  }
}
