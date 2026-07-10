part of 'fuel_synthetic_parser_runner.dart';

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
