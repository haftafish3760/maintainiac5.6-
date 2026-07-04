class AppPdfFormatters {
  const AppPdfFormatters._();

  static String date(DateTime day) => '${day.month}/${day.day}/${day.year}';

  static String money(num value) {
    return moneyCents(_roundedCents(value));
  }

  static String moneyCents(int cents) {
    final sign = cents < 0 ? '-' : '';
    final absolute = cents.abs();
    final dollars = absolute ~/ 100;
    final pennies = (absolute % 100).toString().padLeft(2, '0');
    return '$sign\$$dollars.$pennies';
  }

  static String quantity(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  static String fileSize(int bytes) {
    if (bytes < 0) return '0 bytes';
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      final rendered = mb >= 10 ? mb.round().toString() : mb.toStringAsFixed(1);
      return '$rendered MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).ceil()} KB';
    return bytes == 1 ? '1 byte' : '$bytes bytes';
  }

  static int _roundedCents(num value) {
    final text = value.toStringAsFixed(6);
    final negative = text.startsWith('-');
    final unsigned = negative ? text.substring(1) : text;
    final parts = unsigned.split('.');
    final dollars = int.tryParse(parts.first) ?? 0;
    final decimals = parts.length > 1 ? parts[1].padRight(3, '0') : '000';
    final pennies = int.tryParse(decimals.substring(0, 2)) ?? 0;
    final roundingDigit = int.tryParse(decimals.substring(2, 3)) ?? 0;
    final cents = (dollars * 100) + pennies + (roundingDigit >= 5 ? 1 : 0);
    return negative ? -cents : cents;
  }
}
