import 'dart:async';

import 'work_supply_inventory_store.dart';
import 'work_supply_models.dart';

class WorkSupplyHomeResources {
  const WorkSupplyHomeResources({
    required this.inventoryStore,
    required this.inventoryRecords,
    required this.inventoryTransactions,
  });

  final WorkSupplyInventoryStore inventoryStore;
  final List<WorkSupplyInventoryRecord> inventoryRecords;
  final List<WorkSupplyInventoryTransaction> inventoryTransactions;
}

Future<WorkSupplyHomeResources>? _homeResourcesFuture;
var _seedDemoCleanupDone = false;

Future<WorkSupplyHomeResources> loadWorkSupplyHomeResources() {
  return _homeResourcesFuture ??= _loadWorkSupplyHomeResources();
}

Future<WorkSupplyHomeResources> refreshWorkSupplyHomeResources() {
  _homeResourcesFuture = _loadWorkSupplyHomeResources();
  return _homeResourcesFuture!;
}

Future<WorkSupplyHomeResources> _loadWorkSupplyHomeResources() async {
  final inventoryStore = await WorkSupplyInventoryStore.create();
  if (!_seedDemoCleanupDone) {
    _seedDemoCleanupDone = true;
    unawaited(inventoryStore.purgeObsoleteSeedInventoryRecords());
  }
  return WorkSupplyHomeResources(
    inventoryStore: inventoryStore,
    inventoryRecords: inventoryStore.loadInventory(),
    inventoryTransactions: inventoryStore.loadTransactions(),
  );
}
