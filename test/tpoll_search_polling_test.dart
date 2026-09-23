// The poll endpoint first answers `results: [] + more_coming: true` while the
// supplier is still searching (see the device log). The bloc must keep polling
// instead of settling on that empty snapshot.

import 'dart:io';

import 'package:dio/dio.dart';
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
import 'package:wander_nova/views/TPoll_Search/presentation/bloc/TPoll_SearchEvent.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/bloc/TPoll_SearchState.dart';
import 'package:wander_nova/views/TPoll_Search/presentation/screen/TPollSearch_Screen.dart';

SearchResultEntity _ride(String make) => SearchResultEntity(
      resultId: make,
      vehicleId: make,
      providerName: 'KiwiTaxi',
      vehicleType: 'Sedan',
      vehicleName: 'Standard',
      totalPriceAmount: '40',
      totalPriceCurrency: 'USD',
      bookable: true,
      vehicleImageUrl: '',
      maxPassengers: 3,
      maxBags: 2,
      amenities: const [],
      vehicleMake: make,
    );

TpollSearchEntity _snapshot(List<SearchResultEntity> rides, {required bool more}) =>
    TpollSearchEntity(
      success: true,
      search: SearchDataEntity(
        numPassengers: 1,
        pickupDatetime: '2026-09-22T09:00:00',
        searchId: 's',
        results: rides,
        startLocation: const LocationInfoEntity(fullAddress: '', city: 'Mumbai', iataCode: 'BOM'),
        endLocation: const LocationInfoEntity(fullAddress: 'Andheri West', city: '', iataCode: ''),
        currencyInfo: const CurrencyInfoEntity(code: 'USD', prefixSymbol: '\$'),
        expiresIn: 600,
        moreComing: more,
      ),
    );

/// Plays back a script; the last entry repeats forever.
class _ScriptedRepo implements TpollSearchRepository {
  final List<DataState<TpollSearchEntity>> script;
  int calls = 0;
  _ScriptedRepo(this.script);

  @override
  Future<DataState<TpollSearchEntity>> pollSearchResults(String searchId) async {
    final i = calls < script.length ? calls : script.length - 1;
    calls++;
    return script[i];
  }
}

DataState<TpollSearchEntity> _ok(List<SearchResultEntity> r, {required bool more}) =>
    DataSuccess(_snapshot(r, more: more));

DataState<TpollSearchEntity> _fail() => DataFailed(DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    ));

TpollSearchBloc _bloc(_ScriptedRepo repo, {int maxPolls = 40}) => TpollSearchBloc(
      tpollSearchUseCase: TpollSearchUseCase(repo),
      pollInterval: const Duration(milliseconds: 5),
      maxPolls: maxPolls,
    );

Future<List<TpollSearchState>> _collect(TpollSearchBloc bloc) async {
  final states = <TpollSearchState>[];
  final sub = bloc.stream.listen(states.add);
  bloc.add(const TpollSearchFetchEvent(searchId: 's'));
  await Future.delayed(const Duration(milliseconds: 300));
  await sub.cancel();
  await bloc.close();
  return states;
}

void main() {
  test('keeps polling past the empty first snapshot until rides arrive and it finishes', () async {
    final repo = _ScriptedRepo([
      _ok(const [], more: true), // exactly what the device log shows
      _ok(const [], more: true),
      _ok([_ride('Suzuki')], more: true),
      _ok([_ride('Suzuki'), _ride('Toyota')], more: false),
    ]);
    final states = await _collect(_bloc(repo));

    expect(repo.calls, 4); // stopped as soon as more_coming was false
    final successes = states.whereType<TpollSearchSuccess>().toList();
    expect(successes.first.tpollSearchEntity.search.results, isEmpty);
    expect(successes.first.tpollSearchEntity.search.moreComing, isTrue);
    final last = successes.last.tpollSearchEntity.search;
    expect(last.results.length, 2);
    expect(last.moreComing, isFalse);
  });

  test('gives up after maxPolls and settles with moreComing=false (no endless spinner)', () async {
    final repo = _ScriptedRepo([_ok(const [], more: true)]);
    final states = await _collect(_bloc(repo, maxPolls: 3));

    expect(repo.calls, 3);
    final last = (states.last as TpollSearchSuccess).tpollSearchEntity.search;
    expect(last.results, isEmpty);
    expect(last.moreComing, isFalse);
  });

  test('a failure on the first poll is reported', () async {
    final states = await _collect(_bloc(_ScriptedRepo([_fail()])));
    expect(states.last, isA<TpollSearchFailure>());
  });

  test('a blip after rides arrived keeps polling and keeps the rides', () async {
    final repo = _ScriptedRepo([
      _ok([_ride('Suzuki')], more: true),
      _fail(),
      _ok([_ride('Suzuki'), _ride('Toyota')], more: false),
    ]);
    final states = await _collect(_bloc(repo));

    expect(states.whereType<TpollSearchFailure>(), isEmpty);
    expect((states.last as TpollSearchSuccess).tpollSearchEntity.search.results.length, 2);
  });

  group('results screen', () {
    setUpAll(() async {
      // Real Roboto (the default test font is far wider than on a device).
      final fonts = FontLoader('Roboto');
      for (final n in ['regular', 'medium', 'bold']) {
        final f = File('C:/flutter/src/flutter/bin/cache/artifacts/material_fonts/roboto-$n.ttf');
        if (f.existsSync()) {
          fonts.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
        }
      }
      await fonts.load();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      if (!sl.isRegistered<PreferencesManager>()) {
        sl.registerSingleton<PreferencesManager>(await PreferencesManager.create(prefs));
      }
    });

    testWidgets('shows searching (not "No rides found") until rides arrive', (tester) async {
      final repo = _ScriptedRepo([
        _ok(const [], more: true),
        _ok(const [], more: true),
        _ok([_ride('Suzuki')], more: false),
      ]);
      sl.registerFactory<TpollSearchBloc>(() => TpollSearchBloc(
            tpollSearchUseCase: TpollSearchUseCase(repo),
            pollInterval: const Duration(milliseconds: 200),
          ));
      addTearDown(() => sl.unregister<TpollSearchBloc>());

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: TpollSearchResultsPage(
          searchId: 's',
          startAddress: 'BOM',
          endAddress: 'Andheri West',
          pickupDate: DateTime(2026, 9, 22),
          numPassengers: 1,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50)); // first (empty) snapshot in
      expect(find.text('No rides found'), findsNothing);
      expect(find.text('Suzuki'), findsNothing);

      await tester.pump(const Duration(milliseconds: 250)); // 2nd, still empty
      expect(find.text('No rides found'), findsNothing);

      await tester.pump(const Duration(milliseconds: 250)); // rides arrive
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Suzuki'), findsWidgets);
      expect(find.text('No rides found'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
