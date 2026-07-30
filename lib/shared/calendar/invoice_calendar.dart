import 'app_month_calendar.dart';
import 'calendar_flow_models.dart';

class InvoiceCalendar extends AppMonthCalendar {
  const InvoiceCalendar({super.key, super.onDaySelected})
    : super(source: CalendarFlowSource.invoices);
}
