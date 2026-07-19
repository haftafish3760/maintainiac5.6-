import 'dart:async';

import 'package:flutter/widgets.dart';

import 'device_capability.dart';
import 'device_capability_service.dart';

class DeviceCapabilityController extends ChangeNotifier {
  DeviceCapabilityController({DeviceCapabilityProbe? probe})
    : _probe = probe ?? DeviceCapabilityService.instance;

  final DeviceCapabilityProbe _probe;
  DeviceCapabilityProfile? _profile;
  Object? _lastError;
  bool _loading = false;
  bool _refreshPending = false;
  StreamSubscription<void>? _changeSubscription;
  Timer? _refreshDebounce;

  DeviceCapabilityProfile? get profile => _profile;
  Object? get lastError => _lastError;
  bool get isLoading => _loading;

  Future<void> initialize() {
    final probe = _probe;
    if (probe is DeviceCapabilityLiveProbe) {
      _changeSubscription ??= probe.changes.listen((_) {
        _refreshDebounce?.cancel();
        _refreshDebounce = Timer(
          const Duration(milliseconds: 250),
          () => unawaited(refreshRuntime()),
        );
      });
    }
    return _load(refresh: false);
  }

  /// Refreshes power, thermal, available-memory, and free-storage conditions.
  /// Stable hardware and camera facts remain cached by the service.
  Future<void> refreshRuntime() => _load(refresh: true);

  Future<void> _load({required bool refresh}) async {
    if (_loading) {
      _refreshPending = _refreshPending || refresh;
      return;
    }
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      _profile = await _probe.profile(refresh: refresh);
    } catch (error) {
      _lastError = error;
    } finally {
      _loading = false;
      notifyListeners();
      if (_refreshPending) {
        _refreshPending = false;
        unawaited(_load(refresh: true));
      }
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    unawaited(_changeSubscription?.cancel());
    super.dispose();
  }
}

class DeviceCapabilityScope
    extends InheritedNotifier<DeviceCapabilityController> {
  const DeviceCapabilityScope({
    super.key,
    required DeviceCapabilityController controller,
    required super.child,
  }) : super(notifier: controller);

  static DeviceCapabilityController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DeviceCapabilityScope>();
    assert(scope != null, 'DeviceCapabilityScope was not found.');
    return scope!.notifier!;
  }

  static DeviceCapabilityController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DeviceCapabilityScope>()
        ?.notifier;
  }

  static Future<void> refreshForHeavyWork(BuildContext context) async {
    final controller = maybeOf(context);
    if (controller != null) await controller.refreshRuntime();
  }
}
