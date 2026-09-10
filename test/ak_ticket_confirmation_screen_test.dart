// Responsiveness + null-safety checks for the redesigned
// [AkTicketConfirmationScreen] (Figma node 604:5261).
//
// These pump the screen at a spread of phone sizes with both a full booking
// response and a sparse / very-long-data one, and fail on any RenderFlex
// overflow or other build exception.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/AKRetrieveBooking/domain/entity/AKRetrieveBooking_entity.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/seat_addons_screen.dart';
import 'package:wander_nova/views/flight_ticket/presentation/screen/ak_ticket_confirmation_screen.dart';

FlightRouteSegment _leg({
  String from = 'New Delhi (DEL)',
  String to = 'Dubai (DXB)',
  String? fromCity = 'New Delhi',
  String? toCity = 'Dubai',
}) {
  return FlightRouteSegment(
    from: from,
    to: to,
    fromCity: fromCity,
    toCity: toCity,
    departureTime: '04:40 PM',
    arrivalTime: '06:40 PM',
    duration: '03 h 30 m',
    airline: 'IndiGo',
    flightNo: '6E • 464',
    price: '7414',
    departureDate: 'Wed, 26 Aug',
    stops: 0,
  );
}

AkRetrieveBookingEntity _booking({List<String> pnrs = const ['6FXV1V']}) {
  return AkRetrieveBookingEntity(
    success: true,
    pnrs: pnrs,
    status: 'Ticketed',
    trips: const [
      AkRetrieveTripEntity(
        journey: [
          AkRetrieveJourneyEntity(
            segments: [
              AkRetrieveSegmentEntity(
                crsPnr: '6FXV1V',
                flightNo: '6E464',
                ticketInfo: [
                  AkTicketInfoEntity(paxId: '1', ticketNo: '098-1234567890'),
                  AkTicketInfoEntity(paxId: '2', ticketNo: '098-1234567891'),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _host(Widget child) => MaterialApp(home: child);

const _sizes = <Size>[
  Size(320, 568), // iPhone SE (1st gen) — smallest common
  Size(360, 640), // small Android
  Size(375, 812), // design baseline
  Size(430, 932), // iPhone 15 Pro Max
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!sl.isRegistered<PreferencesManager>()) {
      sl.registerSingleton<PreferencesManager>(await PreferencesManager.create(prefs));
    }
  });

  tearDownAll(() async {
    await sl.reset();
  });

  Future<void> pumpAt(WidgetTester tester, Size size, Widget screen) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Fresh mount every call so widget State (e.g. the "View more" toggle)
    // never carries over between sizes.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(screen));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull, reason: 'build/layout threw at $size');
  }

  testWidgets('renders a full one-way booking with no overflow at every size', (tester) async {
    for (final size in _sizes) {
      await pumpAt(
        tester,
        size,
        AkTicketConfirmationScreen(
          booking: _booking(),
          route: _leg(),
          leadPassenger: const {
            'firstName': 'Anjli',
            'lastName': 'Singh',
            'email': 'anjli@example.com',
            'mobileNumber': '9876543210',
            'title': 'Ms',
          },
          travellers: const [
            {'firstName': 'Anjli', 'lastName': 'Singh', 'paxType': 'ADT', 'dateOfBirth': '14 Aug 2003', 'gender': 'Female'},
            {'firstName': 'Baby', 'lastName': 'Singh', 'paxType': 'INF', 'dateOfBirth': '01 Jan 2024', 'gender': 'Male'},
          ],
          addOns: const AddOnsSummary(total: 500, seatNumbers: ['4A'], meals: ['Veg Meal']),
          transactionId: 'pay_Nxq10P29lK3zY7',
          netAmount: 7414,
          travellerCount: 2,
          travellerNames: const ['Ms Anjli Singh', 'Mr Baby Singh'],
        ),
      );

      expect(find.text('Payment Successful!'), findsOneWidget);
      expect(find.text('Your booking is confirmed.'), findsOneWidget);
      expect(find.textContaining('6FXV1V'), findsWidgets);
      expect(find.text('Anjli Singh'), findsOneWidget);
      expect(find.text('PNR:'), findsOneWidget);
    }
  });

  testWidgets('round trip renders two flight cards', (tester) async {
    await pumpAt(
      tester,
      const Size(375, 812),
      AkTicketConfirmationScreen(
        booking: _booking(pnrs: const ['6FXV1V', 'A1B2C3']),
        route: _leg(),
        additionalLegs: [
          _leg(from: 'Dubai (DXB)', to: 'New Delhi (DEL)', fromCity: 'Dubai', toCity: 'New Delhi'),
        ],
        leadPassenger: const {'firstName': 'Anjli', 'lastName': 'Singh'},
        travellers: const [
          {'firstName': 'Anjli', 'lastName': 'Singh', 'paxType': 'ADT'},
        ],
        netAmount: 15000,
        travellerCount: 1,
      ),
    );

    expect(find.text('Dubai'), findsWidgets);
    expect(find.text('New Delhi'), findsWidgets);
  });

  testWidgets('handles missing / null / very long data without overflow', (tester) async {
    final longName = 'Maximiliana Wilhelmina Aleksandrovna Featherstonehaugh-Cholmondeley';
    for (final size in _sizes) {
      await pumpAt(
        tester,
        size,
        AkTicketConfirmationScreen(
          booking: const AkRetrieveBookingEntity(success: true, pnrs: [], status: '', trips: []),
          route: _leg(
            from: 'X',
            to: 'Y',
            fromCity: 'A Very Long Origin City Name That Should Ellipsize Gracefully',
            toCity: 'An Equally Long Destination City Name For Testing Purposes',
          ),
          leadPassenger: const {},
          travellers: [
            {'firstName': longName, 'lastName': 'Of-The-Long-Surname-Clan', 'paxType': 'ADT'},
            {'firstName': 'Kid', 'lastName': 'Two', 'paxType': 'CHD', 'dateOfBirth': '2019-05-01'},
            {'firstName': 'Third', 'lastName': 'Passenger', 'paxType': 'ADT'},
          ],
          netAmount: 0,
          travellerCount: 3,
        ),
      );

      expect(find.text('TRAVELLER'), findsOneWidget, reason: 'traveller section missing at $size');

      // "View more" appears for 3+ travellers; expanding it must not overflow.
      final viewMore = find.text('View more');
      expect(viewMore, findsOneWidget, reason: 'View more missing at $size');
      await tester.scrollUntilVisible(viewMore, 120,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(viewMore);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'expanding travellers threw at $size');
      expect(find.text('View less'), findsOneWidget);
    }
  });
}
