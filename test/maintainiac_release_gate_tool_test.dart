import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/maintainiac_release_gate.dart';

void main() {
  test('release gate tool emits surgical command plan', () {
    final stdout = _BufferSink();
    final stderr = _BufferSink();

    final exit = runMaintainiacReleaseGate(
      ['--commands-only'],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.text, isEmpty);
    expect(
      stdout.text,
      contains('flutter test test/maintainiac_qa_backbone_test.dart'),
    );
    expect(stdout.text, contains('accessibility localization runner'));
    expect(stdout.text, contains('cost quota runner'));
    expect(stdout.text, isNot(contains('firebase deploy')));
  });

  test('release gate tool emits JSON evidence', () {
    final stdout = _BufferSink();
    final stderr = _BufferSink();

    final exit = runMaintainiacReleaseGate(
      ['--json'],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.text, isEmpty);
    expect(stdout.text, contains('"name": "release_one_core_gate"'));
    expect(stdout.text, contains('"QA-COST-001"'));
    expect(stdout.text, contains('"QA-A11Y-L10N-001"'));
  });
}

class _BufferSink implements IOSink {
  final _buffer = StringBuffer();

  String get text => _buffer.toString();

  @override
  void writeln([Object? object = '']) {
    _buffer.writeln(object);
  }

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
