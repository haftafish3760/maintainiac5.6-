import 'app_month_calendar.dart';
import 'calendar_flow_models.dart';

class ExpenseAppCalendar extends AppMonthCalendar {
  const ExpenseAppCalendar({super.key})
    : super(source: CalendarFlowSource.expenses);
}
