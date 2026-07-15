import 'package:flutter_test/flutter_test.dart';
import '../tool/fuel_synthetic_parser_runner.dart';

const _runnerTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'fuel synthetic parser runner reports compact deterministic fuel coverage',
    () async {
      final report = runFuelSyntheticParser(count: 48, seed: 0);

      expect(report['schema'], 'fuel_synthetic_parser_runner_v1');
      expect(report['caseCount'], 48);
      expect(report['passedCaseCount'], 48);
      expect(report['failedCaseCount'], 0);
      expect(report['accuracy'], 1.0);
      expect(report['blockers'], isEmpty);
      expect(report['mixedReceiptCount'], greaterThan(0));
      expect(report['cashReceiptCount'], greaterThan(0));
      expect(report['evReceiptCount'], greaterThan(0));
      expect(report['cngReceiptCount'], greaterThan(0));
      expect(report['lngReceiptCount'], greaterThan(0));
      expect(report['propaneReceiptCount'], greaterThan(0));
      expect(report['hydrogenReceiptCount'], greaterThan(0));
      expect(report['dirtyReceiptCount'], greaterThan(0));
      expect(report['discountReceiptCount'], greaterThan(0));
      expect(report['evFeeReceiptCount'], greaterThan(0));
      expect(report['commaDecimalReceiptCount'], greaterThan(0));
      expect(report['preauthHoldReceiptCount'], greaterThan(0));
      expect(report['literReceiptCount'], greaterThan(0));
      expect(report['partialFillReceiptCount'], greaterThan(0));
      expect(report['fleetTenderReceiptCount'], greaterThan(0));
      expect(report['personalConvenienceReceiptCount'], greaterThan(0));
      expect(report['multiFuelReceiptCount'], greaterThan(0));
      expect(report['evParkingReceiptCount'], greaterThan(0));
      expect(report['evTaxReceiptCount'], greaterThan(0));
      expect(report['liquidExciseTaxReceiptCount'], greaterThan(0));
      expect(report['perUnitDiscountReceiptCount'], greaterThan(0));
      expect(report['carWashReceiptCount'], greaterThan(0));
      expect(report['alternatePriceReceiptCount'], greaterThan(0));
      expect(report['missingVolumeReceiptCount'], greaterThan(0));
      expect(report['evMissingKwhReceiptCount'], greaterThan(0));
      expect(report['prepayRefundReceiptCount'], greaterThan(0));
      expect(report['rewardUnitDiscountReceiptCount'], greaterThan(0));
      expect(report['hubometerReceiptCount'], greaterThan(0));
      expect(report['nonEthanolReceiptCount'], greaterThan(0));
      expect(report['warehouseFuelReceiptCount'], greaterThan(0));
      expect(report['privateIdentityReceiptCount'], greaterThan(0));
      expect(report['dispenserShorthandReceiptCount'], greaterThan(0));
      expect(
        report['fuelTypeCounts'],
        containsPair('Gasoline', greaterThan(0)),
      );
      expect(report['fuelTypeCounts'], containsPair('Diesel', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('DEF', greaterThan(0)));
      expect(
        report['fuelTypeCounts'],
        containsPair('Kerosene', greaterThan(0)),
      );
      expect(report['fuelTypeCounts'], containsPair('E85', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('E15', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('E30', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('E10', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('CNG', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('LNG', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('Propane', greaterThan(0)));
      expect(
        report['fuelTypeCounts'],
        containsPair('Hydrogen', greaterThan(0)),
      );
      expect(
        report['fuelTypeCounts'],
        containsPair('Electric', greaterThan(0)),
      );
      expect(report['unitCounts'], containsPair('gallon', greaterThan(0)));
      expect(report['unitCounts'], containsPair('GGE', greaterThan(0)));
      expect(report['unitCounts'], containsPair('DGE', greaterThan(0)));
      expect(report['unitCounts'], containsPair('kg', greaterThan(0)));
      expect(report['unitCounts'], containsPair('kWh', greaterThan(0)));
      expect(
        report['localeCounts'],
        containsPair('spanish_us', greaterThan(0)),
      );
      expect(
        report['localeCounts'],
        containsPair('english_us', greaterThan(0)),
      );

      expect(report['failures'], isEmpty);
    },
    timeout: _runnerTimeout,
  );

  test(
    'fuel synthetic milestone preset runs a larger compact sweep',
    () async {
      final report = runFuelSyntheticParser(count: 500, seed: 0);

      expect(report['schema'], 'fuel_synthetic_parser_runner_v1');
      expect(report['caseCount'], 500);
      expect(report['passedCaseCount'], 500);
      expect(report['failedCaseCount'], 0);
      expect(report['accuracy'], 1.0);
      expect(report['blockers'], isEmpty);
      expect(report['fuelTypeCounts'], containsPair('E20', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('E50', greaterThan(0)));
      expect(report['cngReceiptCount'], greaterThan(0));
      expect(report['lngReceiptCount'], greaterThan(0));
      expect(report['propaneReceiptCount'], greaterThan(0));
      expect(report['hydrogenReceiptCount'], greaterThan(0));
      expect(report['evFeeReceiptCount'], greaterThan(0));
      expect(report['dirtyReceiptCount'], greaterThan(0));
      expect(report['discountReceiptCount'], greaterThan(0));
      expect(report['commaDecimalReceiptCount'], greaterThan(0));
      expect(report['preauthHoldReceiptCount'], greaterThan(0));
      expect(report['literReceiptCount'], greaterThan(0));
      expect(report['partialFillReceiptCount'], greaterThan(0));
      expect(report['fleetTenderReceiptCount'], greaterThan(0));
      expect(report['personalConvenienceReceiptCount'], greaterThan(0));
      expect(report['multiFuelReceiptCount'], greaterThan(0));
      expect(report['evParkingReceiptCount'], greaterThan(0));
      expect(report['evTaxReceiptCount'], greaterThan(0));
      expect(report['liquidExciseTaxReceiptCount'], greaterThan(0));
      expect(report['perUnitDiscountReceiptCount'], greaterThan(0));
      expect(report['carWashReceiptCount'], greaterThan(0));
      expect(report['alternatePriceReceiptCount'], greaterThan(0));
      expect(report['missingVolumeReceiptCount'], greaterThan(0));
      expect(report['evMissingKwhReceiptCount'], greaterThan(0));
      expect(report['prepayRefundReceiptCount'], greaterThan(0));
      expect(report['rewardUnitDiscountReceiptCount'], greaterThan(0));
      expect(report['hubometerReceiptCount'], greaterThan(0));
      expect(report['nonEthanolReceiptCount'], greaterThan(0));
      expect(report['warehouseFuelReceiptCount'], greaterThan(0));
      expect(report['privateIdentityReceiptCount'], greaterThan(0));
      expect(report['dispenserShorthandReceiptCount'], greaterThan(0));

      expect(report['failures'], isEmpty);
    },
    timeout: _runnerTimeout,
  );

  test(
    'fuel synthetic runner supports compact multi-seed sweeps',
    () async {
      final report = runFuelSyntheticParser(count: 60, seed: 0, seedCount: 3);

      expect(report['schema'], 'fuel_synthetic_parser_runner_v1');
      expect(report['caseCount'], 180);
      expect(report['passedCaseCount'], 180);
      expect(report['failedCaseCount'], 0);
      expect(report['accuracy'], 1.0);
      expect(report['blockers'], isEmpty);
      expect(
        report['fuelTypeCounts'],
        containsPair('Gasoline', greaterThan(0)),
      );
      expect(report['fuelTypeCounts'], containsPair('Diesel', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('CNG', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('LNG', greaterThan(0)));
      expect(report['fuelTypeCounts'], containsPair('Propane', greaterThan(0)));
      expect(
        report['fuelTypeCounts'],
        containsPair('Hydrogen', greaterThan(0)),
      );
      expect(
        report['fuelTypeCounts'],
        containsPair('Electric', greaterThan(0)),
      );
      expect(report['unitCounts'], containsPair('GGE', greaterThan(0)));
      expect(report['unitCounts'], containsPair('DGE', greaterThan(0)));
      expect(report['unitCounts'], containsPair('kg', greaterThan(0)));
      expect(
        report['localeCounts'],
        containsPair('spanish_us', greaterThan(0)),
      );
      expect(
        report['localeCounts'],
        containsPair('english_us', greaterThan(0)),
      );
      expect(report['commaDecimalReceiptCount'], greaterThan(0));
      expect(report['preauthHoldReceiptCount'], greaterThan(0));
      expect(report['literReceiptCount'], greaterThan(0));
      expect(report['partialFillReceiptCount'], greaterThan(0));
      expect(report['fleetTenderReceiptCount'], greaterThan(0));
      expect(report['personalConvenienceReceiptCount'], greaterThan(0));
      expect(report['multiFuelReceiptCount'], greaterThan(0));
      expect(report['evParkingReceiptCount'], greaterThan(0));
      expect(report['evTaxReceiptCount'], greaterThan(0));
      expect(report['liquidExciseTaxReceiptCount'], greaterThan(0));
      expect(report['perUnitDiscountReceiptCount'], greaterThan(0));
      expect(report['carWashReceiptCount'], greaterThan(0));
      expect(report['alternatePriceReceiptCount'], greaterThan(0));
      expect(report['missingVolumeReceiptCount'], greaterThan(0));
      expect(report['evMissingKwhReceiptCount'], greaterThan(0));
      expect(report['prepayRefundReceiptCount'], greaterThan(0));
      expect(report['rewardUnitDiscountReceiptCount'], greaterThan(0));
      expect(report['hubometerReceiptCount'], greaterThan(0));
      expect(report['nonEthanolReceiptCount'], greaterThan(0));
      expect(report['warehouseFuelReceiptCount'], greaterThan(0));
      expect(report['privateIdentityReceiptCount'], greaterThan(0));
      expect(report['dispenserShorthandReceiptCount'], greaterThan(0));

      expect(report['failures'], isEmpty);
    },
    timeout: _runnerTimeout,
  );

  test(
    'fuel synthetic runner summary excludes failure evidence payloads',
    () async {
      final report = runFuelSyntheticParser(count: 24, seed: 0);

      expect(report['caseCount'], 24);
      expect(report['failedCaseCount'], 0);
      expect(report['blockers'], isEmpty);
      final summary = Map<String, Object?>.from(report)..remove('failures');
      expect(summary.containsKey('failures'), isFalse);
    },
    timeout: _runnerTimeout,
  );
}
