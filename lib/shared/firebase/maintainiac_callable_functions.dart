import 'package:cloud_functions/cloud_functions.dart';

/// Module-neutral callable Functions transport. Feature modules own payload
/// meaning; this shared adapter alone owns the Firebase SDK primitive.
abstract interface class MaintainiacCallableFunctionClient {
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  });
}

class MaintainiacCallableFailure implements Exception {
  const MaintainiacCallableFailure({
    required this.code,
    required this.message,
    this.details = const {},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'Hosted operation failed ($code).';
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
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(Map<String, dynamic>.from(data));
      return Map<String, Object?>.unmodifiable(result.data);
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      throw MaintainiacCallableFailure(
        code: error.code.split('/').last,
        message: error.message ?? 'Hosted operation failed.',
        details: details is Map
            ? Map<String, Object?>.unmodifiable(
                Map<String, Object?>.from(details),
              )
            : const {},
      );
    }
  }
}
