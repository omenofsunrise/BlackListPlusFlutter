String? normalizeRussianPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;

  if (digits.length == 10) {
    return '7$digits';
  }

  if (digits.length == 11 &&
      (digits.startsWith('7') || digits.startsWith('8'))) {
    return '7${digits.substring(1)}';
  }

  final match = RegExp(r'(?:7|8)?(\d{10})').firstMatch(digits);
  if (match == null) return null;

  return '7${match.group(1)!}';
}

String? formatRussianPhoneForCall(String raw) {
  final normalized = normalizeRussianPhone(raw);
  if (normalized == null) return null;
  return '+$normalized';
}

String? formatRussianPhoneForWhatsApp(String raw) {
  return normalizeRussianPhone(raw);
}
