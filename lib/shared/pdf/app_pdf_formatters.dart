class AppPdfFormatters {
  const AppPdfFormatters._();

  static String date(DateTime day) => '${day.month}/${day.day}/${day.year}';

  static String money(num value) {
    final cents = (value * 100).round();
    return moneyCents(cents);
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
}
