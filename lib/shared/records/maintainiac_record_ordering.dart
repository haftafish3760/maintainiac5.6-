int compareMaintainiacRecordsNewestFirst({
  required DateTime leftUpdatedAt,
  required int leftRevision,
  required String leftId,
  required DateTime rightUpdatedAt,
  required int rightRevision,
  required String rightId,
}) {
  final byUpdatedAt = rightUpdatedAt.compareTo(leftUpdatedAt);
  if (byUpdatedAt != 0) return byUpdatedAt;

  final byRevision = rightRevision.compareTo(leftRevision);
  if (byRevision != 0) return byRevision;

  return leftId.compareTo(rightId);
}
