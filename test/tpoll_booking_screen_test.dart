// Checks for the redesigned Transport "Review Your Ride" screen: every value
// comes from the API result, the traveller card edits inline, coupons work like
// the flight screen, and the info icon opens the shared Fare Breakup drawer.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/MainApi/domain/entities/general_setting_entity.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_faq_list_usecase.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_general_setting_usecase.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_promo_codes_usecase.dart';
import 'package:wander_nova/views/MainApi/domain/usecase/get_section_heros_usecase.dart';
import 'package:wander_nova/views/MainApi/presentation/bloc/general_setting_bloc.dart';
import 'package:wander_nova/views/TPoll_Search/domain/entities/TPollSearchEntity.dart';
import 'package:wander_nova/views/TResevation/presentation/screen/payment_screen.dart';
import 'package:wander_nova/views/TResult/presentation/screen/TPoll_Booking.dart';

class _PromoUsecase extends Fake implements GetPromoCodesUsecase {
  final List<PromoCodeEntity> promos;
  _PromoUsecase(this.promos);

  @override
  Future<DataState<List<PromoCodeEntity>>> call({String? domain}) async =>
      DataSuccess(promos);
}

class _U1 extends Fake implements GetGeneralSettingsUsecase {}

class _U2 extends Fake implements GetSectionHeroesUsecase {}

class _U3 extends Fake implements GetFaqListUsecase {}

const _sms = AmenityEntity(
  key: 'sms_notifications',
  name: 'SMS notifications',
  description: 'Receive an SMS when the driver has been assigned.',
  included: false,
  chargeable: true,
  price: PriceInfoEntity(value: '2', display: '2', compact: '2', currency: 'USD'),
);

SearchResultEntity _result({
  String make = 'Suzuki',
  String? model = 'Dzire',
  int? wait = 60,
  String? waitAmt = '1.2',
  List<AmenityEntity>? amenities,
}) =>
    SearchResultEntity(
      resultId: 'r1',
      vehicleId: 'v1',
      providerName: 'KiwiTaxi',
      vehicleType: 'Sedan',
      vehicleName: 'Standard',
      totalPriceAmount: '40',
      totalPriceCurrency: 'USD',
      bookable: true,
      vehicleImageUrl: '',
      maxPassengers: 2,
      maxBags: 3,
      amenities: amenities ??
          const [
            AmenityEntity(
                key: 'meet_and_greet',
                name: 'Meet & Greet',
                description: '',
                included: true,
                chargeable: false),
            AmenityEntity(
                key: 'air_conditioning',
                name: 'Air-conditioning',
                description: '',
                included: true,
                chargeable: false),
            _sms,
          ],
      vehicleMake: make,
      vehicleModel: model,
      travelTimeMinutes: 240,
      waitMinutesIncluded: wait,
      waitingMinuteAmount: waitAmt,
      waitingMinuteCurrency: 'USD',
    );

SearchDataEntity _searchData() => const SearchDataEntity(
      numPassengers: 2,
      pickupDatetime: '2026-09-17T10:00:00',
      searchId: 's1',
      results: [],
      startLocation:
          LocationInfoEntity(fullAddress: 'New Delhi Abc School', city: 'New Delhi', iataCode: ''),
      endLocation: LocationInfoEntity(fullAddress: '', city: 'Jaipur', iataCode: ''),
      currencyInfo: CurrencyInfoEntity(code: 'USD', prefixSymbol: '\$'),
      expiresIn: 600,
      moreComing: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fonts = FontLoader('Roboto');
    for (final name in ['regular', 'medium', 'bold']) {
      final f = File(
          'C:/flutter/src/flutter/bin/cache/artifacts/material_fonts/roboto-$name.ttf');
      if (f.existsSync()) {
        fonts.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await fonts.load();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_data': jsonEncode({
        'id': 7,
        'email': 'anjli@example.com',
        'firstname': 'Anjli',
        'lastname': 'Singh',
      }),
      'preferred_currency': 'INR',
    });
    final prefs = await SharedPreferences.getInstance();
    if (!sl.isRegistered<PreferencesManager>()) {
      sl.registerSingleton<PreferencesManager>(await PreferencesManager.create(prefs));
    }
  });
  tearDownAll(() async => sl.reset());

  Future<void> pump(WidgetTester tester, SearchResultEntity result,
      {List<PromoCodeEntity> promos = const []}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = GeneralSettingsBloc(
      getGeneralSettingsUsecase: _U1(),
      getSectionHeroesUsecase: _U2(),
      getFaqListUsecase: _U3(),
      getPromoCodesUsecase: _PromoUsecase(promos),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: BlocProvider<GeneralSettingsBloc>.value(
        value: bloc,
        child: TPollBookingScreen(
          result: result,
          searchData: _searchData(),
          startAddress: 'DEL',
          endAddress: 'JAI',
          pickupDate: DateTime(2026, 9, 17),
          searchId: 's1',
          resultId: 'r1',
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows only API-backed details, no overflow', (tester) async {
    await pump(tester, _result());
    expect(tester.takeException(), isNull);

    expect(find.text('Review Your Ride'), findsOneWidget);
    expect(find.text('New Delhi Abc School to Jaipur'), findsOneWidget);
    expect(find.text('17 Sep, 10:00AM'), findsOneWidget);
    expect(find.text('4Hrs'), findsOneWidget);
    expect(find.text('Suzuki Dzire'), findsWidgets);
    expect(find.text('Sedan'), findsOneWidget);

    // info tiles
    expect(find.text('AIR-CONDITIONING'), findsOneWidget);
    expect(find.text('2 Seats'), findsOneWidget);

    // vehicle details
    expect(find.text('Vehicle Details'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('3 Bags'), findsOneWidget);
    expect(find.text('60 min included'), findsOneWidget);
    expect(find.textContaining('then USD 1.2/min'), findsOneWidget);

    // amenities: included rows + chargeable box with API description
    expect(find.text('Meet & Greet'), findsOneWidget);
    expect(find.text('Air-conditioning'), findsOneWidget);
    expect(find.textContaining('SMS notifications'), findsOneWidget);
    expect(find.text('Receive an SMS when the driver has been assigned.'), findsOneWidget);

    // nothing hardcoded from the old screen
    expect(find.text('Special Requests'), findsNothing);
    expect(find.textContaining('Final payable'), findsNothing);
    expect(find.text('PAY NOW'), findsOneWidget);
  });

  testWidgets('hides tiles the API did not return', (tester) async {
    await pump(
      tester,
      _result(make: '', model: null, wait: null, waitAmt: null, amenities: const []),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('AIR-CONDITIONING'), findsNothing);
    expect(find.text('MAKE / MODEL'), findsNothing);
    expect(find.text('WAITING TIME'), findsNothing);
    expect(find.text('Amenities'), findsNothing);
  });

  testWidgets('traveller card: prefilled summary → edit form → save', (tester) async {
    await pump(tester, _result());
    // No phone on the account → form is open with the account name prefilled.
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Email ID (optional)'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);

    // Save with no phone → stays open.
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Gender'), findsOneWidget);

    // TextFields in order: first name, last name, phone, email, …
    await tester.enterText(find.byType(TextField).at(2), '9876543212');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Gender'), findsNothing);
    expect(find.text('Anjli Singh'), findsOneWidget);
    expect(find.text('+91 9876543212 | anjli@example.com'), findsOneWidget);
  });

  testWidgets('coupons: apply, discount in fare breakup, remove', (tester) async {
    await pump(tester, _result(), promos: const [
      PromoCodeEntity(
          code: 'WNTAPPLY',
          category: 'transport_booking',
          discountType: 'fixed',
          discountValue: '150',
          description: ''),
      PromoCodeEntity(
          code: 'FLIGHTONLY',
          category: 'flight_booking',
          discountType: 'percent',
          discountValue: '10',
          description: ''),
    ]);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Coupon & Offers'), findsOneWidget);
    expect(find.text('Have a Coupon Code?'), findsOneWidget);
    expect(find.text('WNTAPPLY'), findsOneWidget);
    expect(find.text('FLIGHTONLY'), findsNothing); // wrong category is filtered out

    await tester.ensureVisible(find.text('Apply').last);
    await tester.tap(find.text('Apply').last);
    await tester.pump(const Duration(milliseconds: 300));
    // celebration dialog → dismiss
    await tester.tap(find.text('Great!'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Remove'), findsOneWidget);
    expect(find.textContaining('instant discount applied'), findsOneWidget);

    // fare breakup opens from the bottom bar's info tap
    await tester.tap(find.byIcon(Icons.info));
    await tester.pumpAndSettle();
    expect(find.text('Fare Breakup'), findsOneWidget);
    expect(find.text('Base Fare'), findsOneWidget);
    expect(find.text('Discounts'), findsOneWidget);
    expect(find.text('WNTAPPLY'), findsWidgets);
    expect(find.text('Total Amount'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pump();
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('PAY NOW blocks until traveller + flight details are valid', (tester) async {
    await pump(tester, _result());
    await tester.tap(find.text('PAY NOW'));
    await tester.pump(const Duration(milliseconds: 400));
    // still on this screen, phone error shown (form remains open)
    expect(find.text('Review Your Ride'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
  });

  testWidgets('PAY NOW hands add-ons, coupon and INR amounts to the payment screen', (tester) async {
    const childSeat = AmenityEntity(
      key: 'child_seat',
      name: 'Child seat',
      description: 'For ages 1-5.',
      included: false,
      chargeable: true,
      price: PriceInfoEntity(value: '4', display: '4', compact: '4', currency: 'USD'),
    );
    const internalSms = AmenityEntity(
      key: 'sms_notifications',
      name: 'SMS notifications',
      description: '',
      included: false,
      chargeable: true,
      internal: true,
      price: PriceInfoEntity(value: '2', display: '2', compact: '2', currency: 'USD'),
    );
    await pump(
      tester,
      _result(amenities: const [childSeat, internalSms]),
      promos: const [
        PromoCodeEntity(
            code: 'TENOFF',
            category: 'transport_booking',
            discountType: 'percent',
            discountValue: '10',
            description: ''),
      ],
    );
    await tester.pump(const Duration(milliseconds: 200));

    // traveller: add phone, save
    await tester.enterText(find.byType(TextField).at(2), '9876543212');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();

    // flight details (fields are now: flight number, airline, promo)
    await tester.enterText(find.byType(TextField).at(0), 'ai101');
    await tester.enterText(find.byType(TextField).at(1), 'ai');

    // tick both add-ons
    await tester.ensureVisible(find.textContaining('Child seat'));
    await tester.tap(find.textContaining('Child seat'));
    await tester.pump();
    await tester.ensureVisible(find.textContaining('SMS notifications'));
    await tester.tap(find.textContaining('SMS notifications'));
    await tester.pump();

    // apply the 10% coupon from its card
    await tester.ensureVisible(find.text('TENOFF'));
    await tester.tap(find.text('Apply').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Great!'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.text('PAY NOW'));
    await tester.pump(const Duration(milliseconds: 500));

    final pay = tester.widget<PaymentScreen>(find.byType(PaymentScreen, skipOffstage: false));
    // No exchange rates are cached in tests, so amounts convert 1:1.
    expect(pay.optionalAmenityKeys, ['child_seat']); // internal SMS excluded
    expect(pay.baseFare, 40);
    expect(pay.addOnsAmount, 6); // child seat 4 + sms 2 (both are charged)
    expect(pay.discountAmount, closeTo(4.6, 0.001)); // 10% of 46
    expect(pay.totalAmount, closeTo(41.4, 0.001));
    expect(pay.couponCode, 'TENOFF');
    expect(pay.passengers, 2); // from the search, not hardcoded
    expect(pay.passengerPhone, '+919876543212');
    expect(pay.flightNumber, 'AI101');
    expect(pay.airline, 'AI');

    // Let the payment screen's own timers finish before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 60));
  });
}
