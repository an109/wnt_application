import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../core/error/data_state.dart';
import '../core/resources/app_colours.dart';
import '../core/utils/storage/shared_preference.dart';
import '../injection_container.dart';
import '../views/AKHotelAutosuggest/domain/entity/AKHotelAutosuggest_entity.dart';
import '../views/AKHotelBooking/presentation/screen/ak_hotel_results_screen.dart';
import '../views/AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../views/AKHotelSearchInit/domain/usecase/AKHotelSearchInit_usecase.dart';
import 'hotel_home_card.dart';

/// "Recently Viewed" section — cards redesigned to match `AkHotelSectionCard`
/// (the "Near by" card style on the Akbar results screen) via the shared
/// [HotelHomeCard].
///
/// Backed by real local tracking: [PreferencesManager.addRecentlyViewedHotel]
/// is called wherever the Akbar hotel flow opens a hotel's details (see
/// `AkHotelResultsScreen._navigateToDetail`), so this reads back hotels the
/// user actually viewed — never a static/demo list. Renders nothing until
/// the user has viewed at least one hotel, rather than showing a placeholder.
class HotelRecentlyViewedSection extends StatefulWidget {
  const HotelRecentlyViewedSection({super.key});

  @override
  State<HotelRecentlyViewedSection> createState() => _HotelRecentlyViewedSectionState();
}

class _HotelRecentlyViewedSectionState extends State<HotelRecentlyViewedSection> {
  List<Map<String, dynamic>> _viewed = const [];
  bool _loaded = false;
  int? _searchingIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final viewed = sl<PreferencesManager>().getRecentlyViewedHotels();
      if (!mounted) return;
      setState(() {
        _viewed = viewed;
        _loaded = true;
      });
    } catch (e) {
      debugPrint('Error loading recently viewed hotels: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  List<String> _images(Map<String, dynamic> hotel) {
    final raw = hotel['images'];
    if (raw is List && raw.isNotEmpty) return raw.map((e) => e.toString()).toList();
    final image = (hotel['image'] as String?) ?? '';
    return image.isNotEmpty ? [image] : const [];
  }

  /// The destination this hotel was originally found under (see
  /// `AkHotelResultsScreen._recordRecentlyViewed`). Null for entries saved
  /// before that started being recorded — nothing sensible to re-search for
  /// those, so [_searchAgain] falls back to a message instead of guessing.
  AkHotelLocationEntity? _locationFromHotel(Map<String, dynamic> hotel) {
    final loc = hotel['location'];
    if (loc is! Map || loc['id'] == null) return null;
    return AkHotelLocationEntity(
      id: loc['id'] as String,
      name: (loc['name'] as String?) ?? '',
      fullName: (loc['fullName'] as String?) ?? (loc['name'] as String?) ?? '',
      type: (loc['type'] as String?) ?? 'city',
      state: loc['state'] as String?,
      country: loc['country'] as String?,
      referenceId: loc['referenceId'] as String?,
      lat: (loc['lat'] as num?)?.toDouble(),
      long: (loc['long'] as num?)?.toDouble(),
    );
  }

  List<AkHotelSearchInitRoomEntity> _roomsFromHotel(Map<String, dynamic> hotel) {
    final raw = hotel['rooms'];
    if (raw is! List || raw.isEmpty) {
      return const [AkHotelSearchInitRoomEntity(adults: 1, children: 0, childAges: [])];
    }
    return raw
        .map((r) => AkHotelSearchInitRoomEntity(
              adults: (r['adults'] as num?)?.toInt() ?? 1,
              children: (r['children'] as num?)?.toInt() ?? 0,
              childAges: ((r['childAges'] as List?) ?? const []).map((a) => (a as num).toInt()).toList(),
            ))
        .toList();
  }

  /// Re-runs a brand new Search Init for the same destination this hotel was
  /// originally found under, with fresh dates (tomorrow / the day after —
  /// the original search's own dates are almost certainly in the past by
  /// now), then opens the real results screen. Same "repeat search" pattern
  /// as `HotelRecentSearchesSection._repeatSearch`.
  Future<void> _searchAgain(int index) async {
    if (_searchingIndex != null) return;
    final hotel = _viewed[index];
    final location = _locationFromHotel(hotel);
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search for this destination again to see live pricing'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _searchingIndex = index);
    try {
      final nationality = (hotel['nationality'] as String?) ?? 'IN';
      final rooms = _roomsFromHotel(hotel);
      final checkIn = DateTime.now().add(const Duration(days: 1));
      final checkOut = checkIn.add(const Duration(days: 1));
      final checkInFormatted = DateFormat('MM/dd/yyyy').format(checkIn);
      final checkOutFormatted = DateFormat('MM/dd/yyyy').format(checkOut);

      final result = await sl<AkHotelSearchInitUseCase>().call(
        AkHotelSearchInitRequestEntity(
          locationId: location.id,
          checkIn: checkInFormatted,
          checkOut: checkOutFormatted,
          rooms: rooms,
          nationality: nationality,
          countryOfResidence: nationality,
          destinationCountryCode: location.country ?? nationality,
        ),
      );

      if (!mounted) return;

      if (result is DataSuccess<AkHotelSearchInitEntity>) {
        final data = result.data!;
        final totalAdults = rooms.fold<int>(0, (s, r) => s + r.adults);
        final totalChildren = rooms.fold<int>(0, (s, r) => s + r.children);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AkHotelResultsScreen(
              searchId: data.searchId,
              searchTracingKey: data.searchTracingKey,
              locationName: location.fullName,
              location: location,
              checkIn: checkInFormatted,
              checkOut: checkOutFormatted,
              adults: totalAdults,
              children: totalChildren,
              nationality: nationality,
              rooms: rooms,
              searchedByHotelName: location.type.toLowerCase() == 'hotel',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start a new search. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searchingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _viewed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Viewed',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: context.h(12)),
          SizedBox(
            // Same row height AkHotelSectionCard's own sections use — this
            // card shares that widget's text-block structure, so it needs
            // the same slack to avoid a RenderFlex overflow.
            height: context.h(240),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _viewed.length,
              separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
              itemBuilder: (_, index) {
                final hotel = _viewed[index];
                final name = (hotel['hotelName'] as String?) ?? '';
                final location = ((hotel['address'] as String?)?.isNotEmpty ?? false)
                    ? hotel['address'] as String
                    : (hotel['cityName'] as String?) ?? '';
                final rating = (hotel['rating'] as num?)?.toInt() ?? 0;
                final reviewCount = (hotel['reviewCount'] as num?)?.toInt() ?? 0;
                final reviewRating = (hotel['reviewRating'] as num?)?.toDouble() ?? 0;
                final price = hotel['price'] as String?;
                final isSearching = _searchingIndex == index;

                return Stack(
                  children: [
                    HotelHomeCard(
                      images: _images(hotel),
                      title: name,
                      subtitle: location,
                      priceLabel: (price?.isNotEmpty ?? false) ? price : null,
                      starRating: rating > 0 ? rating : null,
                      reviewRating: reviewRating,
                      reviewCount: reviewCount > 0 ? reviewCount : null,
                      width: 170,
                      // A recently-viewed hotel's own pricing session has
                      // almost certainly expired by now (same as everywhere
                      // else in this app), so tapping it re-runs a brand new
                      // search for the same destination instead of just
                      // telling the user to go do that themselves.
                      onTap: isSearching ? null : () => _searchAgain(index),
                    ),
                    if (isSearching)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(context.r(14)),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
