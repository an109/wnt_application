import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../AKHotelDetailContent/domain/entity/AKHotelDetailContent_entity.dart';
import '../../../AKHotelRooms/domain/entity/AKHotelRooms_entity.dart';
import '../widgets/ak_hotel_image_carousel.dart';
import 'ak_hotel_photo_gallery_screen.dart';
import 'ak_hotel_room_rate_details_screen.dart';

typedef _RoomOption = MapEntry<AkHotelRecommendationEntity, AkHotelRoomGroupEntity>;

/// Room list ("Room Selection"), reached from [AkHotelDetailScreen]'s
/// "SELECT ROOM" bar. Takes the *same in-flight* [roomsFuture] the detail
/// screen already started in its initState, so opening this screen — whether
/// Rooms has already resolved by then or not — never fires a second Rooms
/// API call. [content] (Content API result, may still be null if it hasn't
/// resolved yet) supplies the hotel's own gallery images for each room
/// card's carousel — the Rooms API carries no per-room photos.
///
/// Sibling room-groups that share a room name (different board-basis rate
/// plans from possibly-different providers) are collapsed into one card
/// with a meal-plan picker, rather than one card per option — tapping
/// "Reserve" opens [AkHotelRoomRateDetailsScreen] with that same sibling
/// list for the final rate pick, which is what actually calls
/// [onSelectRoom].
class AkHotelRoomOptionsScreen extends StatefulWidget {
  final String hotelName;
  final Future<DataState<AkHotelRoomsResultEntity>> roomsFuture;
  final void Function(AkHotelRecommendationEntity recommendation, AkHotelRoomGroupEntity roomGroup) onSelectRoom;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final AkHotelDetailContentEntity? content;

  const AkHotelRoomOptionsScreen({
    super.key,
    required this.hotelName,
    required this.roomsFuture,
    required this.onSelectRoom,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    this.content,
  });

  @override
  State<AkHotelRoomOptionsScreen> createState() => _AkHotelRoomOptionsScreenState();
}

class _AkHotelRoomOptionsScreenState extends State<AkHotelRoomOptionsScreen> {
  static const _navy = AppColors.navy;
  static const _blue = AppColors.AppBlue;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  bool _breakfastOnly = false;

  List<String> get _images {
    final c = widget.content;
    if (c == null) return const [];
    final all = <String>[if (c.heroImage.isNotEmpty) c.heroImage, ...c.images];
    return all.toSet().toList();
  }

  /// This room's own photos (from every sibling rate option's `room.images`
  /// — the vendor echoes the same room photos on each rate plan), falling
  /// back to the hotel's gallery only when the vendor didn't supply any.
  /// When every room type has to share that same gallery fallback, [index]
  /// rotates the start of the list per card so consecutive cards open on a
  /// different (still real, still from the API) photo instead of all
  /// showing an identical carousel.
  List<String> _roomImagesFor(List<_RoomOption> options, int index) {
    final roomImages = <String>{for (final o in options) ...o.value.images}.toList();
    if (roomImages.isNotEmpty) return roomImages;
    final gallery = _images;
    if (gallery.length <= 1) return gallery;
    final offset = index % gallery.length;
    return [...gallery.sublist(offset), ...gallery.sublist(0, offset)];
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('dd MMM').format(DateFormat('MM/dd/yyyy').parse(raw));
    } catch (_) {
      return raw;
    }
  }

  void _shareHotel() => Share.share('Check out ${widget.hotelName}!');

  void _openGallery() {
    final images = _images;
    if (images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelPhotoGalleryScreen(
          images: images,
          hotelName: widget.hotelName,
          rating: (widget.content?.starRating ?? 0).round(),
        ),
      ),
    );
  }

  void _openRateDetails(String title, List<_RoomOption> options, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelRoomRateDetailsScreen(
          hotelName: widget.hotelName,
          roomTitle: title,
          options: options,
          initialSelectedIndex: initialIndex,
          content: widget.content,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          onSelectRoom: widget.onSelectRoom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guests = widget.adults + widget.children;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _navy),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Room Selection',
              style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w700, color: _navy),
            ),
            Text(
              '${_formatDate(widget.checkIn)} - ${_formatDate(widget.checkOut)} • $guests Guest${guests == 1 ? '' : 's'}',
              style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.ios_share, size: context.w(20), color: _navy), onPressed: _shareHotel),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<DataState<AkHotelRoomsResultEntity>>(
          future: widget.roomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return SingleChildScrollView(
                padding: context.responsivePadding.copyWith(top: context.gapMedium),
                child: _buildSkeleton(context),
              );
            }

            final result = snapshot.data;
            String? errorMessage;
            List<AkHotelRecommendationEntity> recommendations = const [];
            if (result is DataSuccess<AkHotelRoomsResultEntity>) {
              recommendations = result.data?.recommendations ?? const [];
            } else {
              final message = result is DataFailed<AkHotelRoomsResultEntity> ? result.error?.message : null;
              errorMessage = (message != null && message.toLowerCase().contains('no rooms found'))
                  ? 'No rooms are available for this hotel on the selected dates.'
                  : (message ?? 'Could not load room options. Please try again.');
            }

            if (errorMessage != null) {
              return Center(
                child: Padding(
                  padding: context.responsivePadding,
                  child: Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade400)),
                ),
              );
            }
            if (recommendations.isEmpty) {
              return Center(
                child: Text('No rooms available for these dates.', style: TextStyle(color: _muted)),
              );
            }

            final groups = _groupRooms(recommendations);
            final hasBreakfastOption =
                groups.any((g) => g.value.any((e) => e.value.boardBasisDescription.toLowerCase().contains('breakfast')));
            final visibleGroups = _breakfastOnly
                ? groups.where((g) => g.value.any((e) => e.value.boardBasisDescription.toLowerCase().contains('breakfast'))).toList()
                : groups;

            return SingleChildScrollView(
              physics: context.scrollPhysics,
              padding: context.responsivePadding.copyWith(top: context.gapMedium, bottom: context.gapLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasBreakfastOption) ...[
                    _buildBreakfastFilterChip(context),
                    SizedBox(height: context.gapMedium),
                  ],
                  for (final entry in visibleGroups.asMap().entries)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.gapMedium),
                      child: _RoomOptionCard(
                        title: entry.value.key,
                        options: entry.value.value,
                        images: _roomImagesFor(entry.value.value, entry.key),
                        onOpenGallery: _openGallery,
                        onReserve: (options, index) => _openRateDetails(entry.value.key, options, index),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBreakfastFilterChip(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _breakfastOnly = !_breakfastOnly),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(7)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(color: _breakfastOnly ? _blue : _border),
          color: _breakfastOnly ? _blue.withValues(alpha: 0.08) : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_breakfastOnly) ...[
              Icon(Icons.check, size: context.w(14), color: _blue),
              SizedBox(width: context.w(4)),
            ],
            Text(
              'Breakfast Include',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: _breakfastOnly ? _blue : _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Groups every (recommendation, roomGroup) pair by room title — sibling
  /// options for the same room (different board-basis/provider) sit
  /// together, sorted cheapest-first so index 0 is the pre-selected plan.
  List<MapEntry<String, List<_RoomOption>>> _groupRooms(List<AkHotelRecommendationEntity> recommendations) {
    final entries = <_RoomOption>[
      for (final rec in recommendations)
        for (final rg in rec.roomGroups) MapEntry(rec, rg),
    ];

    final grouped = <String, List<_RoomOption>>{};
    for (final e in entries) {
      final title = e.value.roomName.isEmpty ? 'Room' : e.value.roomName;
      grouped.putIfAbsent(title, () => []).add(e);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.value.totalRate.compareTo(b.value.totalRate));
    }
    return grouped.entries.toList();
  }

  Widget _buildSkeleton(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.r(4))),
        );

    Widget skeletonCard() => Container(
          margin: EdgeInsets.only(bottom: context.gapMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: context.h(150), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(12))))),
              Padding(
                padding: EdgeInsets.all(context.w(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(context.w(140), context.h(14)),
                    SizedBox(height: context.h(8)),
                    bar(context.w(90), context.h(11)),
                    SizedBox(height: context.h(14)),
                    bar(double.infinity, context.h(36)),
                    SizedBox(height: context.h(14)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: bar(context.w(70), context.h(18))),
                        bar(context.w(110), context.h(40)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(children: List.generate(2, (_) => skeletonCard())),
    );
  }
}

/// One room-type card: image carousel, sleeps/refundable summary, a
/// meal-plan picker across [options] (when there's more than one board
/// basis for this room), and a "Reserve" button that hands the whole
/// sibling list + the currently-picked index to [onReserve].
class _RoomOptionCard extends StatefulWidget {
  final String title;
  final List<_RoomOption> options;
  final List<String> images;
  final VoidCallback onOpenGallery;
  final void Function(List<_RoomOption> options, int selectedIndex) onReserve;

  const _RoomOptionCard({
    required this.title,
    required this.options,
    required this.images,
    required this.onOpenGallery,
    required this.onReserve,
  });

  @override
  State<_RoomOptionCard> createState() => _RoomOptionCardState();
}

class _RoomOptionCardState extends State<_RoomOptionCard> {
  static const _navy = AppColors.navy;
  static const _blue = AppColors.AppBlue;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  int _selected = 0;

  /// Prefers the vendor's own `maxGuestAllowed` (or `maxAdultAllowed` +
  /// `maxChildrenAllowed`) when a sibling option actually supplies one —
  /// only falls back to summing [AkHotelOccupancyEntity] (an approximation
  /// of what was searched, not a stated capacity) when the vendor sends
  /// neither.
  int get _maxSleeps {
    for (final o in widget.options) {
      final rg = o.value;
      if (rg.maxGuestAllowed != null && rg.maxGuestAllowed! > 0) return rg.maxGuestAllowed!;
      final adultCap = rg.maxAdultAllowed;
      final childCap = rg.maxChildrenAllowed;
      if (adultCap != null || childCap != null) {
        final total = (adultCap ?? 0) + (childCap ?? 0);
        if (total > 0) return total;
      }
    }
    var max = 0;
    for (final o in widget.options) {
      for (final occ in o.value.occupancies) {
        final total = occ.numOfAdults + occ.numOfChildren;
        if (total > max) max = total;
      }
    }
    return max;
  }

  double? get _area {
    for (final o in widget.options) {
      if (o.value.area != null && o.value.area! > 0) return o.value.area;
    }
    return null;
  }

  List<String> get _bedTypes {
    for (final o in widget.options) {
      if (o.value.bedTypes.isNotEmpty) return o.value.bedTypes;
    }
    return const [];
  }

  String? get _view {
    for (final o in widget.options) {
      if (o.value.view != null && o.value.view!.isNotEmpty) return o.value.view;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.options[_selected];
    final rg = selected.value;
    final roomCount = rg.roomCount > 0 ? rg.roomCount : 1;
    final taxesTotal = rg.taxes.fold<double>(0, (sum, t) => sum + t.amount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AkHotelImageCarousel(
            images: widget.images,
            height: context.h(150),
            onTap: widget.onOpenGallery,
          ),
          Padding(
            padding: EdgeInsets.all(context.w(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: _navy),
                ),
                if (_view != null) ...[
                  SizedBox(height: context.h(4)),
                  Text(
                    _view!,
                    style: TextStyle(fontSize: context.fs(12), color: _blue, fontWeight: FontWeight.w600),
                  ),
                ],
                if (_maxSleeps > 0 || _area != null || _bedTypes.isNotEmpty) ...[
                  SizedBox(height: context.h(6)),
                  Wrap(
                    spacing: context.w(14),
                    runSpacing: context.h(4),
                    children: [
                      if (_area != null) _specChip(context, Icons.square_foot, '${_area!.toStringAsFixed(0)} sq.ft'),
                      if (_maxSleeps > 0) _specChip(context, Icons.person_outline, 'Sleeps $_maxSleeps'),
                      if (_bedTypes.isNotEmpty) _specChip(context, Icons.bed_outlined, _bedTypes.join(', ')),
                    ],
                  ),
                ],
                SizedBox(height: context.h(10)),
                _buildInclusionsBox(context),
                if (widget.options.length > 1) ...[
                  SizedBox(height: context.h(14)),
                  Text(
                    'SELECT MEAL PLAN',
                    style: TextStyle(fontSize: context.fs(10.5), fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.4),
                  ),
                  SizedBox(height: context.h(6)),
                  _buildMealPlanList(context),
                ],
                SizedBox(height: context.h(14)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: CurrencyConverter.currencyListenable,
                        builder: (context, currency, _) {
                          final price = CurrencyConverter.format(
                            CurrencyConverter.convert(amount: rg.totalRate, fromCurrency: 'INR', toCurrency: currency),
                            currency,
                          );
                          final taxes = taxesTotal > 0
                              ? CurrencyConverter.format(
                                  CurrencyConverter.convert(amount: taxesTotal, fromCurrency: 'INR', toCurrency: currency),
                                  currency,
                                )
                              : null;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(price, style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w900, color: _navy)),
                              if (taxes != null)
                                Text(
                                  '+ $taxes taxes & fees for $roomCount room${roomCount == 1 ? '' : 's'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: context.fs(9.5), color: _muted),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    ElevatedButton(
                      onPressed: () => widget.onReserve(widget.options, _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.OrangeColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: context.w(18), vertical: context.h(12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(10))),
                      ),
                      child: Text(
                        'Reserve $roomCount Room${roomCount == 1 ? '' : 's'}',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: context.fs(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Refundable/board-basis/first cancellation-policy line — every string
  /// shown here comes straight from the currently-selected sibling's own
  /// fields, nothing invented.
  Widget _buildInclusionsBox(BuildContext context) {
    final rg = widget.options[_selected].value;
    final extraPolicies = rg.cancellationPolicyTexts.length > 1 ? rg.cancellationPolicyTexts.length - 1 : 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEA),
        border: Border.all(color: const Color(0xFFF3E4B0)),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(rg.refundable ? Icons.check_circle : Icons.cancel, size: context.w(13), color: rg.refundable ? Colors.green : Colors.red),
              SizedBox(width: context.w(6)),
              Text(
                rg.refundable ? 'Refundable' : 'Non-refundable',
                style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: rg.refundable ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ],
          ),
          if (rg.boardBasisDescription.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            _tickLine(context, rg.boardBasisDescription),
          ],
          if (rg.cancellationPolicyTexts.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            _tickLine(
              context,
              extraPolicies > 0 ? '${rg.cancellationPolicyTexts.first}  +$extraPolicies more' : rg.cancellationPolicyTexts.first,
            ),
          ],
          if (rg.roomFacilities.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            _tickLine(
              context,
              rg.roomFacilities.length > 2
                  ? '${rg.roomFacilities.take(2).join(', ')}  +${rg.roomFacilities.length - 2} more'
                  : rg.roomFacilities.join(', '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _specChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.w(14), color: _muted),
        SizedBox(width: context.w(4)),
        Text(label, style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _tickLine(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check, size: context.w(12), color: Colors.green.shade700),
        SizedBox(width: context.w(6)),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: context.fs(11), color: _navy, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildMealPlanList(BuildContext context) {
    final minRate = widget.options.first.value.totalRate;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(context.r(10))),
      child: Column(
        children: List.generate(widget.options.length, (i) {
          final rg = widget.options[i].value;
          final isSelected = i == _selected;
          final delta = rg.totalRate - minRate;
          return InkWell(
            onTap: () => setState(() => _selected = i),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(10)),
              decoration: BoxDecoration(
                color: isSelected ? _blue.withValues(alpha: 0.06) : Colors.transparent,
                border: i == 0 ? null : Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: context.w(18),
                    color: isSelected ? _blue : _muted,
                  ),
                  SizedBox(width: context.w(8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rg.boardBasisDescription.isEmpty ? 'Room Only' : rg.boardBasisDescription,
                          style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w700, color: _navy),
                        ),
                        if (rg.providerName.isNotEmpty)
                          Text(rg.providerName, style: TextStyle(fontSize: context.fs(10), color: _muted)),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: CurrencyConverter.currencyListenable,
                    builder: (context, currency, _) {
                      if (delta <= 0) {
                        return Text('+${CurrencyConverter.getSymbol(currency)}0', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _navy));
                      }
                      final converted = CurrencyConverter.convert(amount: delta, fromCurrency: 'INR', toCurrency: currency);
                      return Text('+${CurrencyConverter.format(converted, currency)}', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _navy));
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
