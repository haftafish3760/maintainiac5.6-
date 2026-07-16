import 'package:flutter/material.dart';

import 'odometer_entry_sheet.dart';
import '../state/global_odometer.dart';
import '../trip_tracking/trip_tracking_session_store.dart';

Future<bool> openOdometerEntry(
  BuildContext context, {
  String title = 'Update Odometer',
  String saveLabel = 'Save Reading',
  TripTrackingReviewRecord? tripReview,
}) async {
  final result = await openOdometerEntryResult(
    context,
    title: title,
    saveLabel: saveLabel,
    tripReview: tripReview,
  );
  return result != null;
}

Future<int?> openOdometerEntryResult(
  BuildContext context, {
  String title = 'Update Odometer',
  String saveLabel = 'Save Reading',
  TripTrackingReviewRecord? tripReview,
}) async {
  final odometer = GlobalOdometerScope.of(context);
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2E3A40),
    builder: (_) => GlobalOdometerScope(
      controller: odometer,
      child: OdometerEntrySheet(
        title: title,
        saveLabel: saveLabel,
        tripReview: tripReview,
      ),
    ),
  );
}
