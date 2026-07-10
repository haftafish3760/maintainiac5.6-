import 'maintainiac_qa_environment.dart';

class MaintainiacQaAssertionFailure implements Exception {
  const MaintainiacQaAssertionFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class MaintainiacQaAssertions {
  const MaintainiacQaAssertions._();

  static void moneyEquals(int actualCents, int expectedCents) {
    if (actualCents != expectedCents) {
      throw MaintainiacQaAssertionFailure(
        'Expected $expectedCents cents, got $actualCents cents.',
      );
    }
  }

  static void odometerIsMonotonic(int start, int end) {
    if (end < start) {
      throw MaintainiacQaAssertionFailure(
        'Odometer moved backward from $start to $end.',
      );
    }
  }

  static void auditTrailComplete(List<Map<String, Object?>> entries) {
    for (final entry in entries) {
      for (final field in ['id', 'actorId', 'action']) {
        if (!entry.containsKey(field) || entry[field].toString().isEmpty) {
          throw MaintainiacQaAssertionFailure('Audit entry missing $field.');
        }
      }
    }
  }

  static void localWriteBeforeMirror(MaintainiacQaEnvironment env) {
    if (env.firestoreMirror.writes.isEmpty) return;
    if (env.hive.writes.isEmpty) {
      throw const MaintainiacQaAssertionFailure(
        'Firestore mirror write happened before local Hive write.',
      );
    }
  }

  static void dirtyFlagSet(Map<String, Object?> payload) {
    if (payload['dirty'] != true) {
      throw const MaintainiacQaAssertionFailure(
        'Expected dirty flag to be set.',
      );
    }
  }

  static void dirtyFlagCleared(Map<String, Object?> payload) {
    if (payload['dirty'] == true) {
      throw const MaintainiacQaAssertionFailure('Expected dirty flag cleared.');
    }
  }

  static void mirrorEqualsLocal(
    Map<String, Object?> local,
    Map<String, Object?> mirror,
  ) {
    final localText = Map.of(local).toString();
    final mirrorText = Map.of(mirror).toString();
    if (localText != mirrorText) {
      throw MaintainiacQaAssertionFailure(
        'Firestore mirror differs from local payload.',
      );
    }
  }

  static void sameAccountOnly(String ownerAccountId, String activeAccountId) {
    if (ownerAccountId != activeAccountId) {
      throw const MaintainiacQaAssertionFailure('Cross-account data bleed.');
    }
  }

  static void confirmedDataNotOverwritten({
    required Map<String, Object?> before,
    required Map<String, Object?> after,
    required List<String> confirmedFields,
  }) {
    for (final field in confirmedFields) {
      if (before[field] != after[field]) {
        throw MaintainiacQaAssertionFailure(
          'Confirmed field $field was overwritten.',
        );
      }
    }
  }

  static void suggestionStayedSuggestion(Map<String, Object?> payload) {
    if (payload['reviewStatus'] != 'suggested' &&
        payload['isSuggestion'] != true) {
      throw const MaintainiacQaAssertionFailure(
        'Parser/OCR output escaped suggestion status.',
      );
    }
  }

  static void recapDidNotMutateSources(MaintainiacQaEnvironment env) {
    final sourceWrites = env.hive.writes.where(
      (write) =>
          RegExp(r'trip|expense|inventory|odometer').hasMatch(write.target),
    );
    if (sourceWrites.isNotEmpty) {
      throw const MaintainiacQaAssertionFailure(
        'Recap/derived output mutated source records.',
      );
    }
  }

  static void noUnauthorizedSourceMutation({
    required String operation,
    required Iterable<String> mutatedCollections,
    required Set<String> allowedCollections,
  }) {
    final unauthorized = mutatedCollections.where(
      (collection) => !allowedCollections.contains(collection),
    );
    if (unauthorized.isNotEmpty) {
      throw MaintainiacQaAssertionFailure(
        '$operation mutated unauthorized source collections: '
        '${unauthorized.join(', ')}.',
      );
    }
  }

  static void invoiceEstimateDidNotMutateSources({
    required String outputType,
    required Iterable<String> sourceCollectionsTouched,
  }) {
    if (sourceCollectionsTouched.isNotEmpty) {
      throw MaintainiacQaAssertionFailure(
        '$outputType must read source data and write output records only; '
        'mutated ${sourceCollectionsTouched.join(', ')}.',
      );
    }
  }

  static void exportContainsOnlyOwnedRecords(
    Iterable<Map<String, Object?>> records,
    String accountId,
  ) {
    for (final record in records) {
      if (record['accountId'] != accountId &&
          record['ownerAccountId'] != accountId) {
        throw const MaintainiacQaAssertionFailure(
          'Export contains records outside the active account.',
        );
      }
    }
  }

  static void payloadContainsNoPrivateFields(Map<String, Object?> payload) {
    const forbiddenKeys = {
      'vin',
      'vehicleidentificationnumber',
      'licenseplate',
      'plate',
      'passenger',
      'patient',
      'ssn',
      'socialsecuritynumber',
      'cardnumber',
      'cvv',
    };
    final badKeys = payload.keys.where(
      (key) => forbiddenKeys.contains(key.toLowerCase()),
    );
    if (badKeys.isNotEmpty) {
      throw MaintainiacQaAssertionFailure(
        'Payload contains private fields: ${badKeys.join(', ')}.',
      );
    }
  }

  static void conflictGeneratedWhenExpected(bool generated) {
    if (!generated) {
      throw const MaintainiacQaAssertionFailure('Expected sync conflict.');
    }
  }

  static void regressionMatchedExpected(
    Object? actual,
    Object? expected,
    String bugId,
  ) {
    if (actual != expected) {
      throw MaintainiacQaAssertionFailure(
        'Regression $bugId failed: expected $expected, got $actual.',
      );
    }
  }
}
