// Checks for the redesigned Transport results card + full-screen filter.
// The card must show only what the API result contains (no hardcoded
// "Free cancellation" / "No hidden fees" claims).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/TPoll_Search/domain/entities/TPollSearchEntity.dart';
import 'package:wander_nova/views/TPoll_Search/domain/repository/TPoll_Search_repository.dart';
import 'package:wander_nova/views/TPoll_Search/domain/usecase/TPoll_search_usecase.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/bloc/TPoll_SearchBloc.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/screen/TPollSearch_Screen.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/Widget/TPoll_VehicleCard.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/screen/TPoll_FilterScreen.dart';

SearchResultEntity _result({
  String id = 'r1',
  String type = 'Sedan',
  String price = '9183',
  int pax = 4,
  int bags = 2,
  num? rating = 4.0,
  int? ratingCount = 307,
  String? make = 'Maruti',
  String? model = 'Suzuki',
  int? freeCancel = 24,
  bool tolls = false,
  List<AmenityEntity>? amenities,
}) {
  return SearchResultEntity(
    resultId: id,
    vehicleId: 'v$id',
    providerName: 'KiwiTaxi',
    vehicleType: type,
    vehicleName: 'Standard',
    totalPriceAmount: price,
    totalPriceCurrency: 'INR',
    bookable: true,
    vehicleImageUrl: '',
    maxPassengers: pax,
    maxBags: bags,
    amenities: amenities ??
        const [
          AmenityEntity(
            key: 'sms_notifications',
            name: 'SMS notification',
            description: '',
            included: false,
            chargeable: true,
            price: PriceInfoEntity(
                value: '191', display: '191', compact: '191', currency: 'INR'),
          ),
          AmenityEntity(
            key: 'air_conditioning',
            name: 'Air conditioning',
            description: '',
            included: true,
            chargeable: false,
          ),
        ],
    rating: rating,
    ratingCount: ratingCount,
    vehicleMake: make,
    vehicleModel: model,
    tollsIncluded: tolls,
    freeCancellationHours: freeCancel,
  );
}

class _FakeRepo implements TpollSearchRepository {
  final List<SearchResultEntity> results;
  _FakeRepo(this.results);

  @override
  Future<DataState<TpollSearchEntity>> pollSearchResults(String searchId) async {
    return DataSuccess(TpollSearchEntity(
      success: true,
      search: SearchDataEntity(
        numPassengers: 2,
        pickupDatetime: '2026-09-16T10:00:00',
        searchId: searchId,
        results: results,
        startLocation: const LocationInfoEntity(
            fullAddress: '', city: 'New Delhi', iataCode: 'DEL'),
        endLocation: const LocationInfoEntity(
            fullAddress: '', city: 'Jaipur', iataCode: ''),
        currencyInfo: const CurrencyInfoEntity(code: 'INR', prefixSymbol: '₹'),
        expiresIn: 600,
        moreComing: false,
      ),
    ));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Tests default to the Ahem font (every glyph as wide as it is tall), which
    // makes text look ~2x wider than on a device. Load the SDK's real Roboto so
    // overflow checks reflect actual widths. Skipped silently if not found.
    final fonts = FontLoader('Roboto');
    for (final name in ['regular', 'medium', 'bold']) {
      final f = File('C:/flutter/src/flutter/bin/cache/artifacts/material_fonts/roboto-$name.ttf');
      if (f.existsSync()) {
        fonts.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await fonts.load();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!sl.isRegistered<PreferencesManager>()) {
      sl.registerSingleton<PreferencesManager>(
          await PreferencesManager.create(prefs));
    }
  });
  tearDownAll(() async => sl.reset());

  Future<void> pump(WidgetTester tester, Widget child, {Size? size}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size ?? const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: child,
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget card(SearchResultEntity r) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TpollVehicleCard(
            searchId: 's',
            result: r,
            currencySymbol: '₹',
            currencyCode: 'INR',
            onTap: () {},
            formattedPrice: '₹9,183',
            formattedAmenityPrices: const {'sms_notifications': '₹191'},
          ),
        ),
      );

  group('TpollVehicleCard', () {
    for (final size in const [Size(320, 640), Size(390, 844), Size(430, 932)]) {
      testWidgets('renders API data without overflow at $size', (tester) async {
        await pump(tester, card(_result(tolls: true)), size: size);

        expect(tester.takeException(), isNull);
        expect(find.text('Maruti Suzuki'), findsOneWidget);
        expect(find.text('Sedan'), findsOneWidget); // image label
        expect(find.text('Free cancellation up to 24 hrs'), findsOneWidget);
        expect(find.text('Tolls included'), findsOneWidget);
        expect(find.text('SMS notification ₹191'), findsOneWidget);
        expect(find.text('AC'), findsOneWidget);
        expect(find.text('4'), findsOneWidget); // pax
        expect(find.text('2'), findsOneWidget); // bags
        expect(find.text('4.0'), findsOneWidget);
        expect(find.text('(307)'), findsOneWidget);
        expect(find.textContaining('₹9,183'), findsOneWidget);
        expect(find.textContaining('/trip'), findsOneWidget);
      });
    }

    testWidgets('omits claims the API did not return', (tester) async {
      await pump(
        tester,
        card(_result(
          rating: null,
          ratingCount: null,
          make: null,
          model: null,
          freeCancel: null,
          amenities: const [],
        )),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Free cancellation'), findsNothing);
      expect(find.textContaining('hidden fees'), findsNothing);
      expect(find.textContaining('SMS'), findsNothing);
      expect(find.text('AC'), findsNothing);
      expect(find.text('(307)'), findsNothing);
      // falls back to the API's vehicle name when make/model are absent
      expect(find.text('Standard'), findsOneWidget);
    });
  });

  group('TpollFilterScreen', () {
    final results = [
      _result(id: 'a', type: 'Sedan', price: '26655', pax: 4),
      _result(id: 'b', type: 'SUV', price: '180000', pax: 6),
    ];

    testWidgets('shows only options derived from the results', (tester) async {
      await pump(
        tester,
        TpollFilterScreen(results: results, currentFilters: const TpollFilterState()),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sort By'), findsOneWidget);
      expect(find.text('Popularity'), findsOneWidget);
      expect(find.text('Price Range'), findsOneWidget);
      expect(find.text('₹26,655'), findsOneWidget); // min label
      expect(find.text('₹180,000'), findsWidgets); // max label + bubble
      expect(find.text('4+ pax'), findsOneWidget);
      expect(find.text('6+ pax'), findsOneWidget);
      expect(find.text('All Vehicles'), findsOneWidget);
      expect(find.text('Sedan'), findsOneWidget);
      expect(find.text('SUV'), findsOneWidget);
      expect(find.text('APPLY FILTER'), findsOneWidget);
    });

    testWidgets('Apply pops the chosen state; Clear resets it', (tester) async {
      TpollFilterState? applied;
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => applied = await Navigator.push<TpollFilterState>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TpollFilterScreen(
                      results: results,
                      currentFilters: const TpollFilterState(),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUV'));
      await tester.tap(find.text('Price: Low to High'));
      await tester.tap(find.text('4+ pax'));
      await tester.pump();
      await tester.tap(find.text('APPLY FILTER'));
      await tester.pumpAndSettle();

      expect(applied, isNotNull);
      expect(applied!.selectedVehicleTypes, {'SUV'});
      expect(applied!.sortBy, TpollFilterState.sortPriceLow);
      expect(applied!.minPassengers, 4);
      expect(applied!.maxPrice, isNull); // slider untouched = no cap

      // reopen with those filters, then Clear → defaults
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pump();
      await tester.tap(find.text('APPLY FILTER'));
      await tester.pumpAndSettle();
      expect(applied!.selectedVehicleTypes, isEmpty);
      expect(applied!.sortBy, TpollFilterState.sortPopular);
      expect(applied!.minPassengers, isNull);
    });
  });

  group('TpollSearchResultsPage', () {
    final cheap = _result(id: 'c', type: 'Sedan', price: '5000', make: 'Cheapo', model: null, rating: 3.0, ratingCount: 900);
    final dear = _result(id: 'd', type: 'SUV', price: '20000', make: 'Luxo', model: null, rating: 4.9, ratingCount: 10);

    Future<void> openPage(WidgetTester tester) async {
      sl.registerFactory<TpollSearchBloc>(() => TpollSearchBloc(
          tpollSearchUseCase: TpollSearchUseCase(_FakeRepo([cheap, dear]))));
      addTearDown(() => sl.unregister<TpollSearchBloc>());
      await pump(
        tester,
        TpollSearchResultsPage(
          searchId: 's',
          startAddress: 'DEL',
          endAddress: 'JAI',
          pickupDate: DateTime(2026, 9, 16),
          numPassengers: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    Finder inCard(String text) =>
        find.descendant(of: find.byType(TpollVehicleCard), matching: find.text(text));
    double top(WidgetTester tester, String text) =>
        tester.getTopLeft(inCard(text)).dy;

    testWidgets('header shows API route + pickup time; chips include All', (tester) async {
      await openPage(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('New Delhi to Jaipur'), findsOneWidget);
      expect(find.text('16 Sep, 10:00 AM'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Sedan'), findsWidgets);
      expect(find.text('Cheapo'), findsWidgets);
      expect(find.text('Luxo'), findsWidgets);

      // Selecting a chip narrows the list; All brings everything back.
      await tester.tap(find.text('SUV').first);
      await tester.pump();
      expect(inCard('Cheapo'), findsNothing);
      expect(inCard('Luxo'), findsOneWidget);
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(inCard('Cheapo'), findsOneWidget);
    });

    testWidgets('Sort sheet: 4 options, applies on DONE, RESET returns to Popularity', (tester) async {
      await openPage(tester);
      // Popularity (most reviews first): Cheapo (900) above Luxo (10).
      expect(top(tester, 'Cheapo') < top(tester, 'Luxo'), isTrue);

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsOneWidget);
      for (final t in ['Popularity', 'Price (Low to High)', 'Price (High to Low)', 'Ratings (Highest)', 'RESET', 'DONE']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.text('Ratings (Highest)'));
      await tester.pump();
      // not applied until DONE
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(top(tester, 'Luxo') < top(tester, 'Cheapo'), isTrue); // 4.9 before 3.0

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RESET'));
      await tester.pump();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(top(tester, 'Cheapo') < top(tester, 'Luxo'), isTrue);
    });

    testWidgets('edit icon opens the top drawer (no hero) and × closes it', (tester) async {
      await openPage(tester);
      final edit = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName.endsWith('edit.png'));
      await tester.tap(edit);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Edit Your Search'), findsOneWidget);
      expect(find.text('Outstation'), findsOneWidget);
      expect(find.text('Airport'), findsOneWidget);
      expect(find.text('One Way'), findsOneWidget);
      expect(find.text('Round Trip'), findsOneWidget);
      expect(find.text('MODIFY SEARCH'), findsOneWidget);
      expect(find.textContaining('Traveller'), findsWidgets);
      final hero = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName.contains('TransHeroImage'));
      expect(hero, findsNothing);

      // × sits below the drawer, horizontally centred.
      final close = find.byIcon(Icons.close_rounded);
      expect(close, findsOneWidget);
      expect((tester.getCenter(close).dx - 195).abs() < 2, isTrue);
      expect(tester.getTopLeft(close).dy > tester.getBottomLeft(find.text('MODIFY SEARCH')).dy, isTrue);

      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Edit Your Search'), findsNothing);
    });
  });
}
