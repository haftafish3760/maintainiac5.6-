import 'package:flutter/material.dart';

import 'odometer_entry_sheet.dart';
import '../trip_tracking/trip_tracking_session_store.dart';

Future<bool> openOdometerEntry(
  BuildContext context, {
  String title = 'Update Odometer',
  String saveLabel = 'Save Reading',
  TripTrackingReviewRecord? tripReview,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2E3A40),
    builder: (_) => OdometerEntrySheet(
      title: title,
      saveLabel: saveLabel,
      tripReview: tripReview,
    ),
  );
  return saved ?? false;
}
