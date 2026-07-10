import 'maintainiac_expense_parser_consumer_contract.dart';
import 'maintainiac_inventory_parser_consumer_contract.dart';

class MaintainiacParserConsumerGate {
  const MaintainiacParserConsumerGate({
    required this.inventory,
    required this.expense,
  });

  final MaintainiacInventoryParserConsumerContract inventory;
  final MaintainiacExpenseParserConsumerContract expense;

  List<String> validate() {
    final failures = <String>[];
    failures.addAll([
      for (final issue in inventory.validate()) 'inventory:$issue',
      for (final issue in expense.validate()) 'expense:$issue',
    ]);
    if (inventory.liveServicesAllowed || expense.liveServicesAllowed) {
      failures.add('parser consumers must not allow live services');
    }
    if (inventory.firebaseWritesAllowed || expense.firebaseWritesAllowed) {
      failures.add('parser consumers must not allow Firebase writes');
    }
    if (inventory.ocrCameraImplementationTouched ||
        expense.ocrCameraImplementationTouched) {
      failures.add('parser consumers must not touch OCR/camera implementation');
    }
    if (!inventory.supportedResultUses.contains('job_materials')) {
      failures.add('inventory consumer must support job material routing');
    }
    if (!expense.supportedResultUses.contains('expense_draft')) {
      failures.add('expense consumer must support expense draft routing');
    }
    if (inventory.families.length + expense.families.length < 20) {
      failures.add('parser consumer gate needs at least 20 QA families');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'consumerCount': 2,
      'inventoryFamilyCount': inventory.families.length,
      'expenseFamilyCount': expense.families.length,
      'totalFamilyCount': inventory.families.length + expense.families.length,
      'liveServicesAllowed': false,
      'firebaseWritesAllowed': false,
      'ocrCameraImplementationTouched': false,
      'inventory': inventory.toJson(),
      'expense': expense.toJson(),
    };
  }
}

const maintainiacParserConsumerGate = MaintainiacParserConsumerGate(
  inventory: maintainiacInventoryParserConsumerContract,
  expense: maintainiacExpenseParserConsumerContract,
);
