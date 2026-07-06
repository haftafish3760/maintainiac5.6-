import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt capture flow does not silently enable Receipt Assist', () async {
    final settingsStore = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart',
    ).readAsString();
    final flowHelpers = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart',
    ).readAsString();

    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedReceiptFill, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedExpenses, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedMaterials, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedMaintenance, false)'),
    );
    expect(
      flowHelpers,
      contains('settings?.appAssistedEnabledFor(area) ?? false'),
    );
    expect(flowHelpers, isNot(contains('area == null ? true')));
    expect(flowHelpers, isNot(contains('?? true)')));
  });
}
