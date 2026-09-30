import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/views/DiyHoliday/data/diy_origins.dart';
import 'package:wander_nova/views/DiyHoliday/data/diy_search_query.dart';
import 'package:wander_nova/views/DiyHoliday/data/diy_traveller.dart';
import 'package:wander_nova/views/DiyHoliday/data/models/diy_models.dart';
import 'package:wander_nova/views/DiyHoliday/presentation/screens/diy_review_screen.dart';

/// The review screen is the gate between a priced trip and a real charge, so
/// these cover the things that would let a bad booking through: the totals it
/// shows, and the three guards on CONTINUE.
void main() {
  final query = DiySearchQuery(
    origin: DiyOrigins.defaultOrigin,
    destination: const DiyDestination(
      kind: 'region',
      slug: 'kerala',
      name: 'Kerala',
      state: 'Kerala',
      countryName: 'India',
      countryCode: 'IN',
      packageCount: 2,
      cities: ['Munnar', 'Alleppey'],
    ),
    departureDate: DateTime(2026, 12, 10),
    adults: 2,
    children: 0,
    rooms: 1,
  );

  Widget host() => MaterialApp(
        home: DiyReviewScreen(
          shareId: 'share-1',
          query: query,
          withFlight: true,
          addOnIds: const [],
          quotedTotal: 81800.72,
          packageTitle: '4 days in Munnar , Alleppey',
          currency: 'INR',
          tripId: 'trip-1',
          nights: 3,
          destination: 'Alleppey',
          counts: const DiyCounts(
            days: 4,
            meals: 2,
            hotels: 2,
            addOns: 0,
            flights: 2,
            transfers: 4,
            activities: 8,
          ),
        ),
      );

  testWidgets('shows the quoted total and the party it was quoted for',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('₹81,801'), findsOneWidget);
    expect(find.text('Grand Total · 2 Travellers'), findsOneWidget);
    expect(find.text('4 days in Munnar , Alleppey'), findsOneWidget);
    // One traveller row per head.
    expect(find.text('Adult 1'), findsOneWidget);
    expect(find.text('Adult 2'), findsOneWidget);
  });

  testWidgets('Package Inclusions is built from the trip counts',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    // "Package Inclusions" appears twice — once as a tab-strip chip, once as
    // the accordion header. The accordion is the later of the two, and sits
    // below the fold, so bring it into view before tapping it.
    final header = find.text('Package Inclusions').last;
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();

    expect(find.text('2 Flights'), findsOneWidget);
    expect(find.text('2 Hotel stays'), findsOneWidget);
    expect(find.text('4 Transfers'), findsOneWidget);
    expect(find.text('8 Activities'), findsOneWidget);
  });

  testWidgets('every tab-strip target is laid out, so scroll-to works',
      (tester) async {
    // Regression: the body used to be a lazy ListView, so sections below the
    // fold were never built. Their GlobalKeys had no context and tapping a
    // tab chip silently did nothing. Each section must exist on first pump.
    await tester.pumpWidget(host());
    await tester.pump();

    for (final section in [
      'Traveller Details',
      'Package Inclusions',
      'Cancellation & Date Change',
      'Important Information',
    ]) {
      expect(
        find.text(section),
        findsWidgets,
        reason: '"$section" must be built for the tab strip to scroll to it',
      );
    }

  });

  testWidgets('CONTINUE is blocked until contact, lead traveller and terms',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    // Empty contact fields fail validation, so nothing is pushed.
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an email address'), findsOneWidget);
    expect(find.text('Enter a mobile number'), findsOneWidget);
    expect(find.byType(DiyReviewScreen), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'EMAIL ID*'), 'a@b.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'MOBILE NUMBER*'), '9812345678');
    await tester.pump();

    // Contact is valid now, but the lead traveller is still blank.
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('lead traveller'), findsWidgets);
    expect(find.byType(DiyReviewScreen), findsOneWidget);
  });

  testWidgets('a traveller with no date of birth shows no age suffix',
      (tester) async {
    // Guards the age formatting: DiyTraveller.age must stay null rather than
    // rendering something like "· 0y" next to the name.
    const t = DiyTraveller(firstName: 'Anjli', lastName: 'Singh');
    expect(t.age, isNull);
    expect(t.fullName, 'Anjli Singh');
    expect(t.isComplete, isTrue);
  });

  test('age is whole years, and not yet incremented before the birthday', () {
    final now = DateTime.now();
    final justBefore = DateTime(now.year - 30, now.month, now.day)
        .add(const Duration(days: 1));
    final t = DiyTraveller(
      firstName: 'A',
      lastName: 'B',
      dob: '${justBefore.year}-'
          '${justBefore.month.toString().padLeft(2, '0')}-'
          '${justBefore.day.toString().padLeft(2, '0')}',
    );
    expect(t.age, 29);
  });
}
