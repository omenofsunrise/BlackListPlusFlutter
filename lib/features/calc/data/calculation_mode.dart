enum CalculationMode { standard, afterInitial, monthlyPercent }

extension CalculationModeX on CalculationMode {
  String get storageKey {
    switch (this) {
      case CalculationMode.standard:
        return 'standard';
      case CalculationMode.afterInitial:
        return 'afterInitial';
      case CalculationMode.monthlyPercent:
        return 'monthlyPercent';
    }
  }

  static CalculationMode parse(String? raw) {
    switch (raw) {
      case 'afterInitial':
        return CalculationMode.afterInitial;
      case 'monthlyPercent':
        return CalculationMode.monthlyPercent;
      case 'standard':
      default:
        return CalculationMode.standard;
    }
  }
}
