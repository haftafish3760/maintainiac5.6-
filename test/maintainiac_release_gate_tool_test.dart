import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/maintainiac_release_gate.dart';

void main() {
  test('release gate tool prints text command plan', () {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final exit = runMaintainiacReleaseGate(
      const [],
      stdout: _StringBufferSink(stdoutBuffer),
      stderr: _StringBufferSink(stderrBuffer),
    );

    expect(exit, 0);
    expect(stderrBuffer.toString(), isEmpty);
    expect(stdoutBuffer.toString(), contains('MAINTAINIAC_RELEASE_GATE'));
    expect(stdoutBuffer.toString(), contains('maintainiac_qa_backbone_test'));
  });

  test('release gate tool prints JSON automation payload', () {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final exit = runMaintainiacReleaseGate(
      const ['--json'],
      stdout: _StringBufferSink(stdoutBuffer),
      stderr: _StringBufferSink(stderrBuffer),
    );

    expect(exit, 0);
    final json = jsonDecode(stdoutBuffer.toString()) as Map;
    expect(json['name'], 'release_one_core_gate');
    expect(json['commands'].toString(), contains('maintainiac_qa_backbone'));
  });

  test('release gate tool prints commands-only output', () {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final exit = runMaintainiacReleaseGate(
      const ['--commands-only'],
      stdout: _StringBufferSink(stdoutBuffer),
      stderr: _StringBufferSink(stderrBuffer),
    );

    expect(exit, 0);
    expect(stderrBuffer.toString(), isEmpty);
    expect(
      stdoutBuffer
          .toString()
          .trim()
          .split('\n')
          .every((line) => line.startsWith('flutter test ')),
      isTrue,
    );
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
