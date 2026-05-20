import 'package:flutter/widgets.dart';

class GlobalOdometerController extends ChangeNotifier {
  GlobalOdometerController({int initialReading = 298150})
    : _reading = initialReading;

  int _reading;

  int get reading => _reading;

  String get displayValue => _reading.toString().padLeft(7, '0');

  OdometerUpdateResult updateFromText(String rawValue) {
    final cleaned = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) {
      return const OdometerUpdateResult.error('Enter an odometer reading.');
    }

    final parsed = int.tryParse(cleaned);
    if (parsed == null) {
      return const OdometerUpdateResult.error(
        'Use numbers only for the odometer reading.',
      );
    }

    if (parsed < 0) {
      return const OdometerUpdateResult.error(
        'Odometer readings cannot be negative.',
      );
    }

    if (parsed > 9999999) {
      return const OdometerUpdateResult.error(
        'This layout supports readings up to 9,999,999 miles.',
      );
    }

    if (parsed == _reading) {
      return const OdometerUpdateResult.success();
    }

    _reading = parsed;
    notifyListeners();
    return const OdometerUpdateResult.success();
  }
}

class OdometerUpdateResult {
  const OdometerUpdateResult._({required this.ok, this.message});

  const OdometerUpdateResult.success() : this._(ok: true);

  const OdometerUpdateResult.error(String message)
    : this._(ok: false, message: message);

  final bool ok;
  final String? message;
}

class GlobalOdometerScope extends InheritedNotifier<GlobalOdometerController> {
  const GlobalOdometerScope({
    super.key,
    required GlobalOdometerController controller,
    required super.child,
  }) : super(notifier: controller);

  static GlobalOdometerController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GlobalOdometerScope>();
    assert(scope != null, 'GlobalOdometerScope is missing above this context.');
    return scope!.notifier!;
  }
}
