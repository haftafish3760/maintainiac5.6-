import 'package:flutter_test/flutter_test.dart';
import '../tool/fuel_parser_field_benchmark.dart';

void main() {
  test(
    'field benchmark keeps real-redacted evidence distinct from regressions',
    () {
      final report = runFuelParserFieldBenchmark();

      expect(report['realRedactedCaseCount'], 1);
      expect(report['independentCaseCount'], 0);
      expect(report['merchantFamilyCount'], 0);
      expect(report['fieldAccuracy'], 1.0);
      expect(report['commercialValidationReady'], isFalse);
      expect(report['blockers'], contains(contains('at least 25')));
    },
  );
}
