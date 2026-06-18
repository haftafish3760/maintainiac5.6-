import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/incoming_receipt_share.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'shared active-action PDF is staged as read-only proof with warnings',
    () async {
      final documentsDirectory = await Directory.systemTemp.createTemp(
        'incoming_active_action_pdf_',
      );
      final source = File(
        '${Directory.systemTemp.path}/shared_active_action.pdf',
      );
      await source.writeAsString(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
        '2 0 obj << /Launch 4 0 R /RichMedia 5 0 R /SubmitForm 6 0 R >> endobj\n'
        '%%EOF',
        flush: true,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => switch (call.method) {
              'getApplicationDocumentsDirectory' => documentsDirectory.path,
              _ => null,
            },
          );
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              null,
            );
        if (source.existsSync()) source.deleteSync();
        if (await documentsDirectory.exists()) {
          await documentsDirectory.delete(recursive: true);
        }
      });

      final prepared = await prepareIncomingReceiptShareForStorage(
        IncomingReceiptShare(
          attachments: receiptAttachmentsFromSharedMedia([
            SharedMediaFile(
              path: source.path,
              type: SharedMediaType.file,
              mimeType: 'application/pdf',
            ),
          ]),
          receivedAt: DateTime(2026, 6, 13),
        ),
      );

      final attachment = prepared.attachments.single;
      expect(attachment.kind, ReceiptAttachmentKind.pdf);
      expect(attachment.storageState, ReceiptAttachmentStorageState.staged);
      expect(attachment.path, contains('receipt_proofs_staging'));
      expect(attachment.riskFlags, contains('auto-open actions'));
      expect(attachment.riskFlags, contains('launch actions'));
      expect(attachment.riskFlags, contains('embedded media'));
      expect(attachment.readState, ReceiptAttachmentReadState.unreadable);
      expect(prepared.messages.join('\n'), contains('will not run scripts'));
    },
  );

  test('shared PDF stores document signals for destination review', () async {
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'incoming_receipt_signal_pdf_',
    );
    final source = File('${Directory.systemTemp.path}/shared_receipt.pdf');
    await source.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page >> stream\n'
      'Advance Auto Parts Receipt Subtotal Tax Total Visa\n'
      'endstream endobj\n'
      '%%EOF',
      flush: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (source.existsSync()) source.deleteSync();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    final prepared = await prepareIncomingReceiptShareForStorage(
      IncomingReceiptShare(
        attachments: receiptAttachmentsFromSharedMedia([
          SharedMediaFile(
            path: source.path,
            type: SharedMediaType.file,
            mimeType: 'application/pdf',
          ),
        ]),
        receivedAt: DateTime(2026, 6, 13),
      ),
    );

    final attachment = prepared.attachments.single;
    expect(attachment.documentSignals, contains('receipt'));
    expect(attachment.documentSignals, contains('subtotal'));
    expect(attachment.documentSignals, contains('tax'));
    expect(attachment.documentSignals, contains('total'));
    expect(attachment.storageState, ReceiptAttachmentStorageState.staged);
  });
}
