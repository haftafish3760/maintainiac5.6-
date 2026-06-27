import 'app_month_calendar.dart';
import 'calendar_flow_models.dart';

class ContractorCalendar extends AppMonthCalendar {
  const ContractorCalendar({super.key})
    : super(source: CalendarFlowSource.contractor);
}
