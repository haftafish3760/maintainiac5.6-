import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'incoming_receipt_destination_screen.dart';
import '../screens/dashboard/dashboard.dart';
import '../main.dart';
import '../shared/navigation/app_page_routes.dart';
import '../shared/device_capabilities/device_capability_scope.dart';
import '../shared/theme/app_theme.dart';
import '../shared/trip_tracking/trip_tracking_controller.dart';
import '../shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import '../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../shared/widgets/receipt_capture/incoming_receipt_share.dart';
import '../shared/localization/maintaniac_localizations.dart';

class MaintaniacApp extends StatefulWidget {
  const MaintaniacApp({super.key, required this.bluetoothTripRuntime});

  final TripTrackingBluetoothRuntimeController bluetoothTripRuntime;

  @override
  State<MaintaniacApp> createState() => _MaintaniacAppState();
}

class _MaintaniacAppState extends State<MaintaniacApp>
    with WidgetsBindingObserver {
  static const _tripHeartbeatCheckInterval = Duration(seconds: 30);

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _deviceCapabilities = DeviceCapabilityController();
  IncomingReceiptShareController? _incomingShare;
  Timer? _tripHeartbeatTimer;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  var _tripHeartbeatCheckInFlight = false;
  var _openingIncomingShare = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _tripHeartbeatTimer = Timer.periodic(
      _tripHeartbeatCheckInterval,
      (_) => unawaited(_checkForegroundTripHeartbeat()),
    );
    unawaited(_deviceCapabilities.initialize());
    unawaited(widget.bluetoothTripRuntime.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = IncomingReceiptShareScope.maybeOf(context);
    if (_incomingShare == controller) return;
    _incomingShare?.removeListener(_handleIncomingShare);
    _incomingShare = controller;
    controller?.addListener(_handleIncomingShare);
    _handleIncomingShare();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tripHeartbeatTimer?.cancel();
    _deviceCapabilities.dispose();
    _incomingShare?.removeListener(_handleIncomingShare);
    widget.bluetoothTripRuntime.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(_deviceCapabilities.refreshRuntime());
      unawaited(widget.bluetoothTripRuntime.start());
    }
    final tripTracking = TripTrackingScope.maybeOf(context);
    final settings = TripTrackingSettingsScope.maybeOf(context);
    if (tripTracking == null || settings == null) return;
    unawaited(
      tripTracking.handleAppLifecycleState(
        state,
        backgroundTrackingAllowed: settings.settings.backgroundTrackingEnabled,
      ),
    );
  }

  Future<void> _checkForegroundTripHeartbeat() async {
    if (!mounted ||
        _appLifecycleState != AppLifecycleState.resumed ||
        _tripHeartbeatCheckInFlight) {
      return;
    }
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (tripTracking == null || !tripTracking.nativeTracking) return;
    _tripHeartbeatCheckInFlight = true;
    try {
      await tripTracking.checkNativeHeartbeat();
    } finally {
      _tripHeartbeatCheckInFlight = false;
    }
  }

  void _handleIncomingShare() {
    if (_openingIncomingShare) return;
    final incoming = _incomingShare?.pending;
    if (incoming == null || !incoming.hasContent) return;
    _openingIncomingShare = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _incomingShare;
      final share = controller?.pending;
      if (controller == null || share == null || !share.hasContent) {
        _openingIncomingShare = false;
        return;
      }
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _openingIncomingShare = false;
        return;
      }
      final takenShare = controller.takePending();
      if (takenShare == null || !takenShare.hasContent) {
        _openingIncomingShare = false;
        return;
      }
      navigator
          .push(
            appNativeRoute<void>(
              navigator.context,
              IncomingReceiptDestinationScreen(
                attachments: takenShare.attachments,
                importedText: takenShare.importedText,
                messages: takenShare.messages,
              ),
            ),
          )
          .whenComplete(() => _openingIncomingShare = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TripTrackingBluetoothRuntimeScope(
      controller: widget.bluetoothTripRuntime,
      child: DeviceCapabilityScope(
        controller: _deviceCapabilities,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Maintaniac',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            MaintaniacLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: MaintaniacLocalizations.supportedLocales,
          theme: buildMaintaniacTheme().copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: AppSlidePageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: AppSlidePageTransitionsBuilder(),
                TargetPlatform.linux: AppSlidePageTransitionsBuilder(),
              },
            ),
          ),
          home: const AnnotatedRegion<SystemUiOverlayStyle>(
            value: maintaniacSystemUiStyle,
            child: DashboardScreen(),
          ),
        ),
      ),
    );
  }
}
