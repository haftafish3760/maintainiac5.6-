import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/home/invoices_home_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  late AppStateController appState;
  late GlobalOdometerController odometer;

  setUp(() {
    appState = AppStateController();
    odometer = GlobalOdometerController();
  });

  tearDown(() {
    appState.dispose();
    odometer.dispose();
  });

  testWidgets('invoice command center exposes launcher actions', (
    tester,
  ) async {
    await _pumpInvoices(tester, appState, odometer);

    expect(find.text('INVOICE VIEW'), findsOneWidget);
    expect(find.text('Work Truck 1'), findsOneWidget);
    expect(find.text('Invoices, Estimates, and Payments'), findsOneWidget);
    expect(find.text('Saved Clients'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Invoices'), findsWidgets);
    expect(find.byKey(const Key('invoice-home-calendar')), findsOneWidget);
    expect(find.text('New Invoice'), findsNothing);
  });

  testWidgets('invoice landing FAB combines all primary invoice actions', (
    tester,
  ) async {
    await _pumpInvoices(tester, appState, odometer);

    await tester.tap(find.text('Invoice Actions'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Invoice'), findsOneWidget);
    expect(find.text('Create New Estimate'), findsOneWidget);
    expect(find.text('Record Payment'), findsOneWidget);
    expect(find.text('Add New Contact'), findsOneWidget);
    expect(find.text('My Info'), findsWidgets);

    await tester.tap(find.text('Create New Invoice'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice Information'), findsOneWidget);
    expect(find.text('Save Invoice'), findsNothing);
  });

  testWidgets('company logo import explains photo access before picker opens', (
    tester,
  ) async {
    await _pumpInvoices(tester, appState, odometer);

    await tester.tap(find.byKey(const Key('invoice-quick-action-myInfo')));
    await tester.pumpAndSettle();
    expect(find.text('My Info'), findsOneWidget);
    expect(find.text('Business Name'), findsOneWidget);

    await tester.tap(find.text('Import Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Logo Photo'), findsWidgets);
    expect(
      find.textContaining('only receives the logo image you choose'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets(
    'bottom nav returns to invoice landing from nested invoice screens',
    (tester) async {
      await _pumpInvoices(tester, appState, odometer);

      await tester.tap(
        find.byKey(const Key('invoice-quick-action-createInvoice')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invoice Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create New Invoice'));
      await tester.pumpAndSettle();
      expect(find.text('Invoice Information'), findsOneWidget);

      await tester.tap(find.text('Invoices').last);
      await tester.pumpAndSettle();

      expect(find.text('Invoices, Estimates, and Payments'), findsOneWidget);
      expect(find.byKey(const Key('invoice-home-calendar')), findsOneWidget);
      expect(find.text('Invoice Information'), findsNothing);
    },
  );

  testWidgets('estimate workspace shows day entries without money recap', (
    tester,
  ) async {
    await _pumpInvoices(tester, appState, odometer);

    await tester.tap(
      find.byKey(const Key('invoice-quick-action-createEstimate')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estimates'), findsWidgets);
    expect(find.text('Estimates for this day'), findsOneWidget);
    expect(find.text('Potential'), findsNothing);
    expect(find.text('Daily'), findsNothing);
    expect(find.text('Weekly'), findsNothing);
    expect(find.text('Past 90'), findsNothing);
    expect(find.byKey(const Key('invoice-status-draft')), findsNothing);
    expect(find.byKey(const Key('invoice-status-sent')), findsNothing);
    expect(find.byKey(const Key('invoice-status-approved')), findsNothing);
    expect(find.byKey(const Key('invoice-status-paid')), findsNothing);
    expect(find.byKey(const Key('invoice-status-unpaid')), findsNothing);
    expect(find.byKey(const Key('invoice-status-overdue')), findsNothing);
    expect(find.text('Estimate Actions'), findsOneWidget);
  });

  testWidgets('invoice FAB opens actions and create routes to invoice form', (
    tester,
  ) async {
    await _pumpInvoices(tester, appState, odometer);

    await tester.tap(
      find.byKey(const Key('invoice-quick-action-createInvoice')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total Paid'), findsOneWidget);
    expect(find.text('Total Unpaid'), findsOneWidget);
    expect(find.text('Total Overdue'), findsOneWidget);
    expect(find.text('Upcoming'), findsWidgets);

    await tester.tap(find.text('Invoice Actions'));
    await tester.pumpAndSettle();
    expect(find.text('Create New Invoice'), findsOneWidget);
    expect(find.text('View Drafts'), findsOneWidget);
    expect(find.text('Saved Clients'), findsOneWidget);

    await tester.tap(find.text('Create New Invoice'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice Information'), findsOneWidget);
    final today = DateTime.now();
    final dueDay = today.add(const Duration(days: 30));
    expect(
      find.textContaining(
        'Date ${_shortDate(today)} • Due ${_shortDate(dueDay)}',
      ),
      findsOneWidget,
    );
    expect(find.text('Select A Template'), findsOneWidget);
    expect(find.text('Structured With Logo'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Company Information'),
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(find.text('Company Information'), findsOneWidget);
    expect(find.text('Client Information'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Subtotal'),
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Save Invoice'),
      find.byType(ListView).first,
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save Invoice'), findsOneWidget);
  });

  testWidgets('invoice form rows open their detail flows', (tester) async {
    await _pumpInvoices(tester, appState, odometer);

    await tester.tap(
      find.byKey(const Key('invoice-quick-action-createInvoice')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invoice Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create New Invoice'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Invoice Information'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice Title'), findsOneWidget);
    expect(find.text('Invoice Number'), findsOneWidget);
    expect(find.text('PO Number'), findsOneWidget);
    expect(find.text('Invoice Date'), findsOneWidget);
    expect(find.text('Due Date'), findsOneWidget);
    final today = DateTime.now();
    expect(find.text(_shortDate(today)), findsOneWidget);
    expect(
      find.text(_shortDate(today.add(const Duration(days: 30)))),
      findsOneWidget,
    );
    expect(find.text('Clear Due Date'), findsOneWidget);
    await tester.tap(find.text('Invoice Date'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select A Template'));
    await tester.pumpAndSettle();
    expect(find.text('Trades'), findsOneWidget);
    expect(find.text('Landscaping'), findsOneWidget);
    expect(find.text('Landscape Garden Artwork'), findsOneWidget);
    expect(find.text('Plumbing Copper'), findsNothing);
    await tester.ensureVisible(find.text('Landscape Garden Artwork'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Landscape Garden Artwork'));
    await tester.pumpAndSettle();
    expect(find.text('Use This Template'), findsOneWidget);
    await tester.tap(find.text('Use This Template'));
    await tester.pumpAndSettle();
    expect(find.text('Landscape Garden Artwork'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Items'),
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Items'));
    await tester.pumpAndSettle();
    expect(find.text('Items & Materials'), findsOneWidget);
    expect(find.text('Add From Materials'), findsOneWidget);
    expect(find.text('Add New'), findsOneWidget);
    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();
    expect(find.text('Create Item'), findsOneWidget);
    expect(find.text('Unit Of Measure'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Discount'),
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discount'));
    await tester.pumpAndSettle();
    expect(find.text('Discount Amount'), findsOneWidget);
    expect(find.text('Discount Percent'), findsOneWidget);
  });

  testWidgets('invoice signature row captures owner and customer signatures', (
    tester,
  ) async {
    await _pumpInvoices(tester, appState, odometer);

    await tester.tap(
      find.byKey(const Key('invoice-quick-action-createInvoice')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invoice Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create New Invoice'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Signature'),
      find.byType(ListView).first,
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Signature'));
    await tester.pumpAndSettle();
    expect(find.text('Add My Signature'), findsOneWidget);
    expect(find.text('Add Customer Signature'), findsOneWidget);

    await tester.tap(find.text('Add My Signature'));
    await tester.pumpAndSettle();
    final ownerCanvas = find.byKey(const Key('app-signature-canvas'));
    await tester.dragFrom(tester.getCenter(ownerCanvas), const Offset(110, 38));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Signature'));
    await tester.pumpAndSettle();
    expect(
      find.text('My signature was added to this invoice.'),
      findsOneWidget,
    );
    expect(find.text('My signature saved'), findsOneWidget);

    await tester.tap(find.text('Signature'));
    await tester.pumpAndSettle();
    expect(find.text('Add My Signature'), findsOneWidget);
    expect(find.text('Add Customer Signature'), findsOneWidget);
    await tester.tap(find.text('Add Customer Signature'));
    await tester.pumpAndSettle();
    final customerCanvas = find.byKey(const Key('app-signature-canvas'));
    await tester.dragFrom(
      tester.getCenter(customerCanvas),
      const Offset(100, 36),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Save Signature'));
    await tester.pumpAndSettle();

    expect(
      find.text('My signature and customer signature saved'),
      findsOneWidget,
    );
  });

  testWidgets('tapping invoice status filters the calendar day view', (
    tester,
  ) async {
    await _pumpInvoices(tester, appState, odometer);

    await tester.tap(
      find.byKey(const Key('invoice-quick-action-createInvoice')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invoice-status-overdue')));
    await tester.pumpAndSettle();

    expect(find.text('Oak Street repair'), findsOneWidget);
    expect(find.text('Smith kitchen repair'), findsNothing);
  });
}

String _shortDate(DateTime day) => '${day.month}/${day.day}/${day.year}';

Future<void> _pumpInvoices(
  WidgetTester tester,
  AppStateController appState,
  GlobalOdometerController odometer,
) {
  return tester.pumpWidget(
    AppStateScope(
      controller: appState,
      child: GlobalOdometerScope(
        controller: odometer,
        child: const MaterialApp(home: InvoicesScreen()),
      ),
    ),
  );
}
