import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_preview_screen.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  testWidgets('generated PDF preview can retry after preparation failure', (
    tester,
  ) async {
    final events = <AppGeneratedPdfPreviewActionEvent>[];
    final service = _FakeGeneratedPdfService(
      failFirstWrite: true,
      tempPath: '${Directory.systemTemp.path}/retry-preview.pdf',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppGeneratedPdfPreviewScreen(
          document: _document(),
          service: service,
          onAction: events.add,
        ),
      ),
    );
    await _pumpPdfPreview(tester);

    expect(
      find.text('Maintaniac could not prepare this PDF right now.'),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    expect(events.map((event) => event.action), [
      AppGeneratedPdfPreviewAction.preparationFailed,
    ]);
    expect(events.single.reasonCode, 'prepare_pdf_validation_failed');

    await tester.tap(find.text('Try Again'));
    await _pumpPdfPreview(tester);

    expect(find.text('Invoice INV-100'), findsOneWidget);
    expect(find.textContaining('Invoice PDF ready'), findsOneWidget);
    expect(find.text('Preview PDF'), findsOneWidget);
    expect(service.writeCount, 2);
    expect(events.map((event) => event.action), [
      AppGeneratedPdfPreviewAction.preparationFailed,
      AppGeneratedPdfPreviewAction.prepared,
    ]);
  });

  testWidgets('generated PDF preview shows friendly share failure', (
    tester,
  ) async {
    final events = <AppGeneratedPdfPreviewActionEvent>[];
    final service = _FakeGeneratedPdfService(
      shareFailure: StateError('platform share broke'),
      tempPath: '${Directory.systemTemp.path}/share-preview.pdf',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppGeneratedPdfPreviewScreen(
          document: _document(),
          service: service,
          onAction: events.add,
        ),
      ),
    );
    await _pumpPdfPreview(tester);

    await tester.tap(find.text('Share or Save PDF'));
    await _pumpPdfPreview(tester);

    expect(
      find.textContaining('could not open sharing for this PDF'),
      findsOneWidget,
    );
    expect(events.map((event) => event.action), [
      AppGeneratedPdfPreviewAction.prepared,
      AppGeneratedPdfPreviewAction.shareFailed,
    ]);
    expect(events.last.reasonCode, 'share_platform_failed');
  });

  testWidgets('generated PDF preview shows friendly print failure', (
    tester,
  ) async {
    final events = <AppGeneratedPdfPreviewActionEvent>[];
    final service = _FakeGeneratedPdfService(
      printFailure: StateError('platform print broke'),
      tempPath: '${Directory.systemTemp.path}/print-preview.pdf',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppGeneratedPdfPreviewScreen(
          document: _document(),
          service: service,
          onAction: events.add,
        ),
      ),
    );
    await _pumpPdfPreview(tester);

    await tester.tap(find.text('Print PDF'));
    await _pumpPdfPreview(tester);

    expect(
      find.textContaining('could not open printing for this PDF'),
      findsOneWidget,
    );
    expect(events.map((event) => event.action), [
      AppGeneratedPdfPreviewAction.prepared,
      AppGeneratedPdfPreviewAction.printFailed,
    ]);
    expect(events.last.reasonCode, 'print_platform_failed');
  });

  testWidgets('generated PDF preview reports share and print action results', (
    tester,
  ) async {
    final events = <AppGeneratedPdfPreviewActionEvent>[];
    final service = _FakeGeneratedPdfService(
      tempPath: '${Directory.systemTemp.path}/action-preview.pdf',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppGeneratedPdfPreviewScreen(
          document: _document(),
          service: service,
          onAction: events.add,
        ),
      ),
    );
    await _pumpPdfPreview(tester);

    await tester.tap(find.text('Share or Save PDF'));
    await _pumpPdfPreview(tester);
    await tester.tap(find.text('Print PDF'));
    await _pumpPdfPreview(tester);

    expect(events.map((event) => event.action), [
      AppGeneratedPdfPreviewAction.prepared,
      AppGeneratedPdfPreviewAction.shareCompleted,
      AppGeneratedPdfPreviewAction.printOpened,
    ]);
    expect(events.where((event) => event.isFailure), isEmpty);
  });

  testWidgets('generated PDF preview reports dismissed share and print flows', (
    tester,
  ) async {
    final events = <AppGeneratedPdfPreviewActionEvent>[];
    final service = _FakeGeneratedPdfService(
      tempPath: '${Directory.systemTemp.path}/dismissed-preview.pdf',
      shareStatus: ShareResultStatus.dismissed,
      printResult: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppGeneratedPdfPreviewScreen(
          document: _document(),
          service: service,
          onAction: events.add,
        ),
      ),
    );
    await _pumpPdfPreview(tester);

    await tester.tap(find.text('Share or Save PDF'));
    await _pumpPdfPreview(tester);
    await tester.tap(find.text('Print PDF'));
    await _pumpPdfPreview(tester);

    expect(events.map((event) => event.action), [
      AppGeneratedPdfPreviewAction.prepared,
      AppGeneratedPdfPreviewAction.shareDismissed,
      AppGeneratedPdfPreviewAction.printDismissed,
    ]);
  });

  testWidgets('generated PDF preview shows unsigned customer warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppGeneratedPdfPreviewScreen(
          document: _document(
            signatureState: AppGeneratedPdfSignatureState.unsigned,
          ),
          service: _FakeGeneratedPdfService(
            tempPath: '${Directory.systemTemp.path}/unsigned-preview.pdf',
          ),
        ),
      ),
    );
    await _pumpPdfPreview(tester);

    expect(
      find.text('Customer signature is still required for this document.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpPdfPreview(WidgetTester tester) async {
  for (var index = 0; index < 6; index += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

AppGeneratedPdfDocument _document({
  AppGeneratedPdfSignatureState signatureState =
      AppGeneratedPdfSignatureState.notRequired,
}) {
  return AppGeneratedPdfDocument(
    kind: AppGeneratedPdfKind.invoice,
    title: 'Invoice INV-100',
    fileName: 'invoice_INV-100.pdf',
    bytes: Uint8List.fromList('%PDF-1.7\n1 0 obj\n%%EOF'.codeUnits),
    createdAt: DateTime(2026, 6, 26),
    sourceModule: 'invoices',
    sourceRecordId: 'invoice_100',
    signatureState: signatureState,
  );
}

class _FakeGeneratedPdfService extends AppGeneratedPdfService {
  _FakeGeneratedPdfService({
    required this.tempPath,
    this.failFirstWrite = false,
    this.shareFailure,
    this.printFailure,
    this.shareStatus = ShareResultStatus.success,
    this.printResult = true,
  });

  final String tempPath;
  final bool failFirstWrite;
  final Object? shareFailure;
  final Object? printFailure;
  final ShareResultStatus shareStatus;
  final bool printResult;
  var writeCount = 0;

  @override
  Future<AppGeneratedPdfFile> writeTemporary(
    AppGeneratedPdfDocument document,
  ) async {
    writeCount += 1;
    if (failFirstWrite && writeCount == 1) {
      throw const AppGeneratedPdfException(
        'Maintaniac could not prepare this PDF right now.',
      );
    }
    return AppGeneratedPdfFile(
      document: document,
      path: tempPath,
      byteSize: document.byteSize,
    );
  }

  @override
  Future<ShareResultStatus> shareGeneratedFile(
    AppGeneratedPdfFile generated,
  ) async {
    final failure = shareFailure;
    if (failure != null) throw failure;
    return shareStatus;
  }

  @override
  Future<bool> print(AppGeneratedPdfDocument document) async {
    final failure = printFailure;
    if (failure != null) throw failure;
    return printResult;
  }
}
