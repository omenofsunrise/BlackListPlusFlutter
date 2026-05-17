import 'dart:convert';

import 'package:blacklist_plus_flutter/features/calc/data/calc_preset.dart';
import 'package:blacklist_plus_flutter/features/calc/data/calculation_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalcPresetService extends ChangeNotifier {
  CalcPresetService(this._prefs) {
    _bootstrap();
  }

  static const _kPresets = 'calc_presets';
  static const _kSeeded = 'calc_presets_seeded';

  final SharedPreferences _prefs;
  List<CalcPreset> _presets = const [];

  List<CalcPreset> get presets => List.unmodifiable(_presets);

  void _bootstrap() {
    final seeded = _prefs.getBool(_kSeeded) ?? false;
    if (!seeded) {
      _presets = _defaultPresets();
      _persist();
      _prefs.setBool(_kSeeded, true);
      return;
    }
    final raw = _prefs.getString(_kPresets);
    if (raw == null || raw.isEmpty) {
      _presets = const [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _presets = list
          .map((e) => CalcPreset.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _presets = const [];
    }
  }

  Future<CalcPreset> add({
    required String title,
    required int amount,
    required int months,
    required int initial,
    required int percent,
    required int round,
    required CalculationMode mode,
  }) async {
    final preset = CalcPreset(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      months: months,
      initial: initial,
      percent: percent,
      round: round,
      mode: mode,
    );
    _presets = [..._presets, preset];
    await _persist();
    notifyListeners();
    return preset;
  }

  Future<void> update(CalcPreset preset) async {
    _presets =
        _presets.map((p) => p.id == preset.id ? preset : p).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _presets = _presets.where((p) => p.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_presets.map((p) => p.toJson()).toList());
    await _prefs.setString(_kPresets, raw);
  }

  List<CalcPreset> _defaultPresets() {
    return [
      CalcPreset(
        id: 'seed_auto',
        title: 'Авто',
        amount: 1000000,
        months: 12,
        initial: 0,
        percent: 20,
        round: 100,
        mode: CalculationMode.standard,
      ),
      CalcPreset(
        id: 'seed_home',
        title: 'Бытовая техника',
        amount: 80000,
        months: 6,
        initial: 0,
        percent: 25,
        round: 50,
        mode: CalculationMode.standard,
      ),
      CalcPreset(
        id: 'seed_electronics',
        title: 'Электроника',
        amount: 50000,
        months: 6,
        initial: 0,
        percent: 30,
        round: 50,
        mode: CalculationMode.standard,
      ),
    ];
  }
}
