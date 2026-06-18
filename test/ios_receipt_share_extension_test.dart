import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS share extension accepts receipt files, images, and text', () {
    final plist = File('ios/ShareExtension/Info.plist').readAsStringSync();

    expect(plist, contains('com.apple.share-services'));
    expect(plist, contains('NSExtensionActivationSupportsFileWithMaxCount'));
    expect(plist, contains('<integer>20</integer>'));
    expect(plist, contains('NSExtensionActivationSupportsImageWithMaxCount'));
    expect(plist, contains('NSExtensionActivationSupportsText'));
    expect(plist, contains('NSExtensionActivationSupportsWebURLWithMaxCount'));
  });

  test('iOS share extension has installable version metadata', () {
    final plist = File('ios/ShareExtension/Info.plist').readAsStringSync();

    expect(
      plist,
      matches(
        RegExp(
          r'<key>CFBundleVersion</key>\s*<string>[^<]+</string>',
          multiLine: true,
        ),
      ),
    );
    expect(
      plist,
      matches(
        RegExp(
          r'<key>CFBundleShortVersionString</key>\s*<string>[^<]+</string>',
          multiLine: true,
        ),
      ),
    );
  });
}
