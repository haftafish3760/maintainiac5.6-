import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/maintainiac_qa_cases.dart';

void main() {
  test('QA cases tool prints labeled release blockers', () {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final exit = runMaintainiacQaCases(
      ['--priority', 'releaseBlocker'],
      stdout: _StringBufferSink(stdoutBuffer),
      stderr: _StringBufferSink(stderrBuffer),
    );

    expect(exit, 0);
    expect(stderrBuffer.toString(), isEmpty);
    expect(stdoutBuffer.toString(), contains('QA-BACKBONE-001'));
    expect(stdoutBuffer.toString(), contains('command:'));
  });

  test('QA cases tool prints JSON for automation', () {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final exit = runMaintainiacQaCases(
      ['--json', '--priority', 'core'],
      stdout: _StringBufferSink(stdoutBuffer),
      stderr: _StringBufferSink(stderrBuffer),
    );

    expect(exit, 0);
    expect(stderrBuffer.toString(), isEmpty);
    final decoded = jsonDecode(stdoutBuffer.toString()) as Map;
    expect(decoded['caseCount'], greaterThan(0));
    expect(decoded['cases'].toString(), contains('QA-DEVICE-001'));
  });

  test('QA cases tool rejects unknown priority', () {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final exit = runMaintainiacQaCases(
      ['--priority', 'missing'],
      stdout: _StringBufferSink(stdoutBuffer),
      stderr: _StringBufferSink(stderrBuffer),
    );

    expect(exit, 66);
    expect(stderrBuffer.toString(), contains('No QA cases found'));
  });
}

class _StringBufferSink implements IOSink {
  _StringBufferSink(this.buffer);

  final StringBuffer buffer;

  @override
  void write(Object? object) => buffer.write(object);

  @override
  void writeln([Object? object = '']) => buffer.writeln(object);

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    buffer.write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) => buffer.writeCharCode(charCode);

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding encoding) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
    }
  }

  @override
  void add(List<int> data) => buffer.write(utf8.decode(data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    throw error;
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> get done async {}

  @override
  Future<void> flush() async {}
}
