// HotelCollectionsSection and HotelLuxePackagesSection on the plain Hotel
// home screen — redesigned to reuse real ExclusiveDeals data (already
// fetched for DealsSection) instead of static/hardcoded hotel lists, and to
// render nothing (never a fake placeholder) until there's real data to show.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/hotelUIwidget/hotel_collections_section.dart';
import 'package:wander_nova/hotelUIwidget/hotel_luxe_packages_section.dart';
import 'package:wander_nova/views/ExclusiveDeals/domain/entities/exclusive_deal_entity.dart';
import 'package:wander_nova/views/ExclusiveDeals/domain/repository/exclusive_deals_repository.dart';
import 'package:wander_nova/views/ExclusiveDeals/domain/usecase/get_exclusive_deals_usecase.dart';
import 'package:wander_nova/views/ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import 'package:wander_nova/views/ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';

class _FakeRepository extends Fake implements ExclusiveDealsRepository {
  final List<ExclusiveDealEntity> deals;
  _FakeRepository(this.deals);

  @override
  Future<DataState<List<ExclusiveDealEntity>>> getExclusiveDeals({String? domain}) async {
    return DataSuccess(deals);
  }
}

ExclusiveDealEntity _deal({
  required int id,
  required String title,
  String imageUrl = 'https://example.com/hotel.jpg',
  String category = 'hotel',
  String ownerTab = 'hotel',
  String discountText = '',
}) {
  final now = DateTime(2026, 1, 1);
  return ExclusiveDealEntity(
    id: id,
    reseller: 1,
    ownerTab: ownerTab,
    category: category,
    brand: 'Brand $id',
    title: title,
    imageUrl: imageUrl,
    description: '',
    shortDescription: '',
    discountText: discountText,
    couponCode: '',
    validUpto: '',
    sectorType: '',
    linkUrl: null,
    isHotDeal: true,
    country: 'IN',
    isFixedDeparture: false,
    isCoachTour: false,
    order: id,
    isActive: true,
    created: now,
    updated: now,
  );
}

Future<void> _pumpWithDeals(
  WidgetTester tester,
  Widget child,
  List<ExclusiveDealEntity> deals,
) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final bloc = ExclusiveDealsBloc(getExclusiveDealsUseCase: GetExclusiveDealsUseCase(_FakeRepository(deals)));
  bloc.add(const LoadExclusiveDeals());
  await tester.pumpWidget(MaterialApp(
    home: BlocProvider.value(
      value: bloc,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ));
  await tester.pump();
  await tester.pump();
  addTearDown(bloc.close);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HotelCollectionsSection', () {
    testWidgets('renders nothing with fewer than 4 real hotel deals', (tester) async {
      await _pumpWithDeals(tester, const HotelCollectionsSection(), [
        _deal(id: 1, title: 'Hotel One'),
        _deal(id: 2, title: 'Hotel Two'),
        _deal(id: 3, title: 'Hotel Three'),
      ]);
      expect(find.text('Collections'), findsNothing);
      expect(find.text('Hotel One'), findsNothing);
    });

    testWidgets('renders the real mosaic once 4+ hotel deals are loaded', (tester) async {
      await _pumpWithDeals(tester, const HotelCollectionsSection(), [
        _deal(id: 1, title: 'Hotel One'),
        _deal(id: 2, title: 'Hotel Two'),
        _deal(id: 3, title: 'Hotel Three'),
        _deal(id: 4, title: 'Hotel Four'),
        // Non-hotel deal must never fill a tile.
        _deal(id: 5, title: 'Flight Deal', category: 'flight', ownerTab: 'flight'),
      ]);
      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Hotel One'), findsOneWidget);
      expect(find.text('Hotel Four'), findsOneWidget);
      expect(find.text('Flight Deal'), findsNothing);
    });
  });

  group('HotelLuxePackagesSection', () {
    testWidgets('renders nothing when there are no real hotel deals', (tester) async {
      await _pumpWithDeals(tester, const HotelLuxePackagesSection(), [
        _deal(id: 1, title: 'Flight Deal', category: 'flight', ownerTab: 'flight'),
      ]);
      expect(find.text('Luxe - Best Packages'), findsNothing);
    });

    testWidgets('renders real deal cards, never a fabricated price/rating', (tester) async {
      await _pumpWithDeals(tester, const HotelLuxePackagesSection(), [
        _deal(id: 1, title: 'Beach Resort', discountText: '20% off'),
      ]);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Luxe - Best Packages'), findsOneWidget);
      expect(find.text('Beach Resort'), findsOneWidget);
      expect(find.text('20% off'), findsOneWidget);
      // No made-up "/night" price line for a deal with no price field.
      expect(find.text(' /night'), findsNothing);
    });
  });
}
