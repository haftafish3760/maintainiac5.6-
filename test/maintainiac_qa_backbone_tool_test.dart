import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/maintainiac_qa_backbone.dart';

void main() {
  test(
    'Maintainiac QA backbone tool writes redacted report artifacts',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maintainiac_main_qa_',
      );
      addTearDown(() {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      });

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      final result = await runMaintainiacQaBackbone(
        ['--output', directory.path, '--profile', 'smoke', '--preset', 'main'],
        stdout: _StringBufferSink(stdoutBuffer),
        stderr: _StringBufferSink(stderrBuffer),
      );

      expect(result.exitCode, 0);
      expect(result.report, isNotNull);
      expect(result.artifact, isNotNull);
      expect(stdoutBuffer.toString(), contains('MAINTAINIAC_QA_ARTIFACT'));
      expect(stderrBuffer.toString(), isEmpty);

      final latest = File(result.artifact!.latestJsonPath);
      final latestSummary = File(result.artifact!.latestSummaryPath);
      expect(latest.existsSync(), isTrue);
      expect(latestSummary.existsSync(), isTrue);

      final json = jsonDecode(latest.readAsStringSync()) as Map;
      expect(json['domain'], 'maintainiac_main');
      expect(json['runConfig'], isA<Map>());
      expect(json['adminHealth'], isA<Map>());
      expect(json['results'].toString(), contains('maintainiac.qa_backbone'));
    },
  );
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
