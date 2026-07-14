import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'incoming_receipt_destination_screen.dart';
import '../screens/dashboard/dashboard.dart';
import '../main.dart';
import '../shared/navigation/app_page_routes.dart';
import '../shared/theme/app_theme.dart';
import '../shared/trip_tracking/trip_tracking_controller.dart';
import '../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../shared/widgets/receipt_capture/incoming_receipt_share.dart';
import '../shared/localization/maintaniac_localizations.dart';

class MaintaniacApp extends StatefulWidget {
  const MaintaniacApp({super.key});

  @override
  State<MaintaniacApp> createState() => _MaintaniacAppState();
}

class _MaintaniacAppState extends State<MaintaniacApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  IncomingReceiptShareController? _incomingShare;
  var _openingIncomingShare = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _incomingShare?.removeListener(_handleIncomingShare);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
    return MaterialApp(
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
        pageTransitionsTheme: const PageTransitionsTheme(
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
    );
  }
}
