import 'app_month_calendar.dart';
import 'calendar_flow_models.dart';

class EmployeeCalendar extends AppMonthCalendar {
  const EmployeeCalendar({super.key})
    : super(source: CalendarFlowSource.employee);
}
