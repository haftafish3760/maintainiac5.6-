import 'package:cloud_functions/cloud_functions.dart';

/// Module-neutral callable Functions transport. Feature modules own payload
/// meaning; this shared adapter alone owns the Firebase SDK primitive.
abstract interface class MaintainiacCallableFunctionClient {
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  });
}

class FirebaseMaintainiacCallableFunctionClient
    implements MaintainiacCallableFunctionClient {
  FirebaseMaintainiacCallableFunctionClient({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    final result = await _functions
        .httpsCallable(name)
        .call<Map<String, dynamic>>(Map<String, dynamic>.from(data));
    return Map<String, Object?>.unmodifiable(result.data);
  }
}
