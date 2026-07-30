// Invoice calendar bridge. Invoice records remain owner-managed; this bridge
// uses the shared Calendar tile system so every Maintainiac screen matches.

import 'package:flutter/widgets.dart';

import '../../../shared/calendar/invoice_calendar.dart';
import 'invoice_home_models.dart';

class InvoiceMonthCalendarPanel extends StatelessWidget {
  const InvoiceMonthCalendarPanel({
    required this.entries,
    required this.onDaySelected,
    super.key,
  });

  /// Kept for source-screen compatibility. The shared InvoiceCalendar reads
  /// owner records for its state counts and opens the standard Calendar day
  /// view; the workspace still receives the selected date for its own list.
  final List<InvoiceTimelineEntry> entries;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) =>
      InvoiceCalendar(onDaySelected: onDaySelected);
}
