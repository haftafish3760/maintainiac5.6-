import 'package:flutter/material.dart';

import 'odometer_entry_sheet.dart';
import 'odometer_distance_value.dart';
import '../state/global_odometer.dart';
import '../trip_tracking/trip_tracking_session_store.dart';

Future<bool> openOdometerEntry(
  BuildContext context, {
  String title = 'Update Odometer',
  String saveLabel = 'Save Reading',
  bool autofocus = true,
  String? helperText,
  int? minimumReading,
  String? minimumReadingMessage,
  OdometerMinimumReadingReviewHandler? onMinimumReadingReview,
  TripTrackingReviewRecord? tripReview,
  bool commitToOdometer = true,
}) async {
  final result = await openOdometerEntryResult(
    context,
    title: title,
    saveLabel: saveLabel,
    autofocus: autofocus,
    helperText: helperText,
    minimumReading: minimumReading,
    minimumReadingMessage: minimumReadingMessage,
    onMinimumReadingReview: onMinimumReadingReview,
    tripReview: tripReview,
    commitToOdometer: commitToOdometer,
  );
  return result != null;
}

Future<int?> openOdometerEntryResult(
  BuildContext context, {
  String title = 'Update Odometer',
  String saveLabel = 'Save Reading',
  bool autofocus = true,
  String? helperText,
  int? minimumReading,
  String? minimumReadingMessage,
  OdometerMinimumReadingReviewHandler? onMinimumReadingReview,
  TripTrackingReviewRecord? tripReview,
  bool commitToOdometer = true,
}) async {
  final exact = await openOdometerExactEntryResult(
    context,
    title: title,
    saveLabel: saveLabel,
    autofocus: autofocus,
    helperText: helperText,
    minimumReading: minimumReading,
    minimumReadingMessage: minimumReadingMessage,
    onMinimumReadingReview: onMinimumReadingReview,
    tripReview: tripReview,
    commitToOdometer: commitToOdometer,
  );
  return exact?.wholeReading;
}

Future<OdometerExactEntryResult?> openOdometerExactEntryResult(
  BuildContext context, {
  String title = 'Update Odometer',
  String saveLabel = 'Save Reading',
  bool autofocus = true,
  String? helperText,
  int? minimumReading,
  String? minimumReadingMessage,
  OdometerMinimumReadingReviewHandler? onMinimumReadingReview,
  TripTrackingReviewRecord? tripReview,
  bool commitToOdometer = true,
}) async {
  final odometer = GlobalOdometerScope.of(context);
  return showModalBottomSheet<OdometerExactEntryResult>(
    context: context,
    isScrollControlled: true,
    // Odometer entry is used in Start Day and End Day. Keep it inside the
    // application's dark modal system so its hierarchy is consistent with
    // the surrounding workday flow.
    backgroundColor: const Color(0xFF101719),
    builder: (_) => GlobalOdometerScope(
      controller: odometer,
      child: OdometerEntrySheet(
        title: title,
        saveLabel: saveLabel,
        autofocus: autofocus,
        helperText: helperText,
        minimumReading: minimumReading,
        minimumReadingMessage: minimumReadingMessage,
        onMinimumReadingReview: onMinimumReadingReview,
        tripReview: tripReview,
        commitToOdometer: commitToOdometer,
      ),
    ),
  );
}
