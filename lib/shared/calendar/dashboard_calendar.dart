import 'app_month_calendar.dart';
import 'calendar_flow_models.dart';

class DashboardCalendar extends AppMonthCalendar {
  const DashboardCalendar({super.key})
    : super(source: CalendarFlowSource.dashboard);
}
