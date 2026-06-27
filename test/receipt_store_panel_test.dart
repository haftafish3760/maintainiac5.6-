import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_form_sections.dart';

void main() {
  late TextEditingController store;
  late TextEditingController phone;
  late TextEditingController street;
  late TextEditingController city;
  late TextEditingController state;
  late TextEditingController zip;
  late TextEditingController email;
  late TextEditingController website;
  late TextEditingController notes;

  setUp(() {
    store = TextEditingController();
    phone = TextEditingController();
    street = TextEditingController();
    city = TextEditingController();
    state = TextEditingController();
    zip = TextEditingController();
    email = TextEditingController();
    website = TextEditingController();
    notes = TextEditingController();
  });

  tearDown(() {
    store.dispose();
    phone.dispose();
    street.dispose();
    city.dispose();
    state.dispose();
    zip.dispose();
    email.dispose();
    website.dispose();
    notes.dispose();
  });

  Widget host({required VoidCallback onChanged}) {
    return MaterialApp(
      home: Scaffold(
        body: SharedReceiptStorePanel(
          store: store,
          phone: phone,
          street: street,
          city: city,
          state: state,
          zip: zip,
          email: email,
          website: website,
          notes: notes,
          onChanged: onChanged,
        ),
      ),
    );
  }

  testWidgets('saves store information back to the receipt draft', (
    tester,
  ) async {
    var changeCount = 0;

    await tester.pumpWidget(host(onChanged: () => changeCount++));
    await tester.tap(find.text('Store Info'));
    await tester.pumpAndSettle();

    expect(find.text('Save And Continue'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, "Lowe's");
    await tester.tap(find.text('Save And Continue'));
    await tester.pumpAndSettle();

    expect(store.text, "Lowe's");
    expect(changeCount, 1);
    expect(find.text("Lowe's"), findsOneWidget);
  });

  testWidgets('cancel keeps the parent receipt draft unchanged', (
    tester,
  ) async {
    store.text = 'Home Depot';
    var changeCount = 0;

    await tester.pumpWidget(host(onChanged: () => changeCount++));
    await tester.tap(find.text('Home Depot'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, "Lowe's");
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(store.text, 'Home Depot');
    expect(changeCount, 0);
  });
}
