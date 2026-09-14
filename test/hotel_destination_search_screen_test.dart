// Checks for the new full-screen hotel pickers wired into hotel_search_card.dart:
//  - HotelDestinationSearchScreen (Figma node 640:9567)
//  - HotelCalendarScreen (Check-in / Check-out wording)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/domain/entity/AKHotelAutosuggest_entity.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/domain/repository/AKHotelAutosuggest_repository.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/domain/usecase/AKHotelAutosuggest_usecase.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/presentation/bloc/AKHotelAutosuggest_bloc.dart';
import 'package:wander_nova/views/AKHotelAutosuggest/presentation/screen/hotel_destination_search_screen.dart';
import 'package:wander_nova/views/Hotel/screen/hotel_calendar_screen.dart';

class _FakeRepo implements AkHotelAutosuggestRepository {
  @override
  Future<DataState<AkHotelAutosuggestEntity>> autosuggest(
      AkHotelAutosuggestRequestEntity request) async {
    return DataSuccess(AkHotelAutosuggestEntity(
      success: true,
      locations: const [
        AkHotelLocationEntity(
          id: 'CTGOA',
          name: 'Goa',
          fullName: 'Goa, India',
          type: 'city',
          country: 'IN',
        ),
        AkHotelLocationEntity(
          id: 'H12345',
          name: 'Taj Exotica',
          fullName: 'Taj Exotica, Benaulim, Goa',
          type: 'hotel',
          referenceId: 'HTL-1',
        ),
      ],
    ));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (!sl.isRegistered<AkHotelAutosuggestBloc>()) {
      sl.registerFactory<AkHotelAutosuggestBloc>(
        () => AkHotelAutosuggestBloc(AkHotelAutosuggestUseCase(_FakeRepo())),
      );
    }
  });
  tearDownAll(() async => sl.reset());

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('destination screen: popular chips, then search + pick pops the entity',
      (tester) async {
    AkHotelLocationEntity? picked;
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                picked = await Navigator.of(context).push<AkHotelLocationEntity>(
                  MaterialPageRoute(
                    builder: (_) => const HotelDestinationSearchScreen(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Select Destination'), findsOneWidget);
    expect(find.text('Popular Searches'), findsOneWidget);
    expect(find.text('Goa'), findsWidgets); // a popular chip

    await tester.enterText(find.byType(TextField), 'goa');
    await tester.pump(const Duration(milliseconds: 500)); // debounce
    await tester.pump();

    expect(find.text('Taj Exotica'), findsOneWidget);
    await tester.tap(find.text('Taj Exotica'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.id, 'H12345');
    expect(find.text('Select Destination'), findsNothing); // screen popped
  });

  testWidgets('hotel calendar screen uses Check-in / Check-out wording',
      (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await pump(
      tester,
      HotelCalendarScreen(
        checkIn: today,
        checkOut: today.add(const Duration(days: 2)),
        firstDate: today,
        lastDate: today.add(const Duration(days: 365)),
      ),
    );

    expect(find.text('Check-in'), findsOneWidget);
    expect(find.text('Check-out'), findsOneWidget);
    expect(find.text('Select Check-in Date'), findsOneWidget);
    expect(find.text('Return'), findsNothing);
    expect(find.textContaining('Departure'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
