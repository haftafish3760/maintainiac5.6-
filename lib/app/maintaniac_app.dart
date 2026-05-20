import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/dashboard/dashboard.dart';
import '../main.dart';
import '../shared/navigation/app_page_routes.dart';
import '../shared/theme/app_theme.dart';

class MaintaniacApp extends StatelessWidget {
  const MaintaniacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maintaniac',
      debugShowCheckedModeBanner: false,
      theme: buildMaintaniacTheme().copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: AppSlidePageTransitionsBuilder(),
            TargetPlatform.iOS: AppSlidePageTransitionsBuilder(),
            TargetPlatform.macOS: AppSlidePageTransitionsBuilder(),
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
