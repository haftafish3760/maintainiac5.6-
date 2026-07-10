import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

const _defaultCount = 24;
const _defaultFailUnder = 1.0;
const _presetCounts = {'smoke': 24, 'milestone': 500};

void main(List<String> args) {
  final config = _FuelSyntheticRunnerConfig.fromArgs(args);
  final cases = <_FuelSyntheticReceipt>[];
  for (var seedOffset = 0; seedOffset < config.seedCount; seedOffset += 1) {
    cases.addAll(
      _generateSyntheticFuelReceipts(
        count: config.count,
        seed: config.seed + seedOffset,
      ),
    );
  }
  final report = _scoreFuelReceipts(cases);
  final blocker = report.accuracy < config.failUnder;

  if (config.summaryJson || config.json) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(
        config.summaryJson
            ? report.toSummaryJson(failUnder: config.failUnder)
            : report.toJson(failUnder: config.failUnder),
      ),
    );
  } else {
    stdout.writeln(
      'Fuel synthetic parser runner: '
      '${report.passedCaseCount}/${report.caseCount} cases passed '
      '(${(report.accuracy * 100).toStringAsFixed(1)}%).',
    );
    if (report.failures.isNotEmpty) {
      stdout.writeln('Failures:');
      for (final failure in report.failures.take(10)) {
        stdout.writeln('  - ${failure.caseName}: ${failure.issues.join('; ')}');
      }
    }
  }

  if (blocker) exitCode = 1;
}

_FuelSyntheticReport _scoreFuelReceipts(List<_FuelSyntheticReceipt> cases) {
  final failures = <_FuelSyntheticFailure>[];
  final fuelTypeCounts = <String, int>{};
  final unitCounts = <String, int>{};
  final localeCounts = <String, int>{};
  var mixedReceiptCount = 0;
  var cashReceiptCount = 0;
  var evReceiptCount = 0;
  var cngReceiptCount = 0;
  var lngReceiptCount = 0;
  var propaneReceiptCount = 0;
  var hydrogenReceiptCount = 0;
  var dirtyReceiptCount = 0;
  var discountReceiptCount = 0;
  var evFeeReceiptCount = 0;
  var commaDecimalReceiptCount = 0;
  var preauthHoldReceiptCount = 0;
  var literReceiptCount = 0;
  var partialFillReceiptCount = 0;
  var fleetTenderReceiptCount = 0;
  var personalConvenienceReceiptCount = 0;
  var multiFuelReceiptCount = 0;
  var evParkingReceiptCount = 0;
  var evTaxReceiptCount = 0;
  var liquidExciseTaxReceiptCount = 0;
  var perUnitDiscountReceiptCount = 0;
  var carWashReceiptCount = 0;
  var alternatePriceReceiptCount = 0;
  var missingVolumeReceiptCount = 0;
  var evMissingKwhReceiptCount = 0;
  var prepayRefundReceiptCount = 0;
  var rewardUnitDiscountReceiptCount = 0;
  var hubometerReceiptCount = 0;
  var nonEthanolReceiptCount = 0;
  var warehouseFuelReceiptCount = 0;
  var privateIdentityReceiptCount = 0;
  var dispenserShorthandReceiptCount = 0;

  for (final receipt in cases) {
    fuelTypeCounts.update(
      receipt.fuelType,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    unitCounts.update(receipt.unit, (count) => count + 1, ifAbsent: () => 1);
    localeCounts.update(
      receipt.locale,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (receipt.expectMixed) mixedReceiptCount += 1;
    if (receipt.expectCashExclusion) cashReceiptCount += 1;
    if (receipt.fuelType == 'Electric') evReceiptCount += 1;
    if (receipt.fuelType == 'CNG') cngReceiptCount += 1;
    if (receipt.fuelType == 'LNG') lngReceiptCount += 1;
    if (receipt.fuelType == 'Propane') propaneReceiptCount += 1;
    if (receipt.fuelType == 'Hydrogen') hydrogenReceiptCount += 1;
    if (receipt.expectDirtyText) dirtyReceiptCount += 1;
    if (receipt.expectedDiscountAdjustment != null) discountReceiptCount += 1;
    if (receipt.expectedChargingFee != null) evFeeReceiptCount += 1;
    if (receipt.expectCommaDecimals) commaDecimalReceiptCount += 1;
    if (receipt.expectPreauthHold) preauthHoldReceiptCount += 1;
    if (receipt.unit == 'liter') literReceiptCount += 1;
    if (receipt.expectedFillType == 'Partial fill') {
      partialFillReceiptCount += 1;
    }
    if (receipt.expectFleetTenderExclusion) fleetTenderReceiptCount += 1;
    if (receipt.expectPersonalConvenience) personalConvenienceReceiptCount += 1;
    if (receipt.expectMultiFuel) multiFuelReceiptCount += 1;
    if (receipt.expectedParkingFee != null) evParkingReceiptCount += 1;
    if (receipt.expectedTax != null && receipt.fuelType == 'Electric') {
      evTaxReceiptCount += 1;
    }
    if (receipt.expectedTax != null && receipt.fuelType != 'Electric') {
      liquidExciseTaxReceiptCount += 1;
    }
    if (receipt.expectPerUnitDiscount) perUnitDiscountReceiptCount += 1;
    if (receipt.expectRewardUnitDiscount) rewardUnitDiscountReceiptCount += 1;
    if (receipt.expectedCarWashAmount != null) carWashReceiptCount += 1;
    if (receipt.expectAlternatePrice) alternatePriceReceiptCount += 1;
    if (receipt.expectMissingVolume) missingVolumeReceiptCount += 1;
    if (receipt.expectEvMissingKwh) evMissingKwhReceiptCount += 1;
    if (receipt.expectedPrepayRefundAmount != null) {
      prepayRefundReceiptCount += 1;
    }
    if (receipt.expectHubometer) hubometerReceiptCount += 1;
    if (receipt.expectNonEthanol) nonEthanolReceiptCount += 1;
    if (receipt.expectWarehouseFuel) warehouseFuelReceiptCount += 1;
    if (receipt.expectPrivateIdentity) privateIdentityReceiptCount += 1;
    if (receipt.expectDispenserShorthand) dispenserShorthandReceiptCount += 1;

    final parsed = parseExpenseReceiptText(receipt.text);
    final fuelLines = parsed.lines
        .where((line) => line.category == 'Fuel')
        .toList();
    final issues = <String>[];

    final expectedFuelLineCount = receipt.expectMultiFuel ? 2 : 1;
    if (fuelLines.length != expectedFuelLineCount) {
      issues.add(
        'expected_${expectedFuelLineCount}_fuel_lines_got_${fuelLines.length}',
      );
    } else {
      _checkExpectedFuelLine(
        issues,
        fuelLines,
        fuelType: receipt.fuelType,
        quantity: receipt.quantity,
        amount: receipt.amount,
        unitPrice: receipt.unitPrice,
        unit: receipt.unit,
        odometer: receipt.odometer,
        fillType: receipt.expectedFillType,
      );
      if (receipt.expectMultiFuel) {
        _checkExpectedFuelLine(
          issues,
          fuelLines,
          fuelType: receipt.secondaryFuelType!,
          quantity: receipt.secondaryQuantity!,
          amount: receipt.secondaryAmount!,
          unitPrice: receipt.secondaryUnitPrice!,
          unit: receipt.secondaryUnit!,
          odometer: receipt.odometer,
          fillType: receipt.expectedFillType,
        );
      }
    }

    if (parsed.diagnostics.parserTaskCount('fuel_line_ready') < 1) {
      issues.add('missing_fuel_line_ready_diagnostic');
    }
    if (receipt.expectCashExclusion &&
        parsed.diagnostics.parserTaskCount('cash_tender_line_excluded') < 1) {
      issues.add('missing_cash_tender_exclusion');
    }
    if (receipt.expectMixed &&
        parsed.diagnostics.parserTaskCount(
              'parser_expense_family_mixed_receipt',
            ) <
            1) {
      issues.add('missing_mixed_receipt_diagnostic');
    }
    if (receipt.expectedDiscountAdjustment != null) {
      final adjustments = parsed.lines.where(
        (line) => line.category == 'Receipt Adjustment',
      );
      final hasExpectedDiscount = adjustments.any((line) {
        return (line.subtotal - receipt.expectedDiscountAdjustment!).abs() <=
            .01;
      });
      if (!hasExpectedDiscount) {
        issues.add(
          'missing_discount_adjustment_${receipt.expectedDiscountAdjustment}',
        );
      }
    }
    if (receipt.expectedChargingFee != null) {
      final fees = parsed.lines.where(
        (line) => line.category == 'Charging Fees',
      );
      final hasExpectedFee = fees.any((line) {
        return (line.subtotal - receipt.expectedChargingFee!).abs() <= .01;
      });
      if (!hasExpectedFee) {
        issues.add('missing_charging_fee_${receipt.expectedChargingFee}');
      }
    }
    if (receipt.expectPreauthHold &&
        parsed.diagnostics.parserTaskCount('auth_detail_line_excluded') < 1) {
      issues.add('missing_preauth_hold_exclusion');
    }
    if (receipt.expectFleetTenderExclusion &&
        parsed.diagnostics.parserTaskCount('fleet_tender_line_excluded') < 1) {
      issues.add('missing_fleet_tender_exclusion');
    }
    if (receipt.expectPersonalConvenience) {
      final personalLines = parsed.lines.where(
        (line) => line.category == 'Personal',
      );
      if (personalLines.length < 2) {
        issues.add('expected_personal_convenience_lines');
      }
      if (personalLines.any((line) => line.use.name != 'personal')) {
        issues.add('personal_convenience_line_not_personal_use');
      }
    }
    if (receipt.expectedParkingFee != null) {
      final parkingLines = parsed.lines.where(
        (line) => line.category == 'Parking',
      );
      final hasExpectedParking = parkingLines.any((line) {
        return (line.subtotal - receipt.expectedParkingFee!).abs() <= .01;
      });
      if (!hasExpectedParking) {
        issues.add('missing_parking_fee_${receipt.expectedParkingFee}');
      }
    }
    if (receipt.expectedTax != null) {
      final actualTax = parsed.enteredTax;
      if (actualTax == null || (actualTax - receipt.expectedTax!).abs() > .01) {
        issues.add(
          'tax_expected_${receipt.expectedTax}_got_${parsed.enteredTax}',
        );
      } else if (parsed.enteredTotal != null) {
        final taxAdjustedTotal = parsed.lineSubtotal + actualTax;
        _expectNear(
          issues,
          field: 'line_subtotal_plus_tax',
          actual: taxAdjustedTotal,
          expected: parsed.enteredTotal!,
        );
      }
    }
    if (receipt.expectPerUnitDiscount &&
        parsed.diagnostics.parserTaskCount('fuel_amount_math_needs_review') >
            0) {
      issues.add('per_unit_discount_fuel_math_needs_review');
    }
    if (receipt.expectAlternatePrice &&
        parsed.diagnostics.parserTaskCount('fuel_amount_math_needs_review') >
            0) {
      issues.add('alternate_price_fuel_math_needs_review');
    }
    if (receipt.expectMissingVolume &&
        parsed.diagnostics.parserTaskCount('fuel_quantity_needs_review') > 0) {
      issues.add('missing_volume_quantity_needs_review');
    }
    if (receipt.expectEvMissingKwh &&
        parsed.diagnostics.parserTaskCount('fuel_quantity_needs_review') > 0) {
      issues.add('ev_missing_kwh_quantity_needs_review');
    }
    if (receipt.expectedPrepayRefundAmount != null) {
      final leakedRefundLine = parsed.lines.any((line) {
        return (line.subtotal - receipt.expectedPrepayRefundAmount!).abs() <=
            .01;
      });
      if (leakedRefundLine) {
        issues.add('prepay_refund_leaked_as_expense_line');
      }
    }
    if (receipt.expectedCarWashAmount != null) {
      final vehicleSupplyLines = parsed.lines.where(
        (line) => line.category == 'Vehicle Supplies',
      );
      final hasExpectedCarWash = vehicleSupplyLines.any((line) {
        return (line.subtotal - receipt.expectedCarWashAmount!).abs() <= .01;
      });
      if (!hasExpectedCarWash) {
        issues.add('missing_car_wash_${receipt.expectedCarWashAmount}');
      }
    }

    if (issues.isNotEmpty) {
      failures.add(
        _FuelSyntheticFailure(
          caseName: receipt.name,
          issues: issues,
          fuelLineDetails: fuelLines
              .map(
                (line) => {
                  'description': line.description,
                  'subtotal': line.subtotal,
                  'fuelType': line.fuelType,
                  'quantity': line.quantity,
                  'unit': line.unit,
                  'unitPrice': line.unitPrice,
                  'rawReceiptText': line.rawReceiptText,
                },
              )
              .toList(),
          receiptText: receipt.text,
        ),
      );
    }
  }

  return _FuelSyntheticReport(
    caseCount: cases.length,
    failedCaseCount: failures.length,
    failures: failures,
    fuelTypeCounts: fuelTypeCounts,
    unitCounts: unitCounts,
    localeCounts: localeCounts,
    mixedReceiptCount: mixedReceiptCount,
    cashReceiptCount: cashReceiptCount,
    evReceiptCount: evReceiptCount,
    cngReceiptCount: cngReceiptCount,
    lngReceiptCount: lngReceiptCount,
    propaneReceiptCount: propaneReceiptCount,
    hydrogenReceiptCount: hydrogenReceiptCount,
    dirtyReceiptCount: dirtyReceiptCount,
    discountReceiptCount: discountReceiptCount,
    evFeeReceiptCount: evFeeReceiptCount,
    commaDecimalReceiptCount: commaDecimalReceiptCount,
    preauthHoldReceiptCount: preauthHoldReceiptCount,
    literReceiptCount: literReceiptCount,
    partialFillReceiptCount: partialFillReceiptCount,
    fleetTenderReceiptCount: fleetTenderReceiptCount,
    personalConvenienceReceiptCount: personalConvenienceReceiptCount,
    multiFuelReceiptCount: multiFuelReceiptCount,
    evParkingReceiptCount: evParkingReceiptCount,
    evTaxReceiptCount: evTaxReceiptCount,
    liquidExciseTaxReceiptCount: liquidExciseTaxReceiptCount,
    perUnitDiscountReceiptCount: perUnitDiscountReceiptCount,
    carWashReceiptCount: carWashReceiptCount,
    alternatePriceReceiptCount: alternatePriceReceiptCount,
    missingVolumeReceiptCount: missingVolumeReceiptCount,
    evMissingKwhReceiptCount: evMissingKwhReceiptCount,
    prepayRefundReceiptCount: prepayRefundReceiptCount,
    rewardUnitDiscountReceiptCount: rewardUnitDiscountReceiptCount,
    hubometerReceiptCount: hubometerReceiptCount,
    nonEthanolReceiptCount: nonEthanolReceiptCount,
    warehouseFuelReceiptCount: warehouseFuelReceiptCount,
    privateIdentityReceiptCount: privateIdentityReceiptCount,
    dispenserShorthandReceiptCount: dispenserShorthandReceiptCount,
  );
}

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

void _checkExpectedFuelLine(
  List<String> issues,
  Iterable<dynamic> fuelLines, {
  required String fuelType,
  required double quantity,
  required double amount,
  required double unitPrice,
  required String unit,
  required int? odometer,
  required String fillType,
}) {
  final matches = fuelLines.where((line) => line.fuelType == fuelType);
  if (matches.length != 1) {
    issues.add('fuel_type_${fuelType}_line_count_${matches.length}');
    return;
  }
  final fuel = matches.single;
  _expectNear(
    issues,
    field: '${fuelType}_quantity',
    actual: fuel.quantity,
    expected: quantity,
  );
  _expectNear(
    issues,
    field: '${fuelType}_subtotal',
    actual: fuel.subtotal,
    expected: amount,
  );
  _expectNear(
    issues,
    field: '${fuelType}_unit_price',
    actual: fuel.unitPrice,
    expected: unitPrice,
    tolerance: .015,
  );
  if (fuel.unit != unit) {
    issues.add('${fuelType}_unit_expected_${unit}_got_${fuel.unit}');
  }
  if (odometer != null && fuel.odometerReading != odometer) {
    issues.add(
      '${fuelType}_odometer_expected_${odometer}_got_${fuel.odometerReading}',
    );
  }
  if (fuel.fillType != fillType) {
    issues.add(
      '${fuelType}_fill_type_expected_${fillType}_got_${fuel.fillType}',
    );
  }
}

String _commaDecimalText(String text) {
  return text.replaceAllMapped(RegExp(r'\b(\d+)\.(\d{2,4})\b'), (match) {
    return '${match.group(1)},${match.group(2)}';
  });
}

String _dirtyFuelText(String text) {
  return text
      .replaceAll('PRICE', 'PR1CE')
      .replaceAll('Price', 'Pr1ce')
      .replaceAll('GALLONS', 'GALL0NS')
      .replaceAll('Gallons', 'Gall0ns')
      .replaceAll('FUEL', 'FUE1')
      .replaceAll('Fuel', 'Fue1')
      .replaceAll('DIESEL', 'D1ESEL')
      .replaceAll('Diesel', 'D1esel')
      .replaceAll(' GAL ', ' GA1 ');
}

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
Venta Combustible $total$discountLine$mixed$cash
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

String _evReceipt({
  required String merchant,
  required int day,
  required double quantity,
  required double unitPrice,
  required double amount,
  required int odometer,
  required int layout,
  required double? sessionFee,
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

class _FuelSyntheticRunnerConfig {
  const _FuelSyntheticRunnerConfig({
    required this.count,
    required this.seed,
    required this.seedCount,
    required this.failUnder,
    required this.json,
    required this.summaryJson,
  });

  factory _FuelSyntheticRunnerConfig.fromArgs(List<String> args) {
    var count = _defaultCount;
    var seed = 0;
    var seedCount = 1;
    var failUnder = _defaultFailUnder;
    var json = false;
    var summaryJson = false;
    var countWasSet = false;

    for (final arg in args) {
      if (arg == '--json') {
        json = true;
      } else if (arg == '--summary-json') {
        summaryJson = true;
      } else if (arg.startsWith('--count=')) {
        count = int.parse(arg.substring('--count='.length));
        countWasSet = true;
      } else if (arg.startsWith('--preset=')) {
        final preset = arg.substring('--preset='.length);
        final presetCount = _presetCounts[preset];
        if (presetCount == null) {
          stderr.writeln(
            '--preset must be one of: ${_presetCounts.keys.join(', ')}.',
          );
          exit(64);
        }
        if (!countWasSet) count = presetCount;
      } else if (arg.startsWith('--seed=')) {
        seed = int.parse(arg.substring('--seed='.length));
      } else if (arg.startsWith('--seed-count=')) {
        seedCount = int.parse(arg.substring('--seed-count='.length));
      } else if (arg.startsWith('--fail-under=')) {
        failUnder = double.parse(arg.substring('--fail-under='.length));
      } else if (arg == '--help' || arg == '-h') {
        stdout.writeln(
          'Usage: dart run tool/fuel_synthetic_parser_runner.dart '
          '[--preset=smoke|milestone] [--count=$_defaultCount] '
          '[--seed=0] [--seed-count=1] '
          '[--fail-under=$_defaultFailUnder] [--json|--summary-json]',
        );
        exit(0);
      }
    }

    if (count < 1) {
      stderr.writeln('--count must be at least 1.');
      exit(64);
    }
    if (seedCount < 1) {
      stderr.writeln('--seed-count must be at least 1.');
      exit(64);
    }

    return _FuelSyntheticRunnerConfig(
      count: count,
      seed: seed,
      seedCount: seedCount,
      failUnder: failUnder,
      json: json,
      summaryJson: summaryJson,
    );
  }

  final int count;
  final int seed;
  final int seedCount;
  final double failUnder;
  final bool json;
  final bool summaryJson;
}

class _FuelSyntheticReport {
  const _FuelSyntheticReport({
    required this.caseCount,
    required this.failedCaseCount,
    required this.failures,
    required this.fuelTypeCounts,
    required this.unitCounts,
    required this.localeCounts,
    required this.mixedReceiptCount,
    required this.cashReceiptCount,
    required this.evReceiptCount,
    required this.cngReceiptCount,
    required this.lngReceiptCount,
    required this.propaneReceiptCount,
    required this.hydrogenReceiptCount,
    required this.dirtyReceiptCount,
    required this.discountReceiptCount,
    required this.evFeeReceiptCount,
    required this.commaDecimalReceiptCount,
    required this.preauthHoldReceiptCount,
    required this.literReceiptCount,
    required this.partialFillReceiptCount,
    required this.fleetTenderReceiptCount,
    required this.personalConvenienceReceiptCount,
    required this.multiFuelReceiptCount,
    required this.evParkingReceiptCount,
    required this.evTaxReceiptCount,
    required this.liquidExciseTaxReceiptCount,
    required this.perUnitDiscountReceiptCount,
    required this.carWashReceiptCount,
    required this.alternatePriceReceiptCount,
    required this.missingVolumeReceiptCount,
    required this.evMissingKwhReceiptCount,
    required this.prepayRefundReceiptCount,
    required this.rewardUnitDiscountReceiptCount,
    required this.hubometerReceiptCount,
    required this.nonEthanolReceiptCount,
    required this.warehouseFuelReceiptCount,
    required this.privateIdentityReceiptCount,
    required this.dispenserShorthandReceiptCount,
  });

  final int caseCount;
  final int failedCaseCount;
  final List<_FuelSyntheticFailure> failures;
  final Map<String, int> fuelTypeCounts;
  final Map<String, int> unitCounts;
  final Map<String, int> localeCounts;
  final int mixedReceiptCount;
  final int cashReceiptCount;
  final int evReceiptCount;
  final int cngReceiptCount;
  final int lngReceiptCount;
  final int propaneReceiptCount;
  final int hydrogenReceiptCount;
  final int dirtyReceiptCount;
  final int discountReceiptCount;
  final int evFeeReceiptCount;
  final int commaDecimalReceiptCount;
  final int preauthHoldReceiptCount;
  final int literReceiptCount;
  final int partialFillReceiptCount;
  final int fleetTenderReceiptCount;
  final int personalConvenienceReceiptCount;
  final int multiFuelReceiptCount;
  final int evParkingReceiptCount;
  final int evTaxReceiptCount;
  final int liquidExciseTaxReceiptCount;
  final int perUnitDiscountReceiptCount;
  final int carWashReceiptCount;
  final int alternatePriceReceiptCount;
  final int missingVolumeReceiptCount;
  final int evMissingKwhReceiptCount;
  final int prepayRefundReceiptCount;
  final int rewardUnitDiscountReceiptCount;
  final int hubometerReceiptCount;
  final int nonEthanolReceiptCount;
  final int warehouseFuelReceiptCount;
  final int privateIdentityReceiptCount;
  final int dispenserShorthandReceiptCount;

  int get passedCaseCount => caseCount - failedCaseCount;
  double get accuracy => caseCount == 0 ? 0 : passedCaseCount / caseCount;

  Map<String, Object?> toJson({required double failUnder}) {
    return {
      'schema': 'fuel_synthetic_parser_runner_v1',
      'caseCount': caseCount,
      'passedCaseCount': passedCaseCount,
      'failedCaseCount': failedCaseCount,
      'accuracy': accuracy,
      'failUnder': failUnder,
      'blockers': [
        if (accuracy < failUnder)
          'Fuel synthetic parser accuracy ${accuracy.toStringAsFixed(4)} '
              'is below fail-under ${failUnder.toStringAsFixed(4)}.',
      ],
      'fuelTypeCounts': fuelTypeCounts,
      'unitCounts': unitCounts,
      'localeCounts': localeCounts,
      'mixedReceiptCount': mixedReceiptCount,
      'cashReceiptCount': cashReceiptCount,
      'evReceiptCount': evReceiptCount,
      'cngReceiptCount': cngReceiptCount,
      'lngReceiptCount': lngReceiptCount,
      'propaneReceiptCount': propaneReceiptCount,
      'hydrogenReceiptCount': hydrogenReceiptCount,
      'dirtyReceiptCount': dirtyReceiptCount,
      'discountReceiptCount': discountReceiptCount,
      'evFeeReceiptCount': evFeeReceiptCount,
      'commaDecimalReceiptCount': commaDecimalReceiptCount,
      'preauthHoldReceiptCount': preauthHoldReceiptCount,
      'literReceiptCount': literReceiptCount,
      'partialFillReceiptCount': partialFillReceiptCount,
      'fleetTenderReceiptCount': fleetTenderReceiptCount,
      'personalConvenienceReceiptCount': personalConvenienceReceiptCount,
      'multiFuelReceiptCount': multiFuelReceiptCount,
      'evParkingReceiptCount': evParkingReceiptCount,
      'evTaxReceiptCount': evTaxReceiptCount,
      'liquidExciseTaxReceiptCount': liquidExciseTaxReceiptCount,
      'perUnitDiscountReceiptCount': perUnitDiscountReceiptCount,
      'carWashReceiptCount': carWashReceiptCount,
      'alternatePriceReceiptCount': alternatePriceReceiptCount,
      'missingVolumeReceiptCount': missingVolumeReceiptCount,
      'evMissingKwhReceiptCount': evMissingKwhReceiptCount,
      'prepayRefundReceiptCount': prepayRefundReceiptCount,
      'rewardUnitDiscountReceiptCount': rewardUnitDiscountReceiptCount,
      'hubometerReceiptCount': hubometerReceiptCount,
      'nonEthanolReceiptCount': nonEthanolReceiptCount,
      'warehouseFuelReceiptCount': warehouseFuelReceiptCount,
      'privateIdentityReceiptCount': privateIdentityReceiptCount,
      'dispenserShorthandReceiptCount': dispenserShorthandReceiptCount,
      'failures': failures.take(25).map((failure) => failure.toJson()).toList(),
    };
  }

  Map<String, Object?> toSummaryJson({required double failUnder}) {
    final report = toJson(failUnder: failUnder);
    report.remove('failures');
    return report;
  }
}

class _FuelSyntheticFailure {
  const _FuelSyntheticFailure({
    required this.caseName,
    required this.issues,
    required this.fuelLineDetails,
    required this.receiptText,
  });

  final String caseName;
  final List<String> issues;
  final List<Map<String, Object?>> fuelLineDetails;
  final String receiptText;

  Map<String, Object?> toJson() {
    return {
      'caseName': caseName,
      'issues': issues,
      'fuelLineDetails': fuelLineDetails,
      'receiptText': receiptText,
    };
  }
}

class _FuelSyntheticProduct {
  const _FuelSyntheticProduct({
    required this.label,
    required this.spanishLabel,
    required this.fuelType,
    required this.unit,
    required this.basePrice,
  });

  final String label;
  final String spanishLabel;
  final String fuelType;
  final String unit;
  final double basePrice;
}

class _FuelSyntheticReceipt {
  const _FuelSyntheticReceipt({
    required this.name,
    required this.text,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.unit,
    required this.fuelType,
    required this.expectedFillType,
    required this.locale,
    required this.odometer,
    required this.expectMixed,
    required this.expectCashExclusion,
    required this.expectDirtyText,
    required this.expectCommaDecimals,
    required this.expectPreauthHold,
    required this.expectFleetTenderExclusion,
    required this.expectPersonalConvenience,
    required this.expectMultiFuel,
    required this.expectPerUnitDiscount,
    required this.expectRewardUnitDiscount,
    required this.expectAlternatePrice,
    required this.expectMissingVolume,
    required this.expectEvMissingKwh,
    required this.expectHubometer,
    required this.expectNonEthanol,
    required this.expectWarehouseFuel,
    required this.expectPrivateIdentity,
    required this.expectDispenserShorthand,
    required this.secondaryQuantity,
    required this.secondaryUnitPrice,
    required this.secondaryAmount,
    required this.secondaryUnit,
    required this.secondaryFuelType,
    required this.expectedDiscountAdjustment,
    required this.expectedChargingFee,
    required this.expectedParkingFee,
    required this.expectedTax,
    required this.expectedCarWashAmount,
    required this.expectedPrepayRefundAmount,
  });

  final String name;
  final String text;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String unit;
  final String fuelType;
  final String expectedFillType;
  final String locale;
  final int? odometer;
  final bool expectMixed;
  final bool expectCashExclusion;
  final bool expectDirtyText;
  final bool expectCommaDecimals;
  final bool expectPreauthHold;
  final bool expectFleetTenderExclusion;
  final bool expectPersonalConvenience;
  final bool expectMultiFuel;
  final bool expectPerUnitDiscount;
  final bool expectRewardUnitDiscount;
  final bool expectAlternatePrice;
  final bool expectMissingVolume;
  final bool expectEvMissingKwh;
  final bool expectHubometer;
  final bool expectNonEthanol;
  final bool expectWarehouseFuel;
  final bool expectPrivateIdentity;
  final bool expectDispenserShorthand;
  final double? secondaryQuantity;
  final double? secondaryUnitPrice;
  final double? secondaryAmount;
  final String? secondaryUnit;
  final String? secondaryFuelType;
  final double? expectedDiscountAdjustment;
  final double? expectedChargingFee;
  final double? expectedParkingFee;
  final double? expectedTax;
  final double? expectedCarWashAmount;
  final double? expectedPrepayRefundAmount;
}

const _products = [
  _FuelSyntheticProduct(
    label: 'REG UNL',
    spanishLabel: 'Gasolina Regular',
    fuelType: 'Gasoline',
    unit: 'gallon',
    basePrice: 3.199,
  ),
  _FuelSyntheticProduct(
    label: 'PREMIUM UNLEADED',
    spanishLabel: 'Gasolina Premium',
    fuelType: 'Gasoline',
    unit: 'gallon',
    basePrice: 4.099,
  ),
  _FuelSyntheticProduct(
    label: 'DIESEL',
    spanishLabel: 'Diésel',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.899,
  ),
  _FuelSyntheticProduct(
    label: '#2 ULSD',
    spanishLabel: 'Diésel No. 2',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.849,
  ),
  _FuelSyntheticProduct(
    label: 'ULTRA LOW SULFUR DIESEL',
    spanishLabel: 'Diésel Ultra Bajo Azufre',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.869,
  ),
  _FuelSyntheticProduct(
    label: 'ON-ROAD CLEAR DIESEL',
    spanishLabel: 'Diésel Claro de Carretera',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.879,
  ),
  _FuelSyntheticProduct(
    label: 'B20 DIESEL',
    spanishLabel: 'B20 Diésel',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.799,
  ),
  _FuelSyntheticProduct(
    label: 'B99 BIODIESEL',
    spanishLabel: 'Biodiesel B99',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.949,
  ),
  _FuelSyntheticProduct(
    label: 'OFF ROAD DIESEL',
    spanishLabel: 'Diésel Rojo',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 3.499,
  ),
  _FuelSyntheticProduct(
    label: 'RD99 RENEWABLE DIESEL',
    spanishLabel: 'Diésel Renovable RD99',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 4.099,
  ),
  _FuelSyntheticProduct(
    label: 'HVO100 RENEWABLE DIESEL',
    spanishLabel: 'Diésel Renovable HVO100',
    fuelType: 'Diesel',
    unit: 'gallon',
    basePrice: 4.149,
  ),
  _FuelSyntheticProduct(
    label: 'DEF FLUID',
    spanishLabel: 'Fluido DEF',
    fuelType: 'DEF',
    unit: 'gallon',
    basePrice: 4.299,
  ),
  _FuelSyntheticProduct(
    label: 'KEROSENE',
    spanishLabel: 'Kerosene',
    fuelType: 'Kerosene',
    unit: 'gallon',
    basePrice: 4.899,
  ),
  _FuelSyntheticProduct(
    label: 'K-1 KEROSENE',
    spanishLabel: 'Queroseno K-1',
    fuelType: 'Kerosene',
    unit: 'gallon',
    basePrice: 4.919,
  ),
  _FuelSyntheticProduct(
    label: 'E85 FLEX FUEL',
    spanishLabel: 'E85 Flex Fuel',
    fuelType: 'E85',
    unit: 'gallon',
    basePrice: 2.799,
  ),
  _FuelSyntheticProduct(
    label: 'E-85 FLEXFUEL',
    spanishLabel: 'E-85 Combustible Flexible',
    fuelType: 'E85',
    unit: 'gallon',
    basePrice: 2.819,
  ),
  _FuelSyntheticProduct(
    label: 'E15 UNLEADED 88',
    spanishLabel: 'E15 Gasolina',
    fuelType: 'E15',
    unit: 'gallon',
    basePrice: 3.059,
  ),
  _FuelSyntheticProduct(
    label: 'E-20 ETHANOL 20',
    spanishLabel: 'Etanol 20',
    fuelType: 'E20',
    unit: 'gallon',
    basePrice: 2.959,
  ),
  _FuelSyntheticProduct(
    label: 'E30 FLEX FUEL',
    spanishLabel: 'Etanol 30',
    fuelType: 'E30',
    unit: 'gallon',
    basePrice: 2.899,
  ),
  _FuelSyntheticProduct(
    label: 'E50 FLEX FUEL',
    spanishLabel: 'Etanol 50',
    fuelType: 'E50',
    unit: 'gallon',
    basePrice: 2.849,
  ),
  _FuelSyntheticProduct(
    label: 'E10 ETHANOL 10',
    spanishLabel: 'E10 Gasolina',
    fuelType: 'E10',
    unit: 'gallon',
    basePrice: 3.249,
  ),
  _FuelSyntheticProduct(
    label: 'E-0 ETHANOL FREE',
    spanishLabel: 'E-0 Sin Etanol',
    fuelType: 'Gasoline',
    unit: 'gallon',
    basePrice: 3.599,
  ),
  _FuelSyntheticProduct(
    label: 'CNG COMPRESSED NATURAL GAS',
    spanishLabel: 'Gas Natural Comprimido',
    fuelType: 'CNG',
    unit: 'GGE',
    basePrice: 2.799,
  ),
  _FuelSyntheticProduct(
    label: 'RNG RENEWABLE NATURAL GAS',
    spanishLabel: 'Gas Natural Renovable',
    fuelType: 'CNG',
    unit: 'GGE',
    basePrice: 2.829,
  ),
  _FuelSyntheticProduct(
    label: 'LNG LIQUEFIED NATURAL GAS',
    spanishLabel: 'Gas Natural Licuado',
    fuelType: 'LNG',
    unit: 'DGE',
    basePrice: 3.129,
  ),
  _FuelSyntheticProduct(
    label: 'RNG LIQUEFIED NATURAL GAS',
    spanishLabel: 'Gas Natural Renovable',
    fuelType: 'LNG',
    unit: 'DGE',
    basePrice: 3.159,
  ),
  _FuelSyntheticProduct(
    label: 'LPG AUTOGAS',
    spanishLabel: 'Propano Autogas',
    fuelType: 'Propane',
    unit: 'gallon',
    basePrice: 2.649,
  ),
  _FuelSyntheticProduct(
    label: 'L.P. GAS',
    spanishLabel: 'Gas LP',
    fuelType: 'Propane',
    unit: 'gallon',
    basePrice: 2.669,
  ),
  _FuelSyntheticProduct(
    label: 'H2 HYDROGEN FUEL',
    spanishLabel: 'Hidrogeno H2',
    fuelType: 'Hydrogen',
    unit: 'kg',
    basePrice: 15.999,
  ),
  _FuelSyntheticProduct(
    label: 'ENERGY',
    spanishLabel: 'Energia',
    fuelType: 'Electric',
    unit: 'kWh',
    basePrice: .439,
  ),
];

const _merchants = [
  'SHELL',
  'EXXON',
  'PILOT TRVL CTR',
  'RIVER ROAD MART 418',
  'SUNOCO',
  'QUIKTRIP',
  'WAWA',
  'RACEWAY',
  ..._warehouseFuelMerchants,
];

const _warehouseFuelMerchants = [
  'KROGER FUEL CENTER',
  'COSTCO GASOLINE',
  'SAMS CLUB FUEL',
];
