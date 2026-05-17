import 'dart:async';
import 'dart:convert';

import 'package:blacklist_plus_flutter/features/stats/data/debt_reminder_service.dart';
import 'package:blacklist_plus_flutter/features/stats/data/local_debt.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebtTotals {
  final int activeCount;
  final int paidCount;
  final int activeSumRub;
  final int paidSumRub;

  const DebtTotals({
    required this.activeCount,
    required this.paidCount,
    required this.activeSumRub,
    required this.paidSumRub,
  });

  const DebtTotals.empty()
      : activeCount = 0,
        paidCount = 0,
        activeSumRub = 0,
        paidSumRub = 0;
}

class LocalDebtService extends ChangeNotifier {
  LocalDebtService(this._prefs, this._reminders) {
    _load();
  }

  static const _kDebts = 'local_debts';

  final SharedPreferences _prefs;
  final DebtReminderService _reminders;
  List<LocalDebt> _debts = const [];

  List<LocalDebt> get debts => List.unmodifiable(_debts);

  DebtTotals get totals {
    int activeCount = 0;
    int paidCount = 0;
    int activeSum = 0;
    int paidSum = 0;
    for (final d in _debts) {
      if (d.isPaid) {
        paidCount += 1;
        paidSum += d.amountRub;
      } else {
        activeCount += 1;
        activeSum += d.amountRub;
      }
    }
    return DebtTotals(
      activeCount: activeCount,
      paidCount: paidCount,
      activeSumRub: activeSum,
      paidSumRub: paidSum,
    );
  }

  Future<LocalDebt> add({
    required String debtorName,
    required int amountRub,
    DateTime? dueDate,
    String? comment,
  }) async {
    final debt = LocalDebt(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      debtorName: debtorName,
      amountRub: amountRub,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      comment: (comment != null && comment.trim().isNotEmpty)
          ? comment.trim()
          : null,
    );
    _debts = [debt, ..._debts];
    await _save();
    unawaited(_reminders.schedule(debt));
    notifyListeners();
    return debt;
  }

  Future<void> markPaid(String id) async {
    _debts = _debts
        .map(
          (d) => d.id == id
              ? d.copyWith(isPaid: true, paidAt: DateTime.now())
              : d,
        )
        .toList();
    await _save();
    unawaited(_reminders.cancel(id));
    notifyListeners();
  }

  Future<void> unmarkPaid(String id) async {
    _debts = _debts
        .map(
          (d) => d.id == id
              ? d.copyWith(isPaid: false, clearPaidAt: true)
              : d,
        )
        .toList();
    await _save();
    final debt = _debts.firstWhere(
      (d) => d.id == id,
      orElse: () => _debts.first,
    );
    if (debt.id == id) {
      unawaited(_reminders.schedule(debt));
    }
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _debts = _debts.where((d) => d.id != id).toList();
    await _save();
    unawaited(_reminders.cancel(id));
    notifyListeners();
  }

  /// Только для отладки: очищает журнал и отменяет все запланированные напоминания.
  Future<void> clearAll() async {
    for (final d in _debts) {
      unawaited(_reminders.cancel(d.id));
    }
    _debts = const [];
    await _save();
    notifyListeners();
  }

  /// Только для отладки: заполняет журнал набором реалистичных тестовых записей.
  Future<void> seedTestData() async {
    final now = DateTime.now();
    final samples = <LocalDebt>[
      LocalDebt(
        id: '${now.microsecondsSinceEpoch}_1',
        debtorName: 'Иван Петров',
        amountRub: 50000,
        createdAt: now.subtract(const Duration(days: 12)),
        dueDate: now.add(const Duration(days: 3)),
        comment: 'Занял на ремонт машины',
      ),
      LocalDebt(
        id: '${now.microsecondsSinceEpoch}_2',
        debtorName: 'Мария Сидорова',
        amountRub: 12000,
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 10)),
        comment: 'До зарплаты',
      ),
      LocalDebt(
        id: '${now.microsecondsSinceEpoch}_3',
        debtorName: 'Алексей Кузнецов',
        amountRub: 150000,
        createdAt: now.subtract(const Duration(days: 45)),
        dueDate: now.subtract(const Duration(days: 20)),
        comment: 'Долг просрочен',
      ),
      LocalDebt(
        id: '${now.microsecondsSinceEpoch}_4',
        debtorName: 'Дмитрий Орлов',
        amountRub: 8500,
        createdAt: now.subtract(const Duration(days: 30)),
        isPaid: true,
        paidAt: now.subtract(const Duration(days: 2)),
        comment: 'Вернул вовремя',
      ),
      LocalDebt(
        id: '${now.microsecondsSinceEpoch}_5',
        debtorName: 'Олег Соколов',
        amountRub: 25000,
        createdAt: now.subtract(const Duration(days: 60)),
        isPaid: true,
        paidAt: now.subtract(const Duration(days: 15)),
      ),
      LocalDebt(
        id: '${now.microsecondsSinceEpoch}_6',
        debtorName: 'Сергей Ушаков',
        amountRub: 3000,
        createdAt: now.subtract(const Duration(days: 1)),
        comment: 'За обед',
      ),
    ];
    _debts = [...samples, ..._debts];
    await _save();
    for (final d in samples) {
      unawaited(_reminders.schedule(d));
    }
    notifyListeners();
  }

  void _load() {
    final raw = _prefs.getString(_kDebts);
    if (raw == null || raw.isEmpty) {
      _debts = const [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _debts = list
          .map((e) => LocalDebt.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _debts = const [];
    }
  }

  Future<void> _save() async {
    final raw = jsonEncode(_debts.map((d) => d.toJson()).toList());
    await _prefs.setString(_kDebts, raw);
  }
}
