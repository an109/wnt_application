// PreferencesManager's real "Recently Viewed Hotels" local tracking — the
// data source HotelRecentlyViewedSection reads back (see
// AkHotelResultsScreen._recordRecentlyViewed for the write side).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PreferencesManager> freshManager() async {
    SharedPreferences.setMockInitialValues({});
    return PreferencesManager.create(await SharedPreferences.getInstance());
  }

  test('records a viewed hotel and reads it back', () async {
    final prefs = await freshManager();
    await prefs.addRecentlyViewedHotel({
      'hotelCode': 'H1',
      'hotelName': 'Taj Palace',
      'image': 'https://example.com/taj.jpg',
      'address': 'Connaught Place, Delhi',
    });

    final viewed = prefs.getRecentlyViewedHotels();
    expect(viewed, hasLength(1));
    expect(viewed.first['hotelName'], 'Taj Palace');
  });

  test('most recently viewed hotel comes first', () async {
    final prefs = await freshManager();
    await prefs.addRecentlyViewedHotel({'hotelCode': 'H1', 'hotelName': 'A'});
    await prefs.addRecentlyViewedHotel({'hotelCode': 'H2', 'hotelName': 'B'});

    final viewed = prefs.getRecentlyViewedHotels();
    expect(viewed.map((h) => h['hotelName']), ['B', 'A']);
  });

  test('re-viewing the same hotel moves it to the front, not duplicated', () async {
    final prefs = await freshManager();
    await prefs.addRecentlyViewedHotel({'hotelCode': 'H1', 'hotelName': 'A'});
    await prefs.addRecentlyViewedHotel({'hotelCode': 'H2', 'hotelName': 'B'});
    await prefs.addRecentlyViewedHotel({'hotelCode': 'H1', 'hotelName': 'A'});

    final viewed = prefs.getRecentlyViewedHotels();
    expect(viewed, hasLength(2));
    expect(viewed.map((h) => h['hotelName']), ['A', 'B']);
  });

  test('keeps only the most recent 10', () async {
    final prefs = await freshManager();
    for (var i = 0; i < 12; i++) {
      await prefs.addRecentlyViewedHotel({'hotelCode': 'H$i', 'hotelName': 'Hotel $i'});
    }

    final viewed = prefs.getRecentlyViewedHotels();
    expect(viewed, hasLength(10));
    // Newest (H11) first, oldest two (H0, H1) dropped.
    expect(viewed.first['hotelName'], 'Hotel 11');
    expect(viewed.map((h) => h['hotelName']), isNot(contains('Hotel 0')));
    expect(viewed.map((h) => h['hotelName']), isNot(contains('Hotel 1')));
  });

  test('nothing viewed yet returns an empty list, not a fabricated entry', () async {
    final prefs = await freshManager();
    expect(prefs.getRecentlyViewedHotels(), isEmpty);
  });
}
