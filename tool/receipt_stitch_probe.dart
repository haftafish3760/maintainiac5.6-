import 'dart:io';

/// Compatibility launcher for the Flutter-backed production stitch probe.
///
/// The production stitcher imports Flutter and `dart:ui`, so invoking it from a
/// plain Dart process cannot work. This launcher preserves the convenient
/// `dart run tool/receipt_stitch_probe.dart ...` command while delegating to the
/// Flutter test harness that calls the real production implementation.
Future<void> main(List<String> paths) async {
  if (paths.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/receipt_stitch_probe.dart <photo> <photo> [...]',
    );
    exitCode = 64;
    return;
  }
  final script = File('tool/receipt_stitch_real_probe.sh');
  if (!script.existsSync()) {
    stderr.writeln('Missing ${script.path}');
    exitCode = 66;
    return;
  }
  final process = await Process.start(
    script.path,
    paths,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}
