import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/navigation/app_page_routes.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('appNativeRoute uses Cupertino routes on iOS', (tester) async {
    late Route<void> route;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) {
            route = appNativeRoute<void>(context, const SizedBox.shrink());
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(route, isA<CupertinoPageRoute<void>>());
  });

  testWidgets('appNativeRoute keeps Material routes on Android', (
    tester,
  ) async {
    late Route<void> route;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            route = appNativeRoute<void>(context, const SizedBox.shrink());
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(route, isA<MaterialPageRoute<void>>());
  });

  test('feature code does not hardcode MaterialPageRoute', () {
    final libDirectory = Directory('lib');
    final offenders = <String>[];

    for (final entity in libDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path == 'lib/shared/navigation/app_page_routes.dart') {
        continue;
      }
      final source = entity.readAsStringSync();
      if (source.contains('MaterialPageRoute')) offenders.add(entity.path);
    }

    expect(offenders, isEmpty);
  });

  test('custom app slide routes use Cupertino routes on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final route = appSlideRoute<void>(const SizedBox.shrink());

    expect(route, isA<CupertinoPageRoute<void>>());
  });
}
