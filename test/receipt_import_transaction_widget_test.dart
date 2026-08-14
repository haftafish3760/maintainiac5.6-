import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  testWidgets(
    'upload is a single immediate transaction even when tapped twice',
    (tester) async {
      final completion = Completer<ReceiptImportActionResult>();
      var invocationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptImportSourceScreen(
            showCamera: false,
            onAction: (action) {
              invocationCount += 1;
              expect(action, ReceiptImportSourceAction.image);
              return completion.future;
            },
          ),
        ),
      );

      final upload = find.text('Upload Photos');
      expect(upload, findsOneWidget);

      // Both taps are dispatched before another frame can remove the tile.
      // The action gate must still start exactly one picker transaction.
      await tester.tap(upload);
      await tester.tap(upload);
      await tester.pump();

      expect(invocationCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Just a moment…'), findsOneWidget);
      expect(upload, findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      completion.complete(const ReceiptImportActionResult.stayOnChooser());
      await tester.pump();

      expect(find.text('Upload Photos'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'manual receipt image action uses customer language and covers every source',
    (tester) async {
      final completion = Completer<ReceiptImportActionResult>();
      var invocationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptImportSourceScreen(
            showCamera: true,
            intent: ReceiptImportEntryIntent.optionalManualProof,
            onAction: (action) {
              invocationCount += 1;
              expect(action, ReceiptImportSourceAction.image);
              return completion.future;
            },
          ),
        ),
      );

      expect(find.text('Add image of your receipt'), findsOneWidget);
      expect(
        find.text(
          'Take a photo or choose an image. You can also add a PDF or text copy.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('proof'), findsNothing);
      expect(find.text('Capture Photo'), findsOneWidget);
      expect(find.text('Upload Photos'), findsOneWidget);
      expect(find.text('Upload PDF/File'), findsOneWidget);
      expect(find.text('Paste/Text'), findsOneWidget);

      await tester.tap(find.text('Upload Photos'));
      await tester.pump();

      expect(invocationCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Just a moment…'), findsOneWidget);
      expect(find.text('Add image of your receipt'), findsNothing);

      completion.complete(const ReceiptImportActionResult.stayOnChooser());
      await tester.pump();

      expect(find.text('Add image of your receipt'), findsOneWidget);
    },
  );

  testWidgets(
    'camera review stays covered until its complete handoff returns',
    (tester) async {
      final completion = Completer<ReceiptImportActionResult>();
      var invocationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptImportSourceScreen(
            showCamera: true,
            onAction: (action) {
              invocationCount += 1;
              expect(action, ReceiptImportSourceAction.camera);
              return completion.future;
            },
          ),
        ),
      );

      await tester.tap(find.text('Capture Photo'));
      await tester.pump();

      expect(invocationCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Just a moment…'), findsOneWidget);
      expect(find.text('Capture Photo'), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      completion.complete(const ReceiptImportActionResult.stayOnChooser());
      await tester.pump();

      expect(find.text('Capture Photo'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('an accepted review closes the source chooser exactly once', (
    tester,
  ) async {
    var popCount = 0;
    ReceiptImportActionResult? returnedResult;
    final observer = _CountingNavigatorObserver(onPop: () => popCount += 1);
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/reviewed-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/reviewed-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(const [
        '/tmp/reviewed-ocr.jpg',
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              returnedResult = await Navigator.of(context)
                  .push<ReceiptImportActionResult>(
                    MaterialPageRoute(
                      builder: (_) => ReceiptImportSourceScreen(
                        showCamera: false,
                        onAction: (_) async =>
                            ReceiptImportActionResult.reviewCompleted(result),
                      ),
                    ),
                  );
            },
            child: const Text('Open source chooser'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open source chooser'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload Photos'));
    await tester.pumpAndSettle();

    expect(popCount, 1);
    expect(returnedResult?.reviewResult, same(result));
    expect(find.text('Open source chooser'), findsOneWidget);
  });

  testWidgets('discard review outcome reaches the owner without being erased', (
    tester,
  ) async {
    ReceiptImportActionResult? returnedResult;
    final discard = ReceiptPhotoReviewResult.discardedByUser(
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              returnedResult = await Navigator.of(context)
                  .push<ReceiptImportActionResult>(
                    MaterialPageRoute(
                      builder: (_) => ReceiptImportSourceScreen(
                        showCamera: false,
                        onAction: (_) async =>
                            ReceiptImportActionResult.reviewCompleted(discard),
                      ),
                    ),
                  );
            },
            child: const Text('Open source chooser'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open source chooser'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload Photos'));
    await tester.pumpAndSettle();

    expect(returnedResult?.exitsReceiptFlow, isTrue);
    expect(returnedResult?.reviewResult?.discardedByUser, isTrue);
    expect(find.text('Open source chooser'), findsOneWidget);
  });

  testWidgets('a canceled document source stays on the same chooser route', (
    tester,
  ) async {
    var invocationCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptImportSourceScreen(
          showCamera: false,
          onAction: (action) async {
            invocationCount += 1;
            expect(action, ReceiptImportSourceAction.pdf);
            return const ReceiptImportActionResult.stayOnChooser();
          },
        ),
      ),
    );

    await tester.tap(find.text('Upload PDF/File'));
    await tester.pumpAndSettle();

    expect(invocationCount, 1);
    expect(find.text('Upload PDF/File'), findsOneWidget);
    expect(
      find.text('Choose how you want to add this receipt.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed source action recovers the chooser without escaping', (
    tester,
  ) async {
    var invocationCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptImportSourceScreen(
          showCamera: false,
          onAction: (action) async {
            invocationCount += 1;
            throw StateError('synthetic source failure');
          },
        ),
      ),
    );

    await tester.tap(find.text('Upload Photos'));
    await tester.pumpAndSettle();

    expect(invocationCount, 1);
    expect(find.text('Upload Photos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text(
        'That receipt source could not be opened. Try again or choose another source.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Upload Photos'));
    await tester.pumpAndSettle();
    expect(invocationCount, 2);
  });
}

class _CountingNavigatorObserver extends NavigatorObserver {
  _CountingNavigatorObserver({required this.onPop});

  final VoidCallback onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
    super.didPop(route, previousRoute);
  }
}
