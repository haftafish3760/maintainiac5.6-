part of 'maintainiac_firestore_upload_queue.dart';

class MaintainiacFirestoreUploadPolicy {
  const MaintainiacFirestoreUploadPolicy._();

  static const maxBatchSize = 20;
  static const maxQueuedRecords = 500;
  static const maxDocumentBytes = 768 * 1024;
  static const retryInitialDelay = Duration(seconds: 30);
  static const retryMaximumDelay = Duration(hours: 6);

  static Duration retryDelayForAttempt(int attemptCount) {
    final exponent = attemptCount.clamp(1, 16).toInt() - 1;
    final seconds = retryInitialDelay.inSeconds * (1 << exponent);
    return Duration(
      seconds: seconds > retryMaximumDelay.inSeconds
          ? retryMaximumDelay.inSeconds
          : seconds,
    );
  }

  static const allowedTopLevelCollections = <String>{
    'users',
    MaintainiacFirestoreSchema.orgs,
    MaintainiacFirestoreSchema.catalogPacks,
    MaintainiacFirestoreSchema.parserHealth,
    MaintainiacFirestoreSchema.catalogHealth,
    MaintainiacFirestoreSchema.sharedCorrectionCandidates,
  };

  static const blockedSensitiveKeys = <String>{
    'rawReceiptText',
    'receiptText',
    'ocrText',
    'merchantName',
    'storeName',
    'customerName',
    'jobName',
    'description',
    'correctedDescription',
    'catalogItemName',
    'itemName',
    'lineText',
    'address',
    'phone',
    'email',
    'vin',
    'plateNumber',
  };

  static const blockedEverywhereKeys = <String>{
    'rawReceiptText',
    'rawOcrText',
    'ocrText',
    'importedText',
    'localPath',
    'path',
    'vin',
    'VIN',
    'vehicleIdentificationNumber',
    'licensePlate',
    'plate',
    'plateNumber',
    'tagNumber',
    'passengerName',
    'passengerPhone',
    'passengerAddress',
    'patientName',
    'patientPhone',
    'patientAddress',
    'medicalRecordNumber',
    'diagnosis',
    'dateOfBirth',
    'dob',
  };

  static void validateDraft(MaintainiacFirestoreDocumentDraft draft) {
    _validatePath(draft.path);
    _validateDocumentSize(draft);
    _validateNoSensitiveKeys(
      draft.data,
      allowPrivateExpenseBackup: _isPrivateExpenseBackupPath(draft.path),
    );
    _validateTripMileageSummaryShape(draft);
    _validateCatalogReadShape(draft);
  }

  static void _validatePath(String path) {
    final clean = path.trim();
    if (clean.isEmpty ||
        clean.startsWith('/') ||
        clean.endsWith('/') ||
        clean.contains('//') ||
        clean.contains('..')) {
      throw ArgumentError.value(path, 'path', 'Unsafe Firestore path.');
    }
    final parts = clean.split('/');
    if (parts.length.isOdd) {
      throw ArgumentError.value(path, 'path', 'Path must target a document.');
    }
    if (!allowedTopLevelCollections.contains(parts.first)) {
      throw ArgumentError.value(
        path,
        'path',
        'Unsupported top-level collection.',
      );
    }
  }

  static void _validateDocumentSize(MaintainiacFirestoreDocumentDraft draft) {
    final bytes = utf8.encode(jsonEncode(draft.data)).length;
    if (bytes > maxDocumentBytes) {
      throw ArgumentError.value(
        bytes,
        draft.path,
        'Firestore document is too large for the guarded queue.',
      );
    }
  }

  static bool _isPrivateExpenseBackupPath(String path) {
    final parts = path.trim().split('/');
    return parts.length >= 4 &&
        parts.first == MaintainiacFirestoreSchema.orgs &&
        (parts[2] == MaintainiacFirestoreSchema.orgExpenses ||
            parts[2] == MaintainiacFirestoreSchema.orgSettings);
  }

  static void _validateTripMileageSummaryShape(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    final parts = draft.path.trim().split('/');
    final isOrganizationMileagePath =
        parts.length == 4 &&
        parts[0] == MaintainiacFirestoreSchema.orgs &&
        parts[2] == MaintainiacFirestoreSchema.orgMileageRecords;
    final isPersonalMileagePath =
        parts.length == 4 &&
        parts[0] == 'users' &&
        parts[2] == MaintainiacFirestoreSchema.orgMileageRecords;
    if (!isOrganizationMileagePath && !isPersonalMileagePath) return;

    if (draft.data['schema'] !=
            TripTrackingFirestoreContract.reviewedSummarySchema ||
        draft.data['locationDataIncluded'] != false ||
        draft.data['visibilityScope'] != 'mileage_only' ||
        !draft.data.keys.every(
          TripTrackingFirestoreContract.reviewedSummaryFields.contains,
        )) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Mileage uploads must be coordinate-free reviewed trip summaries.',
      );
    }
    if (isOrganizationMileagePath) {
      if (draft.data['orgId'] != parts[1] ||
          draft.data['organizationSharingConsent'] != true) {
        throw ArgumentError.value(
          draft.path,
          'draft',
          'Organization mileage requires matching explicit sharing consent.',
        );
      }
      return;
    }
    if (draft.data.containsKey('orgId') ||
        draft.data.containsKey('organizationSharingConsent')) {
      throw ArgumentError.value(
        draft.path,
        'draft',
        'Personal mileage cannot carry organization sharing fields.',
      );
    }
  }

  static void _validateNoSensitiveKeys(
    Object? value, {
    String parent = '',
    bool allowPrivateExpenseBackup = false,
  }) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final blocked = allowPrivateExpenseBackup
            ? blockedEverywhereKeys.contains(key)
            : blockedSensitiveKeys.contains(key);
        if (blocked) {
          throw ArgumentError.value(
            key,
            parent,
            'Sensitive field is not allowed in Firestore upload queue.',
          );
        }
        _validateNoSensitiveKeys(
          entry.value,
          parent: key,
          allowPrivateExpenseBackup: allowPrivateExpenseBackup,
        );
      }
    } else if (value is Iterable) {
      for (final item in value) {
        _validateNoSensitiveKeys(
          item,
          parent: parent,
          allowPrivateExpenseBackup: allowPrivateExpenseBackup,
        );
      }
    }
  }

  static void _validateCatalogReadShape(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    if (!draft.path.startsWith('${MaintainiacFirestoreSchema.catalogPacks}/')) {
      return;
    }
    if (draft.data['firestoreItemDocumentReadCount'] != 0) {
      throw ArgumentError.value(
        draft.data['firestoreItemDocumentReadCount'],
        draft.path,
        'Catalog packs must never require item-document reads.',
      );
    }
    if (draft.data['deliveryMode'] != 'manifest_storage_chunks') {
      throw ArgumentError.value(
        draft.data['deliveryMode'],
        draft.path,
        'Catalog packs must use manifest plus Storage chunks.',
      );
    }
  }
}
