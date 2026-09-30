import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wander_nova/core/constants/holiday_urls.dart';
import 'package:wander_nova/views/DiyHoliday/data/diy_holiday_api.dart';

void main() {
  test('absolute HolidayUrls paths override Dio baseUrl (no doubled prefix)',
      () async {
    late String seen;
    final dio = Dio(BaseOptions(baseUrl: HolidayUrls.baseUrl));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      seen = o.uri.toString();
      h.reject(DioException(requestOptions: o, message: 'stop'));
    }));
    final api = DiyHolidayApi(dio: dio);

    try { await api.getDestinations(); } catch (_) {}
    expect(seen, 'https://diy.thewandernova.com/api/v1/app/destinations/');

    try { await api.getTrip('TRIP1'); } catch (_) {}
    expect(seen, 'https://diy.thewandernova.com/api/v1/app/trips/TRIP1/');

    try {
      await api.getHotelOptions(tripId: 'T', stopId: 'S');
    } catch (_) {}
    expect(seen,
        'https://diy.thewandernova.com/api/v1/app/trips/T/stops/S/hotels/');

    try {
      await api.getFlightOptions(tripId: 'T', outbound: false);
    } catch (_) {}
    expect(seen,
        'https://diy.thewandernova.com/api/v1/app/trips/T/flights/return/');
  });

  test('live: steps 1-3 reachable and shaped as documented', () async {
    final api = DiyHolidayApi();

    final dests = await api.getDestinations();
    expect(dests, isNotEmpty);
    print('step1 destinations=${dests.length} slugs=${dests.take(4).map((d) => d.slug).toList()}');

    final themes = await api.getThemes();
    print('step2 themes=${themes.length}');

    final page = await api.searchPackages(
        origin: 'new-delhi-in', destination: 'kerala', adults: 2);
    print('step3 packages=${page.results.length} '
        'shareIds=${page.results.map((p) => p.shareId).toList()}');
    expect(page.results, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
