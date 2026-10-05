import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';

enum DiyHotelSort { popularity, priceLow, priceHigh }

/// The change-hotel screen's Sort & Filters. Everything here filters the
/// hotels already loaded, so the sheet needs no request of its own.
class DiyHotelFilters {
  final DiyHotelSort sort;

  /// Upgrade difference per person, at most. Null is no ceiling.
  final double? maxPerPerson;
  final Set<int> stars;
  final Set<String> locations;
  final Set<String> amenities;

  const DiyHotelFilters({
    this.sort = DiyHotelSort.popularity,
    this.maxPerPerson,
    this.stars = const {},
    this.locations = const {},
    this.amenities = const {},
  });

  bool get isActive =>
      maxPerPerson != null ||
      stars.isNotEmpty ||
      locations.isNotEmpty ||
      amenities.isNotEmpty;
}

class DiyHotelFilterScreen extends StatefulWidget {
  final DiyHotelFilters initial;

  /// The slider's ends: the cheapest and dearest upgrade per person.
  final double priceMin;
  final double priceMax;

  /// Every locality and facility the loaded hotels mention, most common
  /// first.
  final List<String> locations;
  final List<String> amenities;

  const DiyHotelFilterScreen({
    super.key,
    required this.initial,
    required this.priceMin,
    required this.priceMax,
    required this.locations,
    required this.amenities,
  });

  @override
  State<DiyHotelFilterScreen> createState() => _DiyHotelFilterScreenState();
}

class _DiyHotelFilterScreenState extends State<DiyHotelFilterScreen> {
  late DiyHotelSort _sort = widget.initial.sort;
  late double _max = widget.initial.maxPerPerson ?? widget.priceMax;
  late final Set<int> _stars = {...widget.initial.stars};
  late final Set<String> _locations = {...widget.initial.locations};
  late final Set<String> _amenities = {...widget.initial.amenities};
  bool _allLocations = false;
  bool _allAmenities = false;

  void _reset() => setState(() {
        _sort = DiyHotelSort.popularity;
        _max = widget.priceMax;
        _stars.clear();
        _locations.clear();
        _amenities.clear();
      });

  void _apply() {
    Navigator.of(context).pop(DiyHotelFilters(
      sort: _sort,
      maxPerPerson: _max >= widget.priceMax ? null : _max,
      stars: _stars,
      locations: _locations,
      amenities: _amenities,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = widget.priceMax > widget.priceMin;
    return Scaffold(
      backgroundColor: DiyTokens.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black, size: context.w(22)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Sort & Filters',
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              'Reset',
              style: TextStyle(fontSize: context.fs(13), color: DiyTokens.blue),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(context.w(14)),
        children: [
          _section(
            'Sort By',
            Row(
              children: [
                _sortCard(DiyHotelSort.popularity, Icons.star_outline_rounded,
                    'Popularity', 'Popular First'),
                SizedBox(width: context.w(10)),
                _sortCard(DiyHotelSort.priceLow, Icons.south_rounded, 'Price',
                    'Low to High'),
                SizedBox(width: context.w(10)),
                _sortCard(DiyHotelSort.priceHigh, Icons.north_rounded, 'Price',
                    'High to Low'),
              ],
            ),
          ),
          if (hasRange)
            _section(
              'Price Range',
              Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(10),
                        vertical: context.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.r(6)),
                        border: Border.all(color: DiyTripStyle.border),
                      ),
                      child: Text(
                        '${diyDelta(_max)}/person',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Slider(
                    min: widget.priceMin,
                    max: widget.priceMax,
                    value: _max.clamp(widget.priceMin, widget.priceMax),
                    activeColor: DiyTokens.blue,
                    onChanged: (v) => setState(() => _max = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(diyDelta(widget.priceMin),
                          style: TextStyle(fontSize: context.fs(11))),
                      Text(diyDelta(widget.priceMax),
                          style: TextStyle(fontSize: context.fs(11))),
                    ],
                  ),
                ],
              ),
            ),
          _section(
            'Star Rating',
            Wrap(
              spacing: context.w(10),
              runSpacing: context.h(10),
              children: [
                for (final s in const [2, 3, 4, 5])
                  _chip(
                    '$s Star',
                    _stars.contains(s),
                    () => setState(
                        () => _stars.contains(s) ? _stars.remove(s) : _stars.add(s)),
                    leading: Icon(Icons.star_rounded,
                        size: context.w(14), color: const Color(0xFFF4B400)),
                  ),
              ],
            ),
          ),
          if (widget.locations.isNotEmpty)
            _chipSection(
              'Locations',
              widget.locations,
              _locations,
              _allLocations,
              () => setState(() => _allLocations = !_allLocations),
              'Locations',
            ),
          if (widget.amenities.isNotEmpty)
            _chipSection(
              'Amenities',
              widget.amenities,
              _amenities,
              _allAmenities,
              () => setState(() => _allAmenities = !_allAmenities),
              'Amenities',
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(12),
          context.w(16),
          context.h(12) + MediaQuery.of(context).padding.bottom,
        ),
        color: Colors.white,
        child: SizedBox(
          height: context.h(46),
          child: ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: DiyTripStyle.orange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
            ),
            child: Text(
              'APPLY',
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(14)),
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: DiyTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: context.fs(14), color: DiyTripStyle.grey),
          ),
          SizedBox(height: context.h(12)),
          child,
        ],
      ),
    );
  }

  Widget _sortCard(
      DiyHotelSort sort, IconData icon, String label, String caption) {
    final selected = _sort == sort;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sort = sort),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.h(10)),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F4FC) : Colors.white,
            borderRadius: BorderRadius.circular(context.r(8)),
            border: Border.all(
              color: selected ? DiyTokens.blue : DiyTripStyle.border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: context.w(18),
                  color: selected ? DiyTokens.blue : Colors.black),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: selected ? DiyTokens.blue : Colors.black,
                ),
              ),
              Text(
                caption,
                style:
                    TextStyle(fontSize: context.fs(9), color: DiyTripStyle.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipSection(
    String title,
    List<String> all,
    Set<String> picked,
    bool expanded,
    VoidCallback toggle,
    String noun,
  ) {
    final shown = expanded ? all : all.take(4).toList();
    return _section(
      title,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.w(8),
            runSpacing: context.h(8),
            children: [
              for (final item in shown)
                _chip(
                  item,
                  picked.contains(item),
                  () => setState(() =>
                      picked.contains(item) ? picked.remove(item) : picked.add(item)),
                ),
            ],
          ),
          if (all.length > 4)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: toggle,
                child: Text(
                  expanded ? 'Show less' : '${all.length - 4} More $noun',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    color: DiyTokens.blue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {Widget? leading}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(10),
          vertical: context.h(7),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4FC) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(4)),
          border: Border.all(
            color: selected ? DiyTokens.blue : DiyTripStyle.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, SizedBox(width: context.w(4))],
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w500,
                color: selected ? DiyTokens.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
