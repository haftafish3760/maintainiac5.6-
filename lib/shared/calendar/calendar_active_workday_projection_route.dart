// Calendar routing for Dashboard-owned active-workday projection details.

import 'package:flutter/material.dart';

import '../../screens/dashboard/active_workday_session_detail_screen.dart';
import '../../screens/dashboard/data/active_workday_store.dart';
import '../navigation/app_page_routes.dart';
import 'calendar_projection_contract.dart';

bool calendarOpenActiveWorkdayProjectionRoute(
  BuildContext context,
  CalendarProjectionDeepLink deepLink,
) {
  if (deepLink.target != CalendarDeepLinkTarget.activeWorkday &&
      deepLink.target != CalendarDeepLinkTarget.vehicleProfileDetail) {
    return false;
  }
  final session = ActiveWorkdayScope.of(
    context,
  ).sessionById(deepLink.sourceRecordId);
  if (session == null) return false;

  Navigator.of(context).push(
    appNativeRoute<void>(
      context,
      ActiveWorkdaySessionDetailScreen(session: session),
    ),
  );
  return true;
}
