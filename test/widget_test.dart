import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/app/maintaniac_app.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  testWidgets('Maintaniac app starts on the dashboard', (tester) async {
    await tester.pumpWidget(
      AppStateScope(
        controller: AppStateController(),
        child: GlobalOdometerScope(
          controller: GlobalOdometerController(),
          child: const MaintaniacApp(),
        ),
      ),
    );

    expect(find.text('ODOMETER'), findsOneWidget);
    expect(find.text('WEEKLY RECAP'), findsOneWidget);
    expect(find.text('READY TO TRACK'), findsOneWidget);
  });
}
