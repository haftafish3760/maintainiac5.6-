import 'dart:convert';
import 'dart:collection';

/// Validates and deep-freezes values before they cross a durable-storage
/// boundary. Module payload schemas remain module-owned, but every payload must
/// be portable, finite, acyclic, and bounded enough to recover safely.
class MaintainiacDurablePayload {
  const MaintainiacDurablePayload._();

  static const int maximumDepth = 32;
  static const int maximumValueCount = 100000;
  static const int maximumPortableInteger = 9007199254740991;

  static Map<String, dynamic> freeze(Map<String, dynamic> payload) {
    final traversal = _PayloadTraversal();
    return traversal.freezeRoot(payload);
  }

  /// Serialized size used to reserve device space before a durable write.
  /// Binary attachments use their own storage contract.
  static int encodedByteEstimate(Object? value) {
    final frozen = _PayloadTraversal().freezeAny(value);
    return utf8.encode(jsonEncode(_jsonSafe(frozen))).length;
  }

  static bool equivalent(Object? left, Object? right) {
    final frozenLeft = _PayloadTraversal().freezeAny(left);
    final frozenRight = _PayloadTraversal().freezeAny(right);
    return _equivalentValue(frozenLeft, frozenRight);
  }

  static Object? _jsonSafe(Object? value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is List) return value.map(_jsonSafe).toList(growable: false);
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key as String: _jsonSafe(entry.value),
      };
    }
    return value;
  }

  static bool _equivalentValue(Object? left, Object? right) {
    if (identical(left, right)) return true;
    if (left is DateTime && right is DateTime) {
      return left.isAtSameMomentAs(right);
    }
    if (left is num && right is num) return left == right;
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index += 1) {
        if (!_equivalentValue(left[index], right[index])) return false;
      }
      return true;
    }
    if (left is Map && right is Map) {
      if (left.length != right.length ||
          left.keys.any((key) => !right.containsKey(key))) {
        return false;
      }
      return left.keys.every(
        (key) => _equivalentValue(left[key], right[key]),
      );
    }
    return left == right;
  }
}

class _PayloadTraversal {
  final _activeCollections = HashSet<Object>.identity();
  var _valueCount = 0;

  Map<String, dynamic> freezeRoot(Map<String, dynamic> payload) {
    final frozen = _freeze(payload, 0);
    return frozen as Map<String, dynamic>;
  }

  Object? freezeAny(Object? value) => _freeze(value, 0);

  Object? _freeze(Object? value, int depth) {
    _valueCount += 1;
    if (_valueCount > MaintainiacDurablePayload.maximumValueCount) {
      throw ArgumentError('Durable payload contains too many values.');
    }
    if (depth > MaintainiacDurablePayload.maximumDepth) {
      throw ArgumentError('Durable payload nesting is too deep.');
    }
    if (value == null || value is bool || value is String) {
      return value;
    }
    if (value is int) {
      if (value.abs() > MaintainiacDurablePayload.maximumPortableInteger) {
        throw ArgumentError('Durable payload integer is not portable.');
      }
      return value;
    }
    if (value is double) {
      if (!value.isFinite) {
        throw ArgumentError('Durable payload numbers must be finite.');
      }
      return value;
    }
    if (value is DateTime) return value;
    if (value is Map) {
      return _freezeCollection(value, () {
        final frozen = <String, dynamic>{};
        for (final entry in value.entries) {
          if (entry.key is! String) {
            throw ArgumentError(
              'Durable payload object keys must be text values.',
            );
          }
          frozen[entry.key as String] = _freeze(entry.value, depth + 1);
        }
        return Map<String, dynamic>.unmodifiable(frozen);
      });
    }
    if (value is List) {
      return _freezeCollection(
        value,
        () => List<dynamic>.unmodifiable(
          value.map((item) => _freeze(item, depth + 1)),
        ),
      );
    }
    throw ArgumentError('Durable payload contains an unsupported value type.');
  }

  T _freezeCollection<T>(Object collection, T Function() freeze) {
    if (!_activeCollections.add(collection)) {
      throw ArgumentError('Durable payload contains a reference cycle.');
    }
    try {
      return freeze();
    } finally {
      _activeCollections.remove(collection);
    }
  }
}
