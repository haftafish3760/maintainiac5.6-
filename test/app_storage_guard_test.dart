import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_storage_guard.dart';

void main() {
  group('AppStorageGuard', () {
    test('adds a device reserve to every protected write', () {
      expect(
        AppStorageGuard.protectedRequiredBytes(1),
        1 + AppStorageGuard.minimumDeviceReserveBytes,
      );
      expect(
        AppStorageGuard.protectedRequiredBytesFor(
          AppStoragePurpose.dashboardRecord,
          1,
        ),
        1 + AppStorageGuard.textRecordDeviceReserveBytes,
      );
      expect(
        AppStorageGuard.defaultOperationBytesFor(
          AppStoragePurpose.mileageTracking,
        ),
        AppStorageGuard.mileageTrackingWriteBytes,
      );
    });

    test(
      'dashboard and mileage text records keep a smaller reserve than media',
      () async {
        final dashboard = await AppStorageGuard.checkForBytes(
          operationBytes: 1 * 1024 * 1024,
          purpose: AppStoragePurpose.dashboardRecord,
          freeStorageReader: () async => 26,
        );
        final mileage = await AppStorageGuard.checkForBytes(
          operationBytes: 2 * 1024 * 1024,
          purpose: AppStoragePurpose.mileageTracking,
          freeStorageReader: () async => 27,
        );
        final receipt = await AppStorageGuard.checkForBytes(
          operationBytes: 1 * 1024 * 1024,
          purpose: AppStoragePurpose.receiptPhotoSave,
          freeStorageReader: () async => 26,
        );

        expect(dashboard.hasEnoughSpace, isTrue);
        expect(dashboard.reserveLabel, '25 MB');
        expect(mileage.hasEnoughSpace, isTrue);
        expect(mileage.reserveLabel, '25 MB');
        expect(receipt.hasEnoughSpace, isFalse);
        expect(receipt.reserveLabel, '50 MB');
      },
    );

    test('rejects an invalid negative storage reservation', () async {
      await expectLater(
        () => AppStorageGuard.checkForBytes(
          operationBytes: -1,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
        throwsArgumentError,
      );
    });

    test('blocks writes that would consume the safety reserve', () async {
      final check = await AppStorageGuard.checkForBytes(
        operationBytes: 10 * 1024 * 1024,
        purpose: AppStoragePurpose.receiptPdfImport,
        freeStorageReader: () async => 20,
      );

      expect(check.canVerify, isTrue);
      expect(check.hasEnoughSpace, isFalse);
      expect(check.blockingMessage(), contains('not enough free storage'));
      expect(check.blockingMessage(), contains('device safety reserve'));
      expect(check.blockingMessage(), contains('will not delete anything'));
    });

    test('allows exactly enough storage and blocks just under it', () async {
      final exact = await AppStorageGuard.checkForBytes(
        operationBytes: 10 * 1024 * 1024,
        purpose: AppStoragePurpose.receiptPdfImport,
        freeStorageReader: () async => 60,
      );
      final under = await AppStorageGuard.checkForBytes(
        operationBytes: 10 * 1024 * 1024,
        purpose: AppStoragePurpose.receiptPdfImport,
        freeStorageReader: () async => 59.99,
      );

      expect(exact.requiredBytes, 60 * 1024 * 1024);
      expect(exact.hasEnoughSpace, isTrue);
      expect(under.hasEnoughSpace, isFalse);
    });

    test('warns without blocking when storage is low but usable', () async {
      final check = await AppStorageGuard.checkForBytes(
        operationBytes: 10 * 1024 * 1024,
        purpose: AppStoragePurpose.receiptPdfImport,
        freeStorageReader: () async => 128,
      );

      expect(check.hasEnoughSpace, isTrue);
      expect(check.shouldWarnLowStorage, isTrue);
      expect(check.warningMessage(), contains('getting low on storage'));
    });

    test(
      'classifies shared storage health at the approved thresholds',
      () async {
        Future<AppStorageLevel> levelFor(double freeMb) async =>
            (await AppStorageGuard.checkForBytes(
              operationBytes: 1,
              purpose: AppStoragePurpose.smallRecordWrite,
              freeStorageReader: () async => freeMb,
            )).level;

        expect(await levelFor(1024), AppStorageLevel.green);
        expect(await levelFor(500), AppStorageLevel.yellow);
        expect(await levelFor(499), AppStorageLevel.orange);
        expect(await levelFor(250), AppStorageLevel.red);
      },
    );

    test('allows safe action when the device has enough space', () async {
      final check = await AppStorageGuard.checkForBytes(
        operationBytes: 10 * 1024 * 1024,
        purpose: AppStoragePurpose.receiptPdfImport,
        freeStorageReader: () async => 512,
      );

      expect(check.hasEnoughSpace, isTrue);
      expect(check.shouldWarnLowStorage, isTrue);
    });

    test(
      'unknown storage is permissive but gives a recovery message',
      () async {
        final check = await AppStorageGuard.checkForBytes(
          operationBytes: 10 * 1024 * 1024,
          purpose: AppStoragePurpose.receiptPdfImport,
          freeStorageReader: () async => null,
        );

        expect(check.canVerify, isFalse);
        expect(check.hasEnoughSpace, isTrue);
        expect(check.unknownMessage(), contains('could not verify'));
        expect(check.unknownMessage(), contains('device safety reserve'));
      },
    );

    test('non-positive storage readings are treated as unknown', () async {
      final check = await AppStorageGuard.checkForBytes(
        operationBytes: 10 * 1024 * 1024,
        purpose: AppStoragePurpose.receiptPdfImport,
        freeStorageReader: () async => 0,
      );

      expect(check.canVerify, isFalse);
      expect(check.hasEnoughSpace, isTrue);
      expect(check.unknownMessage(), contains('could not verify'));
    });

    test('receipt guard delegates to the shared storage policy', () {
      expect(
        ReceiptStorageGuard.minimumDeviceReserveBytes,
        AppStorageGuard.minimumDeviceReserveBytes,
      );
      expect(
        ReceiptStorageGuard.protectedRequiredBytes(4096),
        AppStorageGuard.protectedRequiredBytes(4096),
      );
      expect(
        ReceiptStorageGuard.minimumCaptureBytes,
        AppStorageGuard.receiptPhotoCaptureBytes,
      );
    });
  });
}
