// Smoke + functional checks for the redesigned FlightFilterScreen
// (Figma "Flight Filter own way", node 402:1282).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/filter_screen.dart';

FlightFilterScreen _screen(void Function(FlightFilterResult) onApply) {
  return FlightFilterScreen(
    minPrice: 5000,
    maxPrice: 40000,
    currentPriceRange: const RangeValues(5000, 40000),
    currentSelectedAirlines: const {'IndiGo', 'Emirates'},
    currentSelectedDepartureTimes: const {},
    currentSelectedArrivalTimes: const {},
    currentRefundable: false,
    currentNonRefundable: false,
    airlineCounts: const {'IndiGo': 12, 'Emirates': 4},
    airlineMinPrices: const {'IndiGo': 6100, 'Emirates': 22000},
    airlineCodes: const {'IndiGo': '6E', 'Emirates': 'EK'},
    onApply: onApply,
    originCityName: 'New Delhi',
    destinationCityName: 'Dubai',
    stopMinPrices: const {0: 30444, 1: 26444, 2: 41444},
    maxStopsAvailable: 2,
    currentSelectedStops: const {},
    minDuration: 210,
    maxDuration: 1710,
    currentDurationRange: const RangeValues(210, 1710),
    departureAirports: const {'DEL': 'Indira Gandhi International'},
    arrivalAirports: const {'DXB': 'Dubai Intl'},
    departureTimePrices: const {'6-12': 26655, '12-18': 29190, '18-24': 31000},
    arrivalTimePrices: const {'12-18': 29190},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!sl.isRegistered<PreferencesManager>()) {
      sl.registerSingleton<PreferencesManager>(await PreferencesManager.create(prefs));
    }
  });
  tearDownAll(() async => sl.reset());

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Scrolls the filter list until [f] is built, then brings it fully on
  /// screen so it can be tapped reliably.
  Future<void> see(WidgetTester tester, Finder f) async {
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -280));
      await tester.pump();
    }
    expect(f, findsWidgets);
    await tester.ensureVisible(f.first);
    await tester.pump();
  }

  testWidgets('renders the Figma sections; no Fare Type; APPLY FILTER',
      (tester) async {
    await pump(tester, _screen((_) {}));
    expect(tester.takeException(), isNull);

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Stop From New Delhi'), findsOneWidget);

    await see(tester, find.text('Departure From New Delhi'));
    await see(tester, find.text('6AM-12Noon'));
    await see(tester, find.text('Arrival at Dubai'));
    await see(tester, find.text('Other popular filter'));
    await see(tester, find.text('Refundable Fares'));

    expect(find.text('APPLY FILTER'), findsOneWidget);
    expect(find.text('DONE'), findsNothing);
    expect(find.text('Fare Type'), findsNothing);
    expect(find.text('Non-refundable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggling an airline + APPLY FILTER returns an updated result',
      (tester) async {
    FlightFilterResult? applied;
    await pump(tester, _screen((r) => applied = r));

    await see(tester, find.text('Emirates'));
    await tester.tap(find.text('Emirates'));
    await tester.pump();

    await see(tester, find.text('APPLY FILTER'));
    await tester.tap(find.text('APPLY FILTER'));
    await tester.pump();

    expect(applied, isNotNull);
    expect(applied!.selectedAirlines.contains('Emirates'), isFalse);
    expect(applied!.selectedAirlines.contains('IndiGo'), isTrue);
  });

  testWidgets('time windows respect price availability', (tester) async {
    FlightFilterResult? applied;
    await pump(tester, _screen((r) => applied = r));

    await see(tester, find.text('Departure From New Delhi'));
    // '0-6' ("Before 6AM") has no price → disabled; '12-18' has one → works.
    await tester.tap(find.text('Before 6AM').first);
    await tester.pump();
    await tester.tap(find.text('12 Noon-6PM').first);
    await tester.pump();

    await see(tester, find.text('APPLY FILTER'));
    await tester.tap(find.text('APPLY FILTER'));
    await tester.pump();

    expect(applied!.selectedDepartureTimes.contains('0-6'), isFalse);
    expect(applied!.selectedDepartureTimes.contains('12-18'), isTrue);
  });
}
