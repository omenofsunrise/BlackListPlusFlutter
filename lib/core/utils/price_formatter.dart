import 'package:intl/intl.dart';

class PriceFormatter {
  /// Форматирует число или строку в формат вида "15 000₽"
  ///
  /// Примеры:
  /// - 15000 -> "15 000₽"
  /// - "15000" -> "15 000₽"
  /// - 15000.5 -> "15 000.5₽"
  /// - null -> "0₽"
  static String formatPrice(dynamic value) {
    if (value == null) return "0₽";

    // Преобразуем в число
    final num number;
    if (value is num) {
      number = value;
    } else if (value is String) {
      number = num.tryParse(value.replaceAll(' ', '')) ?? 0;
    } else {
      number = 0;
    }

    // Разделяем на целую и дробную части
    final isDouble = number is double || number % 1 != 0;
    final integerPart = number.floor();
    final decimalPart = number - integerPart;

    // Форматируем целую часть с разделителями тысяч
    final integerString = _formatIntegerPart(integerPart);

    // Если есть дробная часть, добавляем её
    if (isDouble && decimalPart > 0) {
      // Округляем до 2 знаков после запятой и убираем лишние нули
      final decimalString = decimalPart.toStringAsFixed(2);
      final cleanDecimal = decimalString
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll('0.', '.');

      return '$integerString$cleanDecimal₽';
    }

    return '${integerString}₽';
  }

  /// Форматирует целую часть числа с разделителями тысяч
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

  /// Альтернативная реализация с использованием NumberFormat
  /// (требует пакет intl)
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

    // Проверяем, есть ли дробная часть
    final hasDecimal = number is double || number % 1 != 0;

    final format = NumberFormat.currency(
      symbol: '₽',
      decimalDigits: hasDecimal ? 2 : 0,
      locale: 'ru_RU',
    );

    String formatted = format.format(number);

    // Убираем запятую для целых чисел и лишние нули для дробных
    if (!hasDecimal) {
      formatted = formatted.replaceAll(',00', '');
    } else {
      formatted = formatted.replaceAll(RegExp(r',?0+₽'), '₽');
    }

    return formatted.replaceAll(',', '.');
  }
}
