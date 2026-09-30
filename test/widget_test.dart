import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/main.dart';

Future<void> initializeFirebaseForTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

void main() {
  testWidgets('Login opens the farm dashboard', (tester) async {
    await initializeFirebaseForTest();
    await tester.pumpWidget(const FarmLedgerApp());

    expect(find.text('Farm Ledger'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'farmer');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Farm Dashboard'), findsOneWidget);
    expect(find.text('Cattle'), findsWidgets);
    expect(find.text('Feeds'), findsWidgets);
    expect(find.text('Production'), findsWidgets);
    expect(find.text('Finance'), findsWidgets);
  });

  testWidgets('A farmer can add cattle', (tester) async {
    await initializeFirebaseForTest();
    await tester.pumpWidget(const FarmLedgerApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'farmer');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cattle').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add cattle'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Malaika');
    await tester.enterText(find.byType(TextFormField).at(1), '12 Jan 2023');
    await tester.enterText(find.byType(TextFormField).at(2), '20 Mar 2023');
    await tester.tap(find.text('Save cow'));
    await tester.pumpAndSettle();

    expect(find.text('Malaika'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('Cow date fields use a date picker', (tester) async {
    await initializeFirebaseForTest();
    await tester.pumpWidget(const FarmLedgerApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'farmer');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cattle').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add cattle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Date of birth'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('Feed entries are saved as monthly records with date info', (
    tester,
  ) async {
    await initializeFirebaseForTest();
    await tester.pumpWidget(const FarmLedgerApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'farmer');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feeds').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();

    expect(find.text('Select cow'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'June 2026');
    await tester.enterText(find.byType(TextFormField).at(1), '12000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('June 2026'), findsOneWidget);
    expect(find.textContaining('KSh 12000'), findsOneWidget);
  });
}
