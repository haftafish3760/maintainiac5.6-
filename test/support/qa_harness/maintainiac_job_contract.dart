enum MaintainiacJobMaterialSource { estimate, inventoryMovement, receipt }

class MaintainiacJobMaterialLine {
  const MaintainiacJobMaterialLine({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.quantity,
    required this.costCents,
    required this.auditId,
    this.localFirst = true,
    this.userConfirmed = true,
  });

  final String id;
  final MaintainiacJobMaterialSource source;
  final String sourceId;
  final int quantity;
  final int costCents;
  final String auditId;
  final bool localFirst;
  final bool userConfirmed;

  int get totalCents => quantity * costCents;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('job material missing id');
    if (sourceId.trim().isEmpty) failures.add('$id missing source id');
    if (quantity <= 0) failures.add('$id quantity must be positive');
    if (costCents < 0) failures.add('$id cost must not be negative');
    if (auditId.trim().isEmpty) failures.add('$id missing audit id');
    if (!localFirst) failures.add('$id job material must be local-first');
    if (!userConfirmed) {
      failures.add('$id job material must be user-confirmed');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'source': source.name,
      'sourceId': sourceId,
      'quantity': quantity,
      'costCents': costCents,
      'totalCents': totalCents,
      'auditId': auditId,
      'localFirst': localFirst,
      'userConfirmed': userConfirmed,
    };
  }
}

class MaintainiacJobSummary {
  const MaintainiacJobSummary({
    required this.jobId,
    required this.materialTotalCents,
    required this.derivedFrom,
    this.mutatesSource = false,
  });

  final String jobId;
  final int materialTotalCents;
  final List<String> derivedFrom;
  final bool mutatesSource;

  List<String> validate() {
    final failures = <String>[];
    if (jobId.trim().isEmpty) failures.add('job summary missing job id');
    if (materialTotalCents < 0) {
      failures.add('$jobId material total must not be negative');
    }
    if (derivedFrom.isEmpty) failures.add('$jobId summary missing sources');
    if (mutatesSource) failures.add('$jobId summary must not mutate source');
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'jobId': jobId,
      'materialTotalCents': materialTotalCents,
      'derivedFrom': derivedFrom,
      'mutatesSource': mutatesSource,
    };
  }
}

class MaintainiacJobContract {
  const MaintainiacJobContract({
    required this.jobId,
    required this.accountId,
    required this.materials,
    required this.summary,
    this.confirmedEstimateId = '',
  });

  final String jobId;
  final String accountId;
  final String confirmedEstimateId;
  final List<MaintainiacJobMaterialLine> materials;
  final MaintainiacJobSummary summary;

  int get materialTotalCents {
    return materials.fold(0, (sum, line) => sum + line.totalCents);
  }

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (jobId.trim().isEmpty) failures.add('job contract missing job id');
    if (accountId.trim().isEmpty) failures.add('$jobId missing account id');
    if (materials.isEmpty) failures.add('$jobId has no material lines');
    for (final line in materials) {
      if (!ids.add(line.id)) {
        failures.add('duplicate job material id ${line.id}');
      }
      failures.addAll(line.validate());
    }
    failures.addAll(summary.validate());
    if (summary.jobId != jobId) {
      failures.add('$jobId summary references wrong job ${summary.jobId}');
    }
    if (summary.materialTotalCents != materialTotalCents) {
      failures.add('$jobId summary material total does not match materials');
    }
    if (confirmedEstimateId.trim().isEmpty &&
        !materials.any(
          (line) => line.source == MaintainiacJobMaterialSource.receipt,
        )) {
      failures.add(
        '$jobId needs confirmed estimate or receipt-backed material',
      );
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'jobId': jobId,
      'accountId': accountId,
      if (confirmedEstimateId.isNotEmpty)
        'confirmedEstimateId': confirmedEstimateId,
      'materialTotalCents': materialTotalCents,
      'materials': [for (final line in materials) line.toJson()],
      'summary': summary.toJson(),
    };
  }
}
