import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('rapid edits coalesce into one latest local checkpoint', () async {
    final store = MaintainiacRecordDraftStore.memory();
    final autosave = MaintainiacDraftAutosaveCoordinator(
      store: store,
      debounce: const Duration(milliseconds: 10),
    );
    final payload = <String, dynamic>{'text': 'a'};
    final first = autosave.schedule(
      module: 'invoices',
      id: 'invoice-1',
      payload: payload,
    );
    payload['text'] = 'mutated-after-schedule';
    final second = autosave.schedule(
      module: 'invoices',
      id: 'invoice-1',
      payload: const {'text': 'ab'},
    );
    final third = autosave.schedule(
      module: 'invoices',
      id: 'invoice-1',
      payload: const {'text': 'abc'},
    );
    final results = await Future.wait([first, second, third]);
    expect(results.every((draft) => draft.payload['text'] == 'abc'), isTrue);
    expect(store.draftFor('invoices', 'invoice-1')?.lifecycle.revision, 1);
  });

  test('flushAll persists pending forms before an interruption', () async {
    final store = MaintainiacRecordDraftStore.memory();
    final autosave = MaintainiacDraftAutosaveCoordinator(
      store: store,
      debounce: const Duration(seconds: 5),
    );
    final invoice = autosave.schedule(
      module: 'invoices',
      id: 'invoice-1',
      payload: const {'amount': 10},
    );
    final estimate = autosave.schedule(
      module: 'estimates',
      id: 'estimate-1',
      payload: const {'amount': 20},
    );
    await autosave.flushAll();
    await Future.wait([invoice, estimate]);
    expect(store.draftFor('invoices', 'invoice-1'), isNotNull);
    expect(store.draftFor('estimates', 'estimate-1'), isNotNull);
  });

  test('failed autosave reports failure and preserves prior draft', () async {
    var hasSpace = true;
    final store = MaintainiacRecordDraftStore.memory(
      storageCheck: () async => AppStorageCheck(
        availableBytes: hasSpace ? 100 : 0,
        operationBytes: 1,
        requiredBytes: 1,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );
    await store.save(
      module: 'expenses',
      id: 'expense-1',
      payload: const {'amount': 10},
    );
    hasSpace = false;
    final autosave = MaintainiacDraftAutosaveCoordinator(
      store: store,
      debounce: const Duration(milliseconds: 1),
    );
    await expectLater(
      autosave.schedule(
        module: 'expenses',
        id: 'expense-1',
        payload: const {'amount': 20},
      ),
      throwsStateError,
    );
    expect(store.draftFor('expenses', 'expense-1')?.payload['amount'], 10);
  });

  test('dispose flushes once and rejects later scheduling', () async {
    final store = MaintainiacRecordDraftStore.memory();
    final autosave = MaintainiacDraftAutosaveCoordinator(
      store: store,
      debounce: const Duration(seconds: 5),
    );
    final pending = autosave.schedule(
      module: 'jobs',
      id: 'job-1',
      payload: const {'note': 'saved'},
    );
    await autosave.dispose();
    await pending;
    expect(store.draftFor('jobs', 'job-1'), isNotNull);
    expect(
      () => autosave.schedule(module: 'jobs', id: 'job-2', payload: const {}),
      throwsStateError,
    );
  });

  test(
    'dispose waits for a checkpoint already writing to device storage',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final store = MaintainiacRecordDraftStore.memory(
        storageCheck: () async {
          entered.complete();
          await release.future;
          return const AppStorageCheck(
            availableBytes: 100,
            operationBytes: 1,
            requiredBytes: 1,
            purpose: AppStoragePurpose.smallRecordWrite,
          );
        },
      );
      final autosave = MaintainiacDraftAutosaveCoordinator(
        store: store,
        debounce: Duration.zero,
      );
      final pending = autosave.schedule(
        module: 'invoices',
        id: 'invoice-in-flight',
        payload: const {'amount': 42},
      );
      await entered.future;
      var disposed = false;
      final disposal = autosave.dispose().then((_) => disposed = true);

      await Future<void>.delayed(Duration.zero);
      expect(disposed, isFalse);
      release.complete();
      await Future.wait([pending, disposal]);

      expect(disposed, isTrue);
      expect(store.draftFor('invoices', 'invoice-in-flight'), isNotNull);
    },
  );

  test('autosave rejects non-text payload keys instead of rewriting them', () {
    final store = MaintainiacRecordDraftStore.memory();
    final autosave = MaintainiacDraftAutosaveCoordinator(store: store);

    expect(
      () => autosave.schedule(
        module: 'invoices',
        id: 'invoice-bad-key',
        payload: <String, dynamic>{
          'nested': <Object, Object?>{7: 'unsafe'},
        },
      ),
      throwsArgumentError,
    );
    expect(store.draftFor('invoices', 'invoice-bad-key'), isNull);
  });
}
