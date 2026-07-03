import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'job contract accepts confirmed estimate and inventory material lines',
    () {
      const contract = MaintainiacJobContract(
        jobId: 'job_1',
        accountId: 'acct_1',
        confirmedEstimateId: 'estimate_1',
        materials: [
          MaintainiacJobMaterialLine(
            id: 'material_1',
            source: MaintainiacJobMaterialSource.estimate,
            sourceId: 'estimate_line_1',
            quantity: 2,
            costCents: 1250,
            auditId: 'AUD-JOB-0001',
          ),
          MaintainiacJobMaterialLine(
            id: 'material_2',
            source: MaintainiacJobMaterialSource.inventoryMovement,
            sourceId: 'inventory_move_1',
            quantity: 3,
            costCents: 500,
            auditId: 'AUD-JOB-0002',
          ),
        ],
        summary: MaintainiacJobSummary(
          jobId: 'job_1',
          materialTotalCents: 4000,
          derivedFrom: ['material_1', 'material_2'],
        ),
      );

      expect(contract.validate(), isEmpty);
      expect(contract.materialTotalCents, 4000);
      expect(contract.toJson().toString(), contains('confirmedEstimateId'));
    },
  );

  test('job contract accepts receipt-backed time and material job', () {
    const contract = MaintainiacJobContract(
      jobId: 'job_receipt_1',
      accountId: 'acct_1',
      materials: [
        MaintainiacJobMaterialLine(
          id: 'receipt_material_1',
          source: MaintainiacJobMaterialSource.receipt,
          sourceId: 'receipt_line_1',
          quantity: 1,
          costCents: 899,
          auditId: 'AUD-JOB-0003',
        ),
      ],
      summary: MaintainiacJobSummary(
        jobId: 'job_receipt_1',
        materialTotalCents: 899,
        derivedFrom: ['receipt_material_1'],
      ),
    );

    expect(contract.validate(), isEmpty);
  });

  test('job contract rejects unsafe material and summary behavior', () {
    const contract = MaintainiacJobContract(
      jobId: 'job_bad',
      accountId: 'acct_1',
      materials: [
        MaintainiacJobMaterialLine(
          id: 'bad_material',
          source: MaintainiacJobMaterialSource.inventoryMovement,
          sourceId: '',
          quantity: 0,
          costCents: -1,
          auditId: '',
          localFirst: false,
          userConfirmed: false,
        ),
      ],
      summary: MaintainiacJobSummary(
        jobId: 'wrong_job',
        materialTotalCents: 999,
        derivedFrom: [],
        mutatesSource: true,
      ),
    );

    final failures = contract.validate().join('\n');

    expect(failures, contains('missing source id'));
    expect(failures, contains('quantity must be positive'));
    expect(failures, contains('cost must not be negative'));
    expect(failures, contains('missing audit id'));
    expect(failures, contains('must be local-first'));
    expect(failures, contains('must be user-confirmed'));
    expect(failures, contains('summary references wrong job'));
    expect(failures, contains('summary material total does not match'));
    expect(failures, contains('summary must not mutate source'));
    expect(
      failures,
      contains('needs confirmed estimate or receipt-backed material'),
    );
  });
}
