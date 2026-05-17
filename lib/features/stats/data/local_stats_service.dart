import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsSnapshot {
  final int totalAdded;
  final int totalDeleted;
  final int totalViewed;
  final int streak;
  final int activeDaysTotal;

  const StatsSnapshot({
    required this.totalAdded,
    required this.totalDeleted,
    required this.totalViewed,
    required this.streak,
    required this.activeDaysTotal,
  });

  const StatsSnapshot.empty()
      : totalAdded = 0,
        totalDeleted = 0,
        totalViewed = 0,
        streak = 0,
        activeDaysTotal = 0;
}

class LocalStatsService extends ChangeNotifier {
  LocalStatsService(this._prefs);

  static const _kAdded = 'stats.totalAdded';
  static const _kDeleted = 'stats.totalDeleted';
  static const _kViewed = 'stats.totalViewed';
  static const _kDates = 'stats.activeDates';

  final SharedPreferences _prefs;

  StatsSnapshot get snapshot {
    final activeDates = _readActiveDates();
    return StatsSnapshot(
      totalAdded: _prefs.getInt(_kAdded) ?? 0,
      totalDeleted: _prefs.getInt(_kDeleted) ?? 0,
      totalViewed: _prefs.getInt(_kViewed) ?? 0,
      streak: _computeStreak(activeDates),
      activeDaysTotal: activeDates.length,
    );
  }

  Future<void> recordAdd() async {
    await _bumpCounter(_kAdded);
    await _touchToday();
    notifyListeners();
  }

  Future<void> recordDelete() async {
    await _bumpCounter(_kDeleted);
    await _touchToday();
    notifyListeners();
  }

  Future<void> recordView() async {
    await _bumpCounter(_kViewed);
    await _touchToday();
    notifyListeners();
  }

  Future<void> recordAppOpen() async {
    await _touchToday();
    notifyListeners();
  }

  Future<void> _bumpCounter(String key) async {
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);
  }

  Future<void> _touchToday() async {
    final today = _isoDate(DateTime.now());
    final dates = _readActiveDates();
    if (dates.contains(today)) return;
    dates.add(today);
    await _prefs.setString(_kDates, jsonEncode(dates.toList()));
  }

  Set<String> _readActiveDates() {
    final raw = _prefs.getString(_kDates);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  int _computeStreak(Set<String> dates) {
    if (dates.isEmpty) return 0;
    final today = _isoDate(DateTime.now());
    final yesterday = _isoDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    DateTime cursor;
    if (dates.contains(today)) {
      cursor = DateTime.now();
    } else if (dates.contains(yesterday)) {
      cursor = DateTime.now().subtract(const Duration(days: 1));
    } else {
      return 0;
    }
    int count = 0;
    while (dates.contains(_isoDate(cursor))) {
      count += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  String _isoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
