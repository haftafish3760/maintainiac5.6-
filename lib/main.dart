import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/maintaniac_app.dart';
import 'shared/state/app_state.dart';
import 'shared/state/expense_settings_store.dart';
import 'shared/state/global_odometer.dart';

const maintaniacSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Color(0xFF050607),
  systemNavigationBarIconBrightness: Brightness.light,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final expenseSettings = await ExpenseSettingsController.create();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(maintaniacSystemUiStyle);
  runApp(
    AppStateScope(
      controller: AppStateController(),
      child: ExpenseSettingsScope(
        controller: expenseSettings,
        child: GlobalOdometerScope(
          controller: GlobalOdometerController(),
          child: const MaintaniacApp(),
        ),
      ),
    ),
  );
}
