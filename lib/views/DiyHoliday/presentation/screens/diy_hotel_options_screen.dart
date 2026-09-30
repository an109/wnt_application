import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';

/// Hotel options for one stop — **API 9: GET /trips/{trip_id}/stops/
/// {stop_id}/hotels/** — and the swap, **API 10: POST** on the same path
/// with `{"hotel_ref": …}` (`room_ref` optional; omitted here so the backend
/// picks a room).
///
/// The first call for a stop takes roughly 19 seconds and returns ~40
/// options, so the wait is spelled out to the user.
class DiyHotelOptionsScreen extends StatefulWidget {
  /// The trip being edited — the POST answers with a partial trip, so this
  /// is passed back in as the base to merge onto.
  final DiyTrip trip;
  final DiyStop stop;

  const DiyHotelOptionsScreen({
    super.key,
    required this.trip,
    required this.stop,
  });

  String get tripId => trip.tripId;
  String get currency => trip.currency;

  @override
  State<DiyHotelOptionsScreen> createState() => _DiyHotelOptionsScreenState();
}

class _DiyHotelOptionsScreenState extends State<DiyHotelOptionsScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  List<DiyHotelOption> _options = const [];
  bool _loading = true;
  String? _error;
  String? _applyingRef;

  /// Per-card carousel state, keyed by hotel_ref so a rebuild of the list
  /// does not reset the photo a customer has swiped to.
  final Map<String, PageController> _galleryControllers = {};
  final Map<String, int> _galleryPage = {};

  int? _starFilter;
  bool _breakfastOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // One controller is created per multi-photo card and kept for the life of
    // the screen, so they are torn down together here.
    for (final controller in _galleryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await _api.getHotelOptions(
        tripId: widget.tripId,
        stopId: widget.stop.stopId,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _select(DiyHotelOption option) async {
    if (option.isSelected) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _applyingRef = option.hotelRef);
    try {
      final trip = await _api.changeHotel(
        tripId: widget.tripId,
        stopId: widget.stop.stopId,
        hotelRef: option.hotelRef,
        previous: widget.trip,
      );
      if (!mounted) return;
      Navigator.of(context).pop(trip);
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _applyingRef = null);
    }
  }

  List<DiyHotelOption> get _visible {
    return _options.where((o) {
      if (_starFilter != null && o.stars != _starFilter) return false;
      if (_breakfastOnly && !o.freeBreakfast) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: DiyTokens.navy, size: context.w(22)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hotels in ${widget.stop.destination}',
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w700,
                color: DiyTokens.navy,
              ),
            ),
            Text(
              '${widget.stop.nights} night${widget.stop.nights == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTokens.subGrey,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const DiyLoading(
              message: 'Searching hotels for this stop…',
              hint: 'This first search takes about 20 seconds.',
            )
          : _error != null
              ? DiyErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    _filterBar(),
                    Expanded(
                      child: _visible.isEmpty
                          ? const DiyErrorView(
                              message: 'No hotels match these filters.',
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                context.w(14),
                                context.h(10),
                                context.w(14),
                                context.h(24),
                              ),
                              itemCount: _visible.length,
                              itemBuilder: (context, i) => Padding(
                                padding: EdgeInsets.only(bottom: context.h(10)),
                                child: _tile(_visible[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterBar() {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: EdgeInsets.only(right: context.w(8)),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(6),
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F4FC) : Colors.white,
              borderRadius: BorderRadius.circular(context.r(20)),
              border: Border.all(
                color: selected ? DiyTokens.blue : DiyTokens.line,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(11.5),
                fontWeight: FontWeight.w600,
                color: selected ? DiyTokens.blue : DiyTokens.subGrey,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('${_options.length} options', false, () {}),
            for (final star in [3, 4, 5])
              chip(
                '$star★',
                _starFilter == star,
                () => setState(
                  () => _starFilter = _starFilter == star ? null : star,
                ),
              ),
            chip(
              'Free breakfast',
              _breakfastOnly,
              () => setState(() => _breakfastOnly = !_breakfastOnly),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(DiyHotelOption option) {
    final applying = _applyingRef == option.hotelRef;

    return DiyCard(
      padding: EdgeInsets.all(context.w(10)),
      borderColor: option.isSelected ? DiyTokens.blue : null,
      onTap: applying ? null : () => _select(option),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _gallery(option),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.navy,
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              GestureDetector(
                onTap: () => Share.share(
                  'Check out ${option.name}'
                  '${option.location.isNotEmpty ? ' in ${option.location}' : ''}!',
                ),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.share_outlined,
                  size: context.w(16),
                  color: DiyTokens.subGrey,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          _starRow(option),
          if (option.location.isNotEmpty) ...[
            SizedBox(height: context.h(5)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: context.w(13),
                  color: DiyTokens.subGrey,
                ),
                SizedBox(width: context.w(4)),
                Expanded(
                  child: Text(
                    option.location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w600,
                      color: DiyTokens.subGrey,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (option.freeBreakfast || option.distanceKm.isNotEmpty) ...[
            SizedBox(height: context.h(7)),
            Wrap(
              spacing: context.w(6),
              runSpacing: context.h(5),
              children: [
                if (option.freeBreakfast)
                  _perk(Icons.free_breakfast_outlined, 'Free breakfast'),
                if (option.distanceKm.isNotEmpty)
                  _perk(
                    Icons.near_me_outlined,
                    '${option.distanceKm} km from centre',
                  ),
              ],
            ),
          ],
          SizedBox(height: context.h(9)),
          const Divider(height: 1, color: DiyTokens.line),
          SizedBox(height: context.h(8)),
          _priceRow(option),
          if (applying) ...[
            SizedBox(height: context.h(10)),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }

  /// Inset rounded image with a swipeable carousel when the API sent more
  /// than one photo — the same treatment the hotel search result cards use.
  /// The dots and counter are only drawn when there is something to page
  /// through.
  Widget _gallery(DiyHotelOption option) {
    final photos = <String>[
      if (option.heroImage.isNotEmpty) option.heroImage,
      ...option.images.where((u) => u.isNotEmpty && u != option.heroImage),
    ];
    final radius = BorderRadius.circular(context.r(10));
    final height = context.h(150);

    if (photos.length <= 1) {
      return DiyImage(
        url: photos.isEmpty ? '' : photos.first,
        width: double.infinity,
        height: height,
        radius: radius,
      );
    }

    final controller = _galleryControllers.putIfAbsent(
      option.hotelRef,
      () => PageController(),
    );

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: PageView.builder(
                controller: controller,
                itemCount: photos.length,
                onPageChanged: (i) =>
                    setState(() => _galleryPage[option.hotelRef] = i),
                itemBuilder: (_, i) => DiyImage(
                  url: photos[i],
                  width: double.infinity,
                  height: height,
                ),
              ),
            ),
          ),
          Positioned(
            right: context.w(8),
            top: context.h(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(7),
                vertical: context.h(2),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
              child: Text(
                '${(_galleryPage[option.hotelRef] ?? 0) + 1}/${photos.length}',
                style: TextStyle(
                  fontSize: context.fs(9.5),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: context.h(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < photos.length && i < 6; i++)
                  Container(
                    width: context.w(5),
                    height: context.w(5),
                    margin: EdgeInsets.symmetric(horizontal: context.w(2)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_galleryPage[option.hotelRef] ?? 0) == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Amber stars for the property class, then the guest score as a filled
  /// chip — the pairing the hotel result cards use.
  Widget _starRow(DiyHotelOption option) {
    final stars = int.tryParse(option.starRating.split('.').first) ?? 0;

    return Row(
      children: [
        if (stars > 0)
          for (var i = 0; i < stars.clamp(0, 5); i++)
            Icon(
              Icons.star_rounded,
              size: context.w(13),
              color: const Color(0xFFFFC107),
            ),
        if (option.reviewRating.isNotEmpty) ...[
          if (stars > 0) SizedBox(width: context.w(7)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(5),
              vertical: context.h(1),
            ),
            decoration: BoxDecoration(
              color: DiyTokens.blue,
              borderRadius: BorderRadius.circular(context.r(4)),
            ),
            child: Text(
              option.reviewRating,
              style: TextStyle(
                fontSize: context.fs(9.5),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (option.reviewCount > 0) ...[
            SizedBox(width: context.w(5)),
            Text(
              '(${option.reviewCount})',
              style: TextStyle(
                fontSize: context.fs(9.5),
                color: DiyTokens.labelGrey,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _perk(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.w(12), color: Colors.green.shade700),
        SizedBox(width: context.w(4)),
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(10),
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _priceRow(DiyHotelOption option) {
    final deltaColor = option.delta == 0
        ? DiyTokens.subGrey
        : option.delta < 0
            ? Colors.green.shade700
            : DiyTokens.orange;

    return Row(
      children: [
        Expanded(
          child: option.isSelected
              ? Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: context.w(14),
                      color: DiyTokens.blue,
                    ),
                    SizedBox(width: context.w(5)),
                    Text(
                      'Currently in your trip',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w700,
                        color: DiyTokens.blue,
                      ),
                    ),
                  ],
                )
              : Text(
                  'For ${widget.stop.nights} night'
                  '${widget.stop.nights == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTokens.labelGrey,
                  ),
                ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              diyMoney(option.total, currency: widget.currency),
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w800,
                color: DiyTokens.navy,
              ),
            ),
            if (!option.isSelected)
              Text(
                diyDelta(option.delta, currency: widget.currency),
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w600,
                  color: deltaColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
