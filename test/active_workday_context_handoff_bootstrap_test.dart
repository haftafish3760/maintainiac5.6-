// Production wiring regression for active-workday context handoff recovery.
//
// Owns the bootstrap contract between main.dart and the shared coordinator.
// It does not test the coordinator's behavior or Dashboard interaction UI.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'app bootstrap recovers handoffs before exposing Dashboard routes',
    () async {
      final source = await File('lib/main.dart').readAsString();

      expect(source, contains('ActiveWorkdayContextHandoffCoordinator('));
      expect(source, contains('records: durableRecordStore'));
      expect(
        source,
        contains('await activeWorkdayContextHandoffs.recoverPending()'),
      );
      expect(source, contains('ActiveWorkdayContextHandoffScope('));
      expect(source, contains('coordinator: activeWorkdayContextHandoffs'));
    },
  );
}
