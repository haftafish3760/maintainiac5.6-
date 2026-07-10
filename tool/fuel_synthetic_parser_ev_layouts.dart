part of 'fuel_synthetic_parser_runner.dart';

String _evReceipt({
  required String merchant,
  required int day,
  required double quantity,
  required double unitPrice,
  required double amount,
  required int odometer,
  required int layout,
  required double? sessionFee,
  required bool useMeteredSessionFee,
  required double? parkingFee,
  required double? tax,
  required String locale,
  required bool omitKwh,
}) {
  final qty = quantity.toStringAsFixed(2);
  final price = unitPrice.toStringAsFixed(3);
  final total = amount.toStringAsFixed(2);
  final isSpanish = locale == 'spanish_us';
  final kwhLine = omitKwh ? '' : 'kWh $qty';
  final englishSaleLine = omitKwh ? 'Energy Sale $total' : 'FUEL SALE $total';
  final spanishSaleLine = omitKwh
      ? 'Venta Energia $total'
      : 'Venta Combustible $total';
  final feeLine = sessionFee == null
      ? ''
      : useMeteredSessionFee
      ? isSpanish
            ? '\nTarifa por minuto 30 MIN @ 0.050 ${sessionFee.toStringAsFixed(2)}'
            : '\nDCFC TIME 30 MIN @ 0.050 ${sessionFee.toStringAsFixed(2)}'
      : isSpanish
      ? layout.isEven
            ? '\nCuota de sesión ${sessionFee.toStringAsFixed(2)}'
            : '\nTarifa por inactividad ${sessionFee.toStringAsFixed(2)}'
      : layout.isEven
      ? '\nSession fee ${sessionFee.toStringAsFixed(2)}'
      : '\nIdle fee ${sessionFee.toStringAsFixed(2)}';
  final parkingLine = parkingFee == null
      ? ''
      : isSpanish
      ? '\nEstacionamiento ${parkingFee.toStringAsFixed(2)}'
      : '\nParking fee ${parkingFee.toStringAsFixed(2)}';
  final taxLine = tax == null
      ? ''
      : isSpanish
      ? '\nImpuesto ${tax.toStringAsFixed(2)}'
      : '\nSales Tax ${tax.toStringAsFixed(2)}';
  final grandTotal =
      (amount + (sessionFee ?? 0) + (parkingFee ?? 0) + (tax ?? 0))
          .toStringAsFixed(2);
  if (isSpanish) {
    switch (layout) {
      case 0:
        final energyLine = omitKwh
            ? 'Venta Energia $total'
            : 'Energía $qty kWh $total';
        final rateLine = omitKwh ? '\nTarifa/kWh $price' : '';
        return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Carga eléctrica
$energyLine$rateLine$feeLine$parkingLine$taxLine
Total $grandTotal
Odometro $odometer
''';
      case 1:
        return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Carga EV
$kwhLine
Tarifa/kWh $price
$spanishSaleLine$feeLine
$parkingLine$taxLine
Total $grandTotal
Odometro $odometer
''';
      case 2:
        return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Sesión de carga $qty kWh @ $price $total$feeLine$parkingLine$taxLine
Tarjeta $grandTotal
Autorización 7788
Odometro $odometer
''';
      default:
        return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Energía entregada $qty kWh
Precio/kWh $price
Carga eléctrica $total$feeLine$parkingLine$taxLine
Monto pagado $grandTotal
Odometro $odometer
''';
    }
  }
  switch (layout) {
    case 0:
      final energyLine = omitKwh
          ? 'Energy Sale $total'
          : 'Energy $qty kWh $total';
      final rateLine = omitKwh ? '\nRate $price' : '';
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
$energyLine$rateLine$feeLine$parkingLine$taxLine
Total $grandTotal
Odometer $odometer
''';
    case 1:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
EV CHARGING
$kwhLine
Rate $price
$englishSaleLine$feeLine$parkingLine$taxLine
TOTAL $grandTotal
Odometer $odometer
''';
    case 2:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Charging Session $qty kWh @ $price $total$feeLine$parkingLine$taxLine
Visa $grandTotal
Auth 7788
Odometer $odometer
''';
    default:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Electric fuel $total
Energy Delivered $qty kWh
Price/kWh $price
Amount Paid $grandTotal$feeLine$parkingLine$taxLine
Mileage $odometer
''';
  }
}

void _expectNear(
  List<String> issues, {
  required String field,
  required double? actual,
  required double expected,
  double tolerance = .01,
}) {
  if (actual == null || (actual - expected).abs() > tolerance) {
    issues.add('${field}_expected_${expected.toStringAsFixed(3)}_got_$actual');
  }
}

double _money(double value) => (value * 100).round() / 100;
