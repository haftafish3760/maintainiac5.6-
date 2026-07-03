import 'maintainiac_qa_environment.dart';

class MaintainiacQaBuilders {
  const MaintainiacQaBuilders._();

  static Map<String, Object?> user({
    String id = 'user_1',
    String accountId = 'acct_1',
  }) {
    return {'id': id, 'accountId': accountId};
  }

  static Map<String, Object?> account({
    String id = 'acct_1',
    String ownerUserId = 'user_1',
  }) {
    return {'id': id, 'ownerUserId': ownerUserId};
  }

  static Map<String, Object?> profile({
    String id = 'profile_1',
    String userId = 'user_1',
  }) {
    return {'id': id, 'userId': userId};
  }

  static Map<String, Object?> vehicle({
    String id = 'vehicle_1',
    String accountId = 'acct_1',
    int odometer = 10000,
  }) {
    return {'id': id, 'accountId': accountId, 'odometer': odometer};
  }

  static Map<String, Object?> odometerSnapshot({
    String id = 'odometer_snapshot_1',
    int miles = 10000,
    String vehicleId = 'vehicle_1',
  }) {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'miles': miles,
      'confirmed': true,
    };
  }

  static Map<String, Object?> dayLog({String id = 'day_2026_07_03'}) {
    return {'id': id, 'date': '2026-07-03', 'source': 'local'};
  }

  static Map<String, Object?> trip({
    String id = 'trip_1',
    int startOdometer = 10000,
    int endOdometer = 10018,
  }) {
    return {
      'id': id,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
    };
  }

  static Map<String, Object?> tripEvent({String type = 'start'}) {
    return {
      'id': 'trip_event_1',
      'type': type,
      'createdAt': '2026-07-03T12:00:00Z',
    };
  }

  static Map<String, Object?> expense({
    String id = 'expense_1',
    int cents = 1299,
    String category = 'fuel',
  }) {
    return {
      'id': id,
      'amountCents': cents,
      'category': category,
      'confirmed': true,
    };
  }

  static Map<String, Object?> receipt({String id = 'receipt_1'}) {
    return {'id': id, 'reviewStatus': 'suggested', 'rawTextStored': false};
  }

  static Map<String, Object?> receiptSegment({int index = 0}) {
    return {'id': 'segment_$index', 'index': index, 'merged': false};
  }

  static Map<String, Object?> ocrResult({String text = 'LOWES PVC 90 1/2'}) {
    return {'id': 'ocr_1', 'text': text, 'isSuggestion': true};
  }

  static Map<String, Object?> inventoryItem({String id = 'inv_1'}) {
    return {'id': id, 'onHand': 1, 'vehicleId': 'vehicle_1'};
  }

  static Map<String, Object?> catalogItem({String id = 'cat_1'}) {
    return {
      'id': id,
      'canonicalName': '1/2 in PVC elbow',
      'aliases': ['PVC 90'],
    };
  }

  static Map<String, Object?> inventoryMovement({int quantity = 1}) {
    return {
      'id': 'move_1',
      'quantity': quantity,
      'reason': 'receipt_confirmed',
    };
  }

  static Map<String, Object?> job({String id = 'job_1'}) {
    return {
      'id': id,
      'status': 'active',
      'tradeSections': ['plumbing'],
    };
  }

  static Map<String, Object?> estimate({String id = 'estimate_1'}) {
    return {'id': id, 'status': 'draft', 'totalCents': 10000};
  }

  static Map<String, Object?> invoice({String id = 'invoice_1'}) {
    return {'id': id, 'status': 'draft', 'totalCents': 10000};
  }

  static Map<String, Object?> maintenanceEntry({String id = 'maint_1'}) {
    return {'id': id, 'vehicleId': 'vehicle_1', 'type': 'oil_change'};
  }

  static Map<String, Object?> calendarEdit({String id = 'cal_edit_1'}) {
    return {'id': id, 'date': '2026-07-03', 'targetType': 'job'};
  }

  static Map<String, Object?> auditEntry({String id = 'audit_1'}) {
    return {'id': id, 'actorId': 'user_1', 'action': 'confirmed_suggestion'};
  }

  static Map<String, Object?> syncConflict({String id = 'conflict_1'}) {
    return {'id': id, 'field': 'amountCents', 'resolution': 'needs_review'};
  }

  static Map<String, Object?> exportRequest({String id = 'export_1'}) {
    return {'id': id, 'ownerAccountId': 'acct_1', 'format': 'csv'};
  }

  static Map<String, Object?> notificationEvent({String id = 'note_1'}) {
    return {'id': id, 'type': 'expense_reminder', 'sourceMutation': false};
  }

  static Map<String, Object?> company({String id = 'company_1'}) {
    return {'id': id, 'accountId': 'acct_1'};
  }

  static Map<String, Object?> employee({String id = 'employee_1'}) {
    return {
      'id': id,
      'companyId': 'company_1',
      'permissions': ['read'],
    };
  }

  static Map<String, Object?> fleetVehicle({String id = 'fleet_vehicle_1'}) {
    return {'id': id, 'companyId': 'company_1', 'vehicleId': 'vehicle_1'};
  }

  static MaintainiacQaEnvironment environment() {
    return MaintainiacQaEnvironment.standard();
  }
}
