part of 'fuel_synthetic_parser_runner.dart';

String _dieselDefReceipt({
  required String merchant,
  required int day,
  required int pump,
  required _FuelSyntheticProduct dieselProduct,
  required double dieselQuantity,
  required double dieselUnitPrice,
  required double dieselAmount,
  required double defQuantity,
  required double defUnitPrice,
  required double defAmount,
  required int odometer,
}) {
  final total = (dieselAmount + defAmount).toStringAsFixed(2);
  return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
PUMP $pump
PRODUCT ${dieselProduct.label}
GALLONS ${dieselQuantity.toStringAsFixed(3)}
PRICE/GAL ${dieselUnitPrice.toStringAsFixed(3)}
FUEL SALE ${dieselAmount.toStringAsFixed(2)}
DEF FLUID ${defQuantity.toStringAsFixed(3)} GAL ${defAmount.toStringAsFixed(2)}
TOTAL $total
WEX FLEET CARD $total
EFS DRIVER ID 55${day}21
COMDATA AUTH 77${day}92
ODOMETER $odometer
''';
}

String _liquidFuelReceipt({
  required String merchant,
  required _FuelSyntheticProduct product,
  required int day,
  required int pump,
  required double quantity,
  required double unitPrice,
  required double amount,
  required int odometer,
  required int layout,
  required String locale,
  required bool includeMixed,
  required bool includeCash,
  required bool includePreauthHold,
  required bool useLiters,
  required bool includePartialFill,
  required bool includeFleetTender,
  required bool includePersonalConvenience,
  required double? discount,
  required double? perUnitDiscount,
  required bool useRewardPerUnitDiscount,
  required double? carWashAmount,
  required double? alternatePricePremium,
  required bool omitVolume,
  required double? prepayRefundAmount,
  required double? exciseTax,
  required bool useHubometer,
  required bool useNonEthanolLabel,
  required bool includePrivateIdentity,
  required bool useDispenserShorthand,
}) {
  final qty = quantity.toStringAsFixed(3);
  final price = unitPrice.toStringAsFixed(3);
  final total = amount.toStringAsFixed(2);
  final isGallonEquivalent = product.unit == 'GGE' || product.unit == 'DGE';
  final englishUnit = useLiters
      ? 'L'
      : isGallonEquivalent
      ? product.unit
      : product.unit == 'kg'
      ? 'KG'
      : 'GAL';
  final englishVolumeLabel = useLiters
      ? 'LITERS'
      : isGallonEquivalent
      ? product.unit
      : product.unit == 'kg'
      ? 'KG'
      : 'GALLONS';
  final englishPriceLabel = useLiters
      ? 'PRICE/LITER'
      : isGallonEquivalent
      ? 'PRICE/${product.unit}'
      : product.unit == 'kg'
      ? 'PRICE/KG'
      : 'PRICE/GAL';
  final spanishVolumeLabel = useLiters
      ? 'Litros'
      : isGallonEquivalent
      ? product.unit
      : product.unit == 'kg'
      ? 'KG'
      : 'Galones';
  final spanishPriceLabel = useLiters
      ? 'Precio/Litro'
      : isGallonEquivalent
      ? 'Precio/${product.unit}'
      : product.unit == 'kg'
      ? 'Precio/KG'
      : 'Precio/Galón';
  final layoutOneOdometerLine = useHubometer
      ? 'HUBOMETER $odometer'
      : 'ODO $odometer';
  final productLabel = useNonEthanolLabel
      ? 'REC FUEL 90 NO ETHANOL'
      : product.label;
  final spanishProductLabel = useNonEthanolLabel
      ? 'Gasolina Sin Etanol'
      : product.spanishLabel;
  final spanishVolumeLine = omitVolume ? '' : '$spanishVolumeLabel $qty';
  final englishVolumeLine = omitVolume ? '' : '$englishVolumeLabel $qty';
  final discountLine = discount == null
      ? ''
      : locale == 'spanish_us'
      ? '\nDescuento combustible -${discount.toStringAsFixed(2)}'
      : '\nREWARDS DISC -${discount.toStringAsFixed(2)}';
  final perUnitDiscountLine = perUnitDiscount == null
      ? ''
      : locale == 'spanish_us'
      ? '\nDescuento/Galón -${perUnitDiscount.toStringAsFixed(3)}'
      : useRewardPerUnitDiscount
      ? '\nFUEL REWARDS -${perUnitDiscount.toStringAsFixed(3)}/GAL'
      : '\nDISC/GAL -${perUnitDiscount.toStringAsFixed(3)}';
  final alternatePriceLine = alternatePricePremium == null
      ? ''
      : locale == 'spanish_us'
      ? '\nPrecio efectivo $price\nPrecio credito ${(unitPrice + alternatePricePremium).toStringAsFixed(3)}'
      : '\nCASH PRICE/GAL $price\nCREDIT PRICE/GAL ${(unitPrice + alternatePricePremium).toStringAsFixed(3)}';
  final carWash = carWashAmount == null
      ? ''
      : locale == 'spanish_us'
      ? '\nLavado de auto ${carWashAmount.toStringAsFixed(2)}'
      : '\nCAR WASH ULTIMATE ${carWashAmount.toStringAsFixed(2)}';
  final prepayRefund = prepayRefundAmount == null
      ? ''
      : locale == 'spanish_us'
      ? '\nReembolso prepago ${prepayRefundAmount.toStringAsFixed(2)}'
      : '\nUNUSED PREPAY REFUND ${prepayRefundAmount.toStringAsFixed(2)}';
  final exciseTaxLine = exciseTax == null
      ? ''
      : locale == 'spanish_us'
      ? '\nImpuesto federal ${exciseTax.toStringAsFixed(2)}'
      : '\nFederal Excise Tax ${exciseTax.toStringAsFixed(2)}';
  final mixedAmount = includeMixed
      ? locale == 'spanish_us'
            ? 3.75
            : 8.48
      : 0.0;
  final personalAmount = includePersonalConvenience ? 25.74 : 0.0;
  final carWashTotal = carWashAmount ?? 0.0;
  final exciseTaxTotal = exciseTax ?? 0.0;
  final grandTotal =
      (amount +
              mixedAmount +
              personalAmount +
              carWashTotal +
              exciseTaxTotal -
              (discount ?? 0))
          .toStringAsFixed(2);
  // Tax-bearing receipts normally print a final total in addition to the card
  // authorization amount. Keep payment-only footer variants elsewhere, but do
  // not make this tax accounting case depend on an inferred tender total.
  final taxTotalFooter = exciseTax == null ? '' : '\nTOTAL $grandTotal';
  final alternatePriceTender = alternatePricePremium == null
      ? ''
      : locale == 'spanish_us'
      ? '\nTarjeta credito $grandTotal'
      : '\nVISA CREDIT $grandTotal';
  final mixed = includeMixed
      ? locale == 'spanish_us'
            ? '\nCafe grande 2.25\nAgua botella 1.50'
            : '\nCOFFEE LARGE 2.49\nWASHER FLUID 5.99'
      : '';
  final personalConvenience = includePersonalConvenience
      ? locale == 'spanish_us'
            ? '\nCerveza 6pk 11.99\nCigarrillos 8.75\nLoteria 5.00'
            : '\nBEER 6PK 11.99\nCIGARETTES 8.75\nLOTTERY SCRATCHER 5.00'
      : '';
  final cash = includeCash
      ? locale == 'spanish_us'
            ? '\nEfectivo ${(double.parse(grandTotal) + 10).toStringAsFixed(2)}\nCambio 10.00'
            : '\nCASH TENDER ${(double.parse(grandTotal) + 10).toStringAsFixed(2)}\nCHANGE DUE 10.00'
      : '';
  final holdAmount = (double.parse(grandTotal) + 100).toStringAsFixed(2);
  final preauthHold = includePreauthHold
      ? locale == 'spanish_us'
            ? '\nAutorización previa $holdAmount'
            : '\nPREAUTH HOLD $holdAmount\nAUTH APPROVED 880${day}61'
      : '';
  final partialNote = includePartialFill
      ? locale == 'spanish_us'
            ? '\nCarga parcial\nNo lleno'
            : '\nTANK NOT FULL'
      : '';
  final fleetTender = includeFleetTender
      ? locale == 'spanish_us'
            ? '\nTarjeta flota WEX $grandTotal\nEFS Conductor 55${day}21\nComdata Autorización 77${day}92'
            : '\nWEX FLEET CARD $grandTotal\nEFS DRIVER ID 55${day}21\nCOMDATA AUTH 77${day}92\nVOYAGER TRACE 20${day}618'
      : '';
  final privateIdentity = includePrivateIdentity
      ? '\nMEMBER 77${day}888999\nDRIVER ID AB${day}77\nVEHICLE ID TRUCK-${pump.toString().padLeft(2, '0')}\nVIN 1FTFW1E55NFA${day.toString().padLeft(5, '0')}\nLICENSE PLATE TX KLT${pump.toString().padLeft(4, '0')}'
      : '';

  if (useDispenserShorthand) {
    return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
NOZZLE ${pump.toString().padLeft(2, '0')}
HOSE ${(pump % 4) + 1}
FUELING POINT $pump
PROD $productLabel
VOL $qty
PPU $price
AMT $total$discountLine$mixed$cash
$alternatePriceLine
$perUnitDiscountLine
$carWash
$prepayRefund
$exciseTaxLine
$personalConvenience
$fleetTender
$privateIdentity
$preauthHold
$partialNote
TOTAL $grandTotal
ODOMETER $odometer
''';
  }

  if (locale == 'spanish_us') {
    return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Bomba $pump
Producto $spanishProductLabel
$spanishVolumeLine
$spanishPriceLabel $price
$alternatePriceLine
$perUnitDiscountLine
Venta Combustible $total$discountLine$mixed$cash$alternatePriceTender
$carWash
$prepayRefund
$exciseTaxLine
$personalConvenience
$fleetTender
$privateIdentity
$preauthHold
$partialNote
Total $grandTotal
Odometro $odometer
''';
  }

  switch (layout) {
    case 0:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
Pump $pump $productLabel $qty $englishUnit $total$discountLine$mixed$cash
$alternatePriceLine
$perUnitDiscountLine
$carWash
$prepayRefund
$exciseTaxLine
$personalConvenience
$fleetTender
$privateIdentity
$preauthHold
$partialNote
TOTAL $grandTotal
''';
    case 1:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
PUMP $pump
PRODUCT $productLabel
$englishVolumeLine
$englishPriceLabel $price
$alternatePriceLine
$perUnitDiscountLine
FUEL SALE $total$discountLine$mixed$cash
$carWash
$prepayRefund
$exciseTaxLine
$personalConvenience
$fleetTender
$privateIdentity
$preauthHold
$partialNote
TOTAL $grandTotal
$layoutOneOdometerLine
''';
    case 2:
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
$productLabel $qty $englishUnit @ $price $total$mixed
$alternatePriceLine
$perUnitDiscountLine
$discountLine
$carWash
$prepayRefund
$exciseTaxLine
CARD SALE $grandTotal$cash
$taxTotalFooter
$personalConvenience
$fleetTender
$privateIdentity
$preauthHold
$partialNote
AUTH 100${day}99
''';
    default:
      final compactQuantityUnit = isGallonEquivalent
          ? '${product.unit} '
          : product.unit == 'kg'
          ? 'KG '
          : useLiters
          ? 'LITERS '
          : '';
      final compactPriceLabel = product.unit == 'GGE'
          ? 'PPGE'
          : product.unit == 'DGE'
          ? 'PPDGE'
          : product.unit == 'kg'
          ? 'PPKG'
          : useLiters
          ? 'PPL'
          : 'PPG';
      return '''
$merchant
06/${day.toString().padLeft(2, '0')}/2026
FUEL QTY $compactQuantityUnit$qty
$compactPriceLabel $price
$alternatePriceLine
$perUnitDiscountLine
$productLabel FUEL $total$discountLine$mixed$cash
$carWash
$prepayRefund
$exciseTaxLine
$personalConvenience
$fleetTender
$privateIdentity
$preauthHold
$partialNote
AMOUNT PAID $grandTotal
MILEAGE $odometer
''';
  }
}
