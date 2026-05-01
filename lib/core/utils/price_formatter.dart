import 'package:intl/intl.dart';

class PriceFormatter {
  static String formatPrice(dynamic value) {
    if (value == null) return "0₽";

    final num number;
    if (value is num) {
      number = value;
    } else if (value is String) {
      number = num.tryParse(value.replaceAll(' ', '')) ?? 0;
    } else {
      number = 0;
    }

    final isDouble = number is double || number % 1 != 0;
    final integerPart = number.floor();
    final decimalPart = number - integerPart;

    final integerString = _formatIntegerPart(integerPart);

    if (isDouble && decimalPart > 0) {
      final decimalString = decimalPart.toStringAsFixed(2);
      final cleanDecimal = decimalString
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll('0.', '.');

      return '$integerString$cleanDecimal₽';
    }

    return '${integerString}₽';
  }

  static String _formatIntegerPart(int number) {
    if (number == 0) return '0';

    final String numberStr = number.abs().toString();
    final StringBuffer result = StringBuffer();

    if (number < 0) {
      result.write('-');
    }

    final int length = numberStr.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        result.write(' ');
      }
      result.write(numberStr[i]);
    }

    return result.toString();
  }

  static String formatPriceWithIntl(dynamic value) {
    if (value == null) return "0₽";

    final num number;
    if (value is num) {
      number = value;
    } else if (value is String) {
      number = num.tryParse(value.replaceAll(' ', '')) ?? 0;
    } else {
      number = 0;
    }

    final hasDecimal = number is double || number % 1 != 0;

    final format = NumberFormat.currency(
      symbol: '₽',
      decimalDigits: hasDecimal ? 2 : 0,
      locale: 'ru_RU',
    );

    String formatted = format.format(number);

    if (!hasDecimal) {
      formatted = formatted.replaceAll(',00', '');
    } else {
      formatted = formatted.replaceAll(RegExp(r',?0+₽'), '₽');
    }

    return formatted.replaceAll(',', '.');
  }
}
