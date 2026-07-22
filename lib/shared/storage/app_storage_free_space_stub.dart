/// Pure-Dart fallback used by command-line QA. Runtime callers receive the
/// Flutter implementation through the conditional import in the guard.
Future<double?> readAppFreeDiskSpaceMb() async => null;
