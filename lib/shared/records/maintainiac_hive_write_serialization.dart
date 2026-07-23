/// Process-wide write serialization for shared Hive boxes.
///
/// Multiple screens may independently create a repository for the same box.
/// Serializing per repository instance is insufficient because both instances
/// can read the same revision and then overwrite one another. This boundary
/// keeps read-modify-write operations ordered by the actual durable box.
final class MaintainiacHiveWriteSerialization {
  MaintainiacHiveWriteSerialization._();

  static final Map<String, Future<void>> _tails = {};

  static Future<T> enqueue<T>(String boxName, Future<T> Function() operation) {
    final tail = _tails[boxName] ?? Future<void>.value();
    final next = tail.then((_) => operation());
    _tails[boxName] = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
