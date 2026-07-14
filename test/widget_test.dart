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
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE VEHICLE'), findsAtLeastNWidgets(1));
    expect(find.text('READY TO TRACK'), findsOneWidget);
    expect(find.text('Profit'), findsAtLeastNWidgets(1));
    expect(find.text('Fuel'), findsAtLeastNWidgets(1));
  });
}
