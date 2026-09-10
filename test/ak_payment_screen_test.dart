// Smoke + layout checks for the redesigned AkFlightPaymentScreen:
// separate option cards, one-tap (no "select a payment method" button),
// highlight tags, and the top-anchored fare drawer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/flight_payment/presentation/screen/ak_payment_screen.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';

FlightRouteSegment _route() => FlightRouteSegment(
      from: 'New Delhi (DEL)',
      to: 'Dubai (DXB)',
      fromCity: 'New Delhi',
      toCity: 'Dubai',
      departureTime: '04:40 PM',
      arrivalTime: '06:40 PM',
      duration: '03 h 30 m',
      airline: 'IndiGo',
      flightNo: '6E • 464',
      price: '6823',
      sessionId: 'sess_test_123',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // razorpay_flutter opens a MethodChannel in the screen's initState; stub it
  // so the constructor doesn't throw under the test binding.
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('razorpay_flutter'),
      (call) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!sl.isRegistered<PreferencesManager>()) {
      sl.registerSingleton<PreferencesManager>(await PreferencesManager.create(prefs));
    }
  });

  tearDownAll(() async => sl.reset());

  Future<void> pump(WidgetTester tester, [Size size = const Size(375, 812)]) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: AkFlightPaymentScreen(
        route: _route(),
        leadPassenger: const {'firstName': 'Anjli', 'lastName': 'Singh'},
        netAmount: 6823,
        travellerCount: 1,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    // Leave the screen so its periodic hold-timer is cancelled in dispose().
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  testWidgets('shows the grouped option cards, promo strip and no pay button',
      (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);

    // Working methods kept.
    expect(find.text('My Wallet'), findsOneWidget);
    expect(find.text('Razorpay'), findsOneWidget);
    // GooglePay + UPI, plus the promo strip above their shared card.
    expect(find.text('GooglePay'), findsOneWidget);
    expect(find.text('UPI Options'), findsOneWidget);
    expect(find.text('Get extra discount on UPI of Rs 32'), findsOneWidget);
    // Other options: Credit standalone, the rest grouped, with the NB tag.
    expect(find.text('Credit & Debit Cards'), findsOneWidget);
    expect(find.text('Net Banking'), findsOneWidget);
    expect(find.text('Pay Later'), findsOneWidget);
    expect(find.text('Gift Cards & e-Wallets'), findsOneWidget);
    expect(find.text('Fingerprint/Face ID'), findsOneWidget);
    // No dividers inside the grouped cards.
    expect(find.byType(Divider), findsOneWidget); // only the header rule
    // The old bottom button is gone.
    expect(find.text('SELECT A PAYMENT METHOD'), findsNothing);
    expect(find.textContaining('PAY ₹'), findsNothing);
  });

  testWidgets('tapping Total Due opens the top fare drawer with flight + pax',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Total Due').first);
    await tester.pumpAndSettle();

    // Breakup rows + trip badge + flight card + passenger card, in the drawer.
    expect(find.text('Fare'), findsOneWidget);
    expect(find.text('ONE WAY'), findsOneWidget);
    expect(find.text('New Delhi → Dubai (Non-stop)'), findsOneWidget);
    expect(find.text('ANJLI SINGH'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Close button floats centred below the drawer.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Fare'), findsNothing);
  });

  testWidgets('static "other" cards do not select on tap', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Credit & Debit Cards'));
    await tester.pump(const Duration(milliseconds: 200));

    // No selection highlight / check icon appeared, no processing spinner.
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
