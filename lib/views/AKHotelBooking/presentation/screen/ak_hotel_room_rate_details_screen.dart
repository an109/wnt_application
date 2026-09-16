import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../AKHotelDetailContent/domain/entity/AKHotelDetailContent_entity.dart';
import '../../../AKHotelRooms/domain/entity/AKHotelRooms_entity.dart';
import '../widgets/ak_hotel_amenity_categorizer.dart';
import '../widgets/ak_hotel_image_carousel.dart';

typedef _RateOption = MapEntry<AkHotelRecommendationEntity, AkHotelRoomGroupEntity>;

/// Rate/amenities detail screen reached from [AkHotelRoomOptionsScreen]'s
/// "Reserve" button — lets the user do the final board-basis/rate pick
/// (pre-seeded with whatever meal plan they'd already picked on the room
/// card) alongside the hotel's full amenities list, then "Continue" is what
/// actually invokes [onSelectRoom] (same callback the old inline room list
/// called directly), pushing [AkHotelPriceConfirmScreen] exactly as before.
/// No new API calls are made here — [options] and [content] are handed down
/// from screens that already fetched them.
class AkHotelRoomRateDetailsScreen extends StatefulWidget {
  final String hotelName;
  final String roomTitle;
  final List<_RateOption> options;
  final int initialSelectedIndex;
  final AkHotelDetailContentEntity? content;
  final String checkIn;
  final String checkOut;
  final void Function(AkHotelRecommendationEntity recommendation, AkHotelRoomGroupEntity roomGroup) onSelectRoom;

  const AkHotelRoomRateDetailsScreen({
    super.key,
    required this.hotelName,
    required this.roomTitle,
    required this.options,
    required this.initialSelectedIndex,
    required this.content,
    required this.checkIn,
    required this.checkOut,
    required this.onSelectRoom,
  });

  @override
  State<AkHotelRoomRateDetailsScreen> createState() => _AkHotelRoomRateDetailsScreenState();
}

class _AkHotelRoomRateDetailsScreenState extends State<AkHotelRoomRateDetailsScreen> {
  static const _navy = AppColors.black;
  static const _blue = AppColors.AppBlue;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  late int _selected = widget.initialSelectedIndex.clamp(0, widget.options.length - 1);

  /// This room's own photos (from every sibling rate option's `room.images`
  /// — the vendor echoes the same room photos on each rate plan), falling
  /// back to the hotel's gallery only when the vendor didn't supply any.
  List<String> get _images {
    final roomImages = <String>{for (final o in widget.options) ...o.value.images}.toList();
    if (roomImages.isNotEmpty) return roomImages;
    final c = widget.content;
    if (c == null) return const [];
    final all = <String>[if (c.heroImage.isNotEmpty) c.heroImage, ...c.images];
    return all.toSet().toList();
  }

  int get _nights {
    try {
      final inDate = DateFormat('MM/dd/yyyy').parseStrict(widget.checkIn);
      final outDate = DateFormat('MM/dd/yyyy').parseStrict(widget.checkOut);
      final diff = outDate.difference(inDate).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Prefers the vendor's own `maxGuestAllowed` (or `maxAdultAllowed` +
  /// `maxChildrenAllowed`) when supplied, falling back to summing
  /// [AkHotelOccupancyEntity] only when the vendor sends neither.
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

  void _continue() {
    final selected = widget.options[_selected];
    widget.onSelectRoom(selected.key, selected.value);
  }

  @override
  Widget build(BuildContext context) {
    final selectedRg = widget.options[_selected].value;
    final roomCount = selectedRg.roomCount > 0 ? selectedRg.roomCount : 1;
    final taxesTotal = selectedRg.taxes.fold<double>(0, (sum, t) => sum + t.amount);
    final facilities = widget.content?.facilities ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        // iconTheme: const IconThemeData(color: _navy),
        title: Text('Details', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600, color: _navy)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: context.scrollPhysics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                child: AkHotelImageCarousel(images: _images, height: context.h(220)),
              ),
              Padding(
                padding: context.responsivePadding.copyWith(top: context.gapMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomTitle,
                      style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: _navy),
                    ),
                    if (_view != null) ...[
                      SizedBox(height: context.h(2)),
                      Text(_view!, style: TextStyle(fontSize: context.fs(12), color: _blue, fontWeight: FontWeight.w600)),
                    ],
                    if (_area != null || _maxSleeps > 0 || _bedTypes.isNotEmpty) ...[
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
                  ],
                ),
              ),
              SizedBox(height: context.gapMedium),
              if (facilities.isNotEmpty) _AmenitiesAccordion(facilities: facilities),
              Padding(
                padding: context.responsivePadding.copyWith(top: context.gapLarge, bottom: context.gapMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rate Only', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: _navy)),
                    SizedBox(height: context.gapSmall),
                    for (var i = 0; i < widget.options.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.gapSmall),
                        child: _buildRateCard(context, i),
                      ),
                  ],
                ),
              ),
              SizedBox(height: context.h(90)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, roomCount, taxesTotal),
    );
  }

  Widget _buildRateCard(BuildContext context, int index) {
    final rg = widget.options[index].value;
    final isSelected = index == _selected;
    final roomCount = rg.roomCount > 0 ? rg.roomCount : 1;

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: isSelected ? _blue : _border, width: isSelected ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rg.boardBasisDescription.isEmpty ? 'Room Only' : rg.boardBasisDescription,
            style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w800, color: _navy),
          ),
          SizedBox(height: context.h(6)),
          _bullet(context, rg.refundable ? 'Refundable' : 'Non-refundable', color: rg.refundable ? Colors.green : Colors.red),
          if (rg.providerName.isNotEmpty) _bullet(context, rg.providerName),
          for (final policy in rg.cancellationPolicyTexts.take(2)) _bullet(context, policy),
          SizedBox(height: context.h(10)),
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(price, style: TextStyle(fontSize: context.fs(17), fontWeight: FontWeight.w900, color: _navy)),
                        if (_nights > 0)
                          Text(
                            'For $_nights Night${_nights == 1 ? '' : 's'}, $roomCount Room${roomCount == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: context.fs(9.5), color: _muted),
                          ),
                      ],
                    );
                  },
                ),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _selected = index),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isSelected ? _blue : _border),
                  foregroundColor: isSelected ? _blue : _navy,
                  padding: EdgeInsets.symmetric(horizontal: context.w(20), vertical: context.h(10)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
                ),
                child: Text(
                  isSelected ? 'SELECTED' : 'SELECT',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: context.fs(11)),
                ),
              ),
            ],
          ),
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

  Widget _bullet(BuildContext context, String text, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.h(3)),
            child: Icon(Icons.circle, size: context.w(5), color: color ?? _muted),
          ),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: context.fs(11.5), color: color ?? _muted, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int roomCount, double taxesTotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.symmetric(horizontal: context.gapLarge, vertical: context.gapMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: CurrencyConverter.currencyListenable,
                builder: (context, currency, _) {
                  final selectedRg = widget.options[_selected].value;
                  final price = CurrencyConverter.format(
                    CurrencyConverter.convert(amount: selectedRg.totalRate, fromCurrency: 'INR', toCurrency: currency),
                    currency,
                  );
                  final taxes = taxesTotal > 0
                      ? CurrencyConverter.format(CurrencyConverter.convert(amount: taxesTotal, fromCurrency: 'INR', toCurrency: currency), currency)
                      : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(price, style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w900, color: _navy)),
                      if (taxes != null)
                        Text('+ $taxes taxes & fees', style: TextStyle(fontSize: context.fs(10), color: _muted)),
                      if (_nights > 0)
                        Text(
                          'For $_nights Night${_nights == 1 ? '' : 's'}, $roomCount Room${roomCount == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: context.fs(10), color: _muted),
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(width: context.gapMedium),
            ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: context.w(32), vertical: context.h(14)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
              ),
              child: Text(
                'CONTINUE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: context.fs(13), letterSpacing: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amenities as a per-category accordion, matching the Figma reference:
/// the first category starts expanded in a highlighted box with a "−", the
/// rest start collapsed with a "+". Every facility shown is a real string
/// from Content's `facilities` list — the category buckets themselves are
/// just a presentational grouping (the API gives facilities as a flat
/// list, no category), so anything that doesn't match a known keyword
/// falls into "Basic Facilities" rather than being dropped.
class _AmenitiesAccordion extends StatefulWidget {
  final List<String> facilities;
  const _AmenitiesAccordion({required this.facilities});

  @override
  State<_AmenitiesAccordion> createState() => _AmenitiesAccordionState();
}

class _AmenitiesAccordionState extends State<_AmenitiesAccordion> {
  static const _navy = AppColors.navy;
  static const _muted = AppColors.subhead;
  static const _border = AppColors.lightsubhead;
  static const _blue = AppColors.AppBlue;

  late final Map<String, List<String>> _categories = categorizeAkHotelAmenities(widget.facilities);
  late final Set<String> _expanded = _categories.keys.isEmpty ? {} : {_categories.keys.first};

  @override
  Widget build(BuildContext context) {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amenities', style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: _navy)),
          SizedBox(height: context.gapSmall),
          for (final entry in _categories.entries) ...[
            _buildCategory(context, entry.key, entry.value),
            SizedBox(height: context.h(8)),
          ],
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String name, List<String> items) {
    final isExpanded = _expanded.contains(name);
    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expanded.remove(name);
        } else {
          _expanded.add(name);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: isExpanded ? _blue.withValues(alpha: 0.04) : Colors.white,
          border: Border.all(color: isExpanded ? _blue : AppColors.white, width: 0.2),
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: name, style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600, color: _navy)),
                        TextSpan(
                          text: '  (${items.length} Facilities)',
                          style: TextStyle(fontSize: context.fs(8), color: _muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(isExpanded ? Icons.remove : Icons.add, size: context.w(18), color: _navy),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: context.h(10)),
              for (final item in items)
                Padding(
                  padding: EdgeInsets.only(bottom: context.h(10)),
                  child: Row(
                    children: [
                      Icon(iconForAkHotelAmenity(item), size: context.w(18), color: _muted),
                      SizedBox(width: context.w(10)),
                      Expanded(
                        child: Text(item, style: TextStyle(fontSize: context.fs(12.5), color: _navy, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
