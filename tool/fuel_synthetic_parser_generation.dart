part of 'fuel_synthetic_parser_runner.dart';

List<_FuelSyntheticReceipt> _generateSyntheticFuelReceipts({
  required int count,
  required int seed,
}) {
  final receipts = <_FuelSyntheticReceipt>[];
  var index = 0;
  while (receipts.length < count) {
    final productIndex = (index + seed) % _products.length;
    final productCycle = (index ~/ _products.length) + seed;
    final product = _products[productIndex];
    final layout = productCycle % 4;
    final locale = ((index + seed) % 5 == 0) ? 'spanish_us' : 'english_us';
    final includeMultiFuel =
        product.fuelType == 'Diesel' &&
        product.unit == 'gallon' &&
        locale == 'english_us' &&
        ((index + seed) % 12 == 2);
    final includeMixed =
        !includeMultiFuel && product.unit != 'kWh' && ((index + seed) % 4 == 1);
    final includeCash =
        !includeMultiFuel && product.unit != 'kWh' && ((index + seed) % 6 == 2);
    final includePreauthHold =
        !includeMultiFuel &&
        product.unit != 'kWh' &&
        ((index + seed) % 10 == 6);
    final useLiters =
        !includeMultiFuel &&
        product.unit == 'gallon' &&
        ((index + seed) % 10 == 7);
    final includePartialFill =
        !includeMultiFuel &&
        product.unit != 'kWh' &&
        ((index + seed) % 12 == 8);
    final includeFleetTender =
        includeMultiFuel ||
        (product.unit != 'kWh' && ((index + seed) % 11 == 8));
    final includePersonalConvenience =
        !includeMultiFuel &&
        product.unit != 'kWh' &&
        ((index + seed) % 13 == 3);
    final carWashAmount =
        !includeMultiFuel && product.unit != 'kWh' && ((index + seed) % 9 == 0)
        ? _money(8.00 + (((index + seed) % 3) * 2))
        : null;
    final includePrepayRefund =
        !includeMultiFuel &&
        product.unit != 'kWh' &&
        ((index + seed) % 15 == 4);
    final includeLiquidExciseTax =
        !includeMultiFuel &&
        product.unit != 'kWh' &&
        ((index + seed) % 17 == 6);
    final includeHubometer =
        !includeMultiFuel &&
        product.unit != 'kWh' &&
        layout == 1 &&
        ((index + seed) % 5 == 0);
    final includeNonEthanol =
        !includeMultiFuel &&
        product.fuelType == 'Gasoline' &&
        product.unit == 'gallon' &&
        !useLiters &&
        ((index + seed) % 10 == 0);
    final includeDirtyText =
        locale == 'english_us' && ((index + seed) % 7 == 3);
    final useCommaDecimals =
        locale == 'spanish_us' && ((index + seed) % 9 == 5);
    final includeAlternatePrice =
        !includeMultiFuel &&
        product.unit == 'gallon' &&
        !useLiters &&
        ((index + seed) % 16 == 1);
    final includePerUnitDiscount =
        !includeMultiFuel &&
        product.unit == 'gallon' &&
        !useLiters &&
        !includeAlternatePrice &&
        ((index + seed) % 14 == 5);
    final includeRewardUnitDiscount =
        !includeMultiFuel &&
        product.unit == 'gallon' &&
        !useLiters &&
        !includeAlternatePrice &&
        !includePerUnitDiscount &&
        ((index + seed) % 18 == 13);
    final includeMissingVolume =
        !includeMultiFuel &&
        product.unit == 'gallon' &&
        !useLiters &&
        !includeAlternatePrice &&
        !includePerUnitDiscount &&
        !includeRewardUnitDiscount &&
        layout == 1 &&
        ((index + seed) % 4 == 3);
    final perUnitDiscount = includePerUnitDiscount || includeRewardUnitDiscount
        ? .05 + (((index + seed) % 3) * .05)
        : null;
    final discount =
        !includePerUnitDiscount &&
            product.unit != 'kWh' &&
            ((index + seed) % 8 == 4)
        ? _money(.35 + (((index + seed) % 3) * .25))
        : null;
    final evFee = product.unit == 'kWh' && productCycle.isEven
        ? _money(.75 + (((index + seed) % 4) * .5))
        : null;
    final evParkingFee = product.unit == 'kWh' && productCycle.isEven
        ? _money(2.00 + (((index + seed) % 3) * .75))
        : null;
    final includeEvMissingKwh =
        product.unit == 'kWh' && (layout == 0 || layout == 1);
    final quantity = product.unit == 'kWh'
        ? 8.25 + ((index + seed) % 19) * .75
        : useLiters
        ? 19.5 + ((index + seed) % 23) * 1.75
        : 5.125 + ((index + seed) % 23) * .625;
    final postedUnitPrice = useLiters
        ? (product.basePrice + ((index + seed) % 11) * .011) * 0.2641720524
        : product.basePrice + ((index + seed) % 11) * .011;
    final alternatePricePremium = includeAlternatePrice ? .10 : 0.0;
    final effectiveUnitPrice =
        postedUnitPrice + alternatePricePremium - (perUnitDiscount ?? 0);
    final amount = _money(quantity * effectiveUnitPrice);
    final expectedQuantity = includeEvMissingKwh
        ? amount / effectiveUnitPrice
        : quantity;
    final prepayRefundAmount = includePrepayRefund
        ? _money(10.00 + (((index + seed) % 4) * 2.50))
        : null;
    final liquidExciseTax = includeLiquidExciseTax
        ? _money(1.00 + (((index + seed) % 5) * .35))
        : null;
    final evTax = product.unit == 'kWh' && evParkingFee != null
        ? _money((amount + (evFee ?? 0) + evParkingFee) * .0725)
        : null;
    final secondaryQuantity = includeMultiFuel
        ? 2.25 + ((index + seed) % 5) * .25
        : null;
    const secondaryUnitPrice = 4.299;
    final secondaryAmount = secondaryQuantity == null
        ? null
        : _money(secondaryQuantity * secondaryUnitPrice);
    final odometer = 46000 + ((index + seed) * 41);
    final day = ((index + seed) % 26) + 1;
    final pump = ((index + seed) % 18) + 1;
    final merchant = _merchants[(index + seed) % _merchants.length];
    final expectWarehouseFuel = _warehouseFuelMerchants.contains(merchant);
    final includePrivateIdentity =
        !includeMultiFuel &&
        product.unit != 'kWh' &&
        ((index + seed) % 20 == 11);
    final includeDispenserShorthand =
        !includeMultiFuel &&
        product.unit == 'gallon' &&
        locale == 'english_us' &&
        !useLiters &&
        productIndex == 1;
    final cleanText = includeMultiFuel
        ? _dieselDefReceipt(
            merchant: merchant,
            day: day,
            pump: pump,
            dieselProduct: product,
            dieselQuantity: quantity,
            dieselUnitPrice: postedUnitPrice,
            dieselAmount: amount,
            defQuantity: secondaryQuantity!,
            defUnitPrice: secondaryUnitPrice,
            defAmount: secondaryAmount!,
            odometer: odometer,
          )
        : product.unit == 'kWh'
        ? _evReceipt(
            merchant: 'CHARGEPOINT',
            day: day,
            quantity: quantity,
            unitPrice: postedUnitPrice,
            amount: amount,
            odometer: odometer,
            layout: layout,
            sessionFee: evFee,
            parkingFee: evParkingFee,
            tax: evTax,
            locale: locale,
            omitKwh: includeEvMissingKwh,
          )
        : _liquidFuelReceipt(
            merchant: merchant,
            product: product,
            day: day,
            pump: pump,
            quantity: quantity,
            unitPrice: postedUnitPrice,
            amount: amount,
            odometer: odometer,
            layout: layout,
            locale: locale,
            includeMixed: includeMixed,
            includeCash: includeCash,
            includePreauthHold: includePreauthHold,
            useLiters: useLiters,
            includePartialFill: includePartialFill,
            includeFleetTender: includeFleetTender,
            includePersonalConvenience: includePersonalConvenience,
            discount: discount,
            perUnitDiscount: perUnitDiscount,
            useRewardPerUnitDiscount: includeRewardUnitDiscount,
            carWashAmount: carWashAmount,
            alternatePricePremium: includeAlternatePrice
                ? alternatePricePremium
                : null,
            omitVolume: includeMissingVolume,
            prepayRefundAmount: prepayRefundAmount,
            exciseTax: liquidExciseTax,
            useHubometer: includeHubometer,
            useNonEthanolLabel: includeNonEthanol,
            includePrivateIdentity: includePrivateIdentity,
            useDispenserShorthand: includeDispenserShorthand,
          );
    final text = includeDirtyText ? _dirtyFuelText(cleanText) : cleanText;
    final localizedText = useCommaDecimals ? _commaDecimalText(text) : text;
    receipts.add(
      _FuelSyntheticReceipt(
        name:
            'fuel_synth_${receipts.length.toString().padLeft(4, '0')}_'
            '${product.fuelType}_${locale}_layout$layout',
        text: localizedText,
        quantity: expectedQuantity,
        unitPrice: effectiveUnitPrice,
        amount: amount,
        unit: useLiters ? 'liter' : product.unit,
        fuelType: product.fuelType,
        expectedFillType: includePartialFill ? 'Partial fill' : 'Full fill-up',
        locale: locale,
        odometer: layout == 1 || product.unit == 'kWh' ? odometer : null,
        expectMixed: includeMixed,
        expectCashExclusion: includeCash,
        expectDirtyText: includeDirtyText,
        expectCommaDecimals: useCommaDecimals,
        expectPreauthHold: includePreauthHold,
        expectFleetTenderExclusion: includeFleetTender,
        expectPersonalConvenience: includePersonalConvenience,
        expectMultiFuel: includeMultiFuel,
        expectPerUnitDiscount:
            includePerUnitDiscount || includeRewardUnitDiscount,
        expectRewardUnitDiscount: includeRewardUnitDiscount,
        expectAlternatePrice: includeAlternatePrice,
        expectMissingVolume: includeMissingVolume,
        expectEvMissingKwh: includeEvMissingKwh,
        expectHubometer: includeHubometer,
        expectNonEthanol: includeNonEthanol,
        expectWarehouseFuel: expectWarehouseFuel,
        expectPrivateIdentity: includePrivateIdentity,
        expectDispenserShorthand: includeDispenserShorthand,
        secondaryQuantity: secondaryQuantity,
        secondaryUnitPrice: includeMultiFuel ? secondaryUnitPrice : null,
        secondaryAmount: secondaryAmount,
        secondaryUnit: includeMultiFuel ? 'gallon' : null,
        secondaryFuelType: includeMultiFuel ? 'DEF' : null,
        expectedDiscountAdjustment: discount == null ? null : -discount,
        expectedChargingFee: evFee,
        expectedParkingFee: evParkingFee,
        expectedTax: evTax ?? liquidExciseTax,
        expectedCarWashAmount: carWashAmount,
        expectedPrepayRefundAmount: prepayRefundAmount,
      ),
    );
    index += 1;
  }
  return receipts;
}
