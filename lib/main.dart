import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/maintaniac_app.dart';
import 'shared/state/app_state.dart';
import 'shared/state/global_odometer.dart';

const maintaniacSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Color(0xFF050607),
  systemNavigationBarIconBrightness: Brightness.light,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(maintaniacSystemUiStyle);
  runApp(
    AppStateScope(
      controller: AppStateController(),
      child: GlobalOdometerScope(
        controller: GlobalOdometerController(),
        child: const MaintaniacApp(),
      ),
    ),
  );
}
