part of 'fuel_synthetic_parser_runner.dart';

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
    if (receipt.expectPrivateIdentity) {
      final leakedIdentityLine = parsed.lines.any((line) {
        return RegExp(
          r'\b(member|driver\s+id|vehicle\s+id|vin|license\s+plate)\b',
          caseSensitive: false,
        ).hasMatch(line.description);
      });
      if (leakedIdentityLine) {
        issues.add('private_identity_leaked_as_item_description');
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
