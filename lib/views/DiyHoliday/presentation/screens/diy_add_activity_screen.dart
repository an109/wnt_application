import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';
import 'diy_addon_detail_screen.dart';
import 'diy_addons_screen.dart' show DiyTripAddonsResult;

enum _Sort { popularity, priceLow, priceHigh }

/// "Add Activity Or Transfers" — what ADD TO DAY opens, for that one day.
///
/// The package's add-ons (**GET /packages/{share_id}/addons/**) split into
/// two tabs: activities, and transfers sold as add-ons (category TRANSFER).
/// The day's own city leads. Picks collect in a tray; UPDATE adds each one to
/// the day (**POST /trips/{trip_id}/activities/**) and pops a
/// [DiyTripAddonsResult] with the repriced trip.
class DiyAddActivityScreen extends StatefulWidget {
  final DiyTrip trip;
  final DiyDay day;
  final String shareId;
  final List<DiyAddon> addons;

  /// Add-ons already added this session, by add-on id.
  final Map<String, String> addedIds;

  const DiyAddActivityScreen({
    super.key,
    required this.trip,
    required this.day,
    required this.shareId,
    this.addons = const [],
    this.addedIds = const {},
  });

  @override
  State<DiyAddActivityScreen> createState() => _DiyAddActivityScreenState();
}

class _DiyAddActivityScreenState extends State<DiyAddActivityScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();
  final TextEditingController _search = TextEditingController();

  late List<DiyAddon> _addons = widget.addons;
  bool _loading = false;
  String? _error;
  bool _transfers = false;
  bool _searching = false;
  bool _updating = false;

  _Sort _sort = _Sort.popularity;
  final Set<String> _categories = {};

  /// Picked on this screen, in the order picked.
  final List<DiyAddon> _picked = [];

  int get _adults => widget.trip.adults > 0 ? widget.trip.adults : 1;
  int get _pax => widget.trip.adults + widget.trip.children;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    if (_addons.isEmpty) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final addons = await _api.getAddons(widget.shareId);
      if (!mounted) return;
      setState(() {
        _addons = addons;
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

  bool _isAdded(DiyAddon a) => widget.addedIds.containsKey(a.id);
  bool _isPicked(DiyAddon a) => _picked.any((p) => p.id == a.id);

  void _toggle(DiyAddon a) => setState(() {
        _isPicked(a) ? _picked.removeWhere((p) => p.id == a.id) : _picked.add(a);
      });

  /// The tab's add-ons: this day's city first, then the rest of the trip's.
  List<DiyAddon> get _visible {
    final query = _search.text.trim().toLowerCase();
    final here = widget.day.destination.toLowerCase();
    final list = _addons
        .where((a) => !a.isComplimentary && a.pricePerPerson > 0)
        .where((a) => a.isTransfer == _transfers)
        .where((a) => _categories.isEmpty || _categories.contains(a.category))
        .where((a) =>
            query.isEmpty ||
            a.name.toLowerCase().contains(query) ||
            a.shortDescription.toLowerCase().contains(query))
        .toList();
    int local(DiyAddon a) => a.destination.toLowerCase() == here ? 0 : 1;
    list.sort((a, b) {
      final byPlace = local(a).compareTo(local(b));
      if (byPlace != 0) return byPlace;
      return switch (_sort) {
        _Sort.popularity => b.popularityRank.compareTo(a.popularityRank),
        _Sort.priceLow => a.pricePerPerson.compareTo(b.pricePerPerson),
        _Sort.priceHigh => b.pricePerPerson.compareTo(a.pricePerPerson),
      };
    });
    return list;
  }

  /// The design's MOST POPULAR badge: the three best-ranked in the catalogue.
  Set<String> get _mostPopular {
    final ranked = _addons.where((a) => a.popularityRank > 0).toList()
      ..sort((a, b) => b.popularityRank.compareTo(a.popularityRank));
    return ranked.take(3).map((a) => a.id).toSet();
  }

  double get _pickedTotal =>
      _picked.fold(0, (sum, a) => sum + a.pricePerPerson * _pax);

  Future<void> _update() async {
    if (_picked.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _updating = true);
    var trip = widget.trip;
    final added = Map<String, String>.from(widget.addedIds);
    try {
      for (final addon in _picked) {
        final result = await _api.addActivity(
          tripId: trip.tripId,
          activityId: addon.id,
          day: widget.day.day,
          previous: trip,
        );
        trip = result.trip;
        added[addon.id] = result.id;
      }
      if (mounted) {
        Navigator.of(context)
            .pop(DiyTripAddonsResult(trip: trip, addedIds: added));
      }
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _knowMore(DiyAddon a) async {
    final select = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DiyAddonDetailScreen(
          addon: a,
          trip: widget.trip,
          day: widget.day,
          selected: _isPicked(a) || _isAdded(a),
        ),
      ),
    );
    if (select == true && !_isPicked(a) && !_isAdded(a) && mounted) _toggle(a);
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final d = diyParseDate(widget.day.date);
    final party = [
      '${widget.trip.adults} Adult${widget.trip.adults == 1 ? '' : 's'}',
      if (widget.trip.children > 0)
        '${widget.trip.children} Child${widget.trip.children == 1 ? '' : 'ren'}',
    ].join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: context.w(24)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search by Activity Name',
                  hintStyle: TextStyle(
                      fontSize: context.fs(12), color: DiyTripStyle.grey),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(10),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.r(8)),
                    borderSide: const BorderSide(color: DiyTokens.blue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.r(8)),
                    borderSide: const BorderSide(color: DiyTokens.blue),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Activity Or Transfers',
                    style: TextStyle(
                      fontSize: context.fs(17),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    [
                      if (d != null) DateFormat('MMM dd').format(d),
                      party,
                    ].join(', '),
                    style: TextStyle(
                        fontSize: context.fs(10), color: DiyTripStyle.grey),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _searching ? Icons.close_rounded : Icons.search_rounded,
              color: DiyTripStyle.grey,
            ),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _search.clear();
            }),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(context.h(48)),
          child: _tabs(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _picked.isEmpty && !_loading ? _sortFilterPill() : null,
      body: _loading
          ? const DiyLoading(message: 'Loading activities…')
          : _error != null
              ? DiyErrorView(message: _error!, onRetry: _load)
              : _list(),
      bottomNavigationBar: _picked.isEmpty ? null : _tray(),
    );
  }

  Widget _tabs() {
    Widget tab(String label, bool transfers) {
      final selected = _transfers == transfers;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _transfers = transfers;
            _categories.clear();
          }),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? DiyTokens.blue : DiyTripStyle.divider,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w500,
                color: selected ? DiyTokens.blue : DiyTripStyle.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Row(children: [tab('Activity', false), tab('Transfers', true)]),
    );
  }

  Widget _list() {
    final items = _visible;
    if (items.isEmpty) {
      return DiyErrorView(
        message: _transfers
            ? 'No transfers to add for this trip.'
            : 'No activities match. Try clearing the search or filters.',
      );
    }
    final popular = _mostPopular;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(20),
        context.w(16),
        context.h(96),
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(18)),
      itemBuilder: (_, i) =>
          _card(items[i], popular: popular.contains(items[i].id)),
    );
  }

  Widget _card(DiyAddon a, {required bool popular}) {
    final added = _isAdded(a);
    final picked = _isPicked(a);
    final image = a.images.isNotEmpty ? a.images.first : a.image;

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: DiyTripStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FB),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: DiyImage(
                  url: image,
                  width: double.infinity,
                  height: context.h(170),
                  fit: a.isTransfer ? BoxFit.contain : BoxFit.cover,
                  radius: BorderRadius.circular(context.r(10)),
                ),
              ),
              if (popular)
                Positioned(
                  right: context.w(10),
                  top: context.h(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(3),
                    ),
                    decoration: BoxDecoration(
                      color: a.isTransfer
                          ? const Color(0xFFF8E6F3)
                          : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                    child: Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        fontSize: context.fs(9),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Text(
            a.name,
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (a.shortDescription.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            Text(
              a.shortDescription,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(12),
                color: DiyTripStyle.grey,
                height: 1.35,
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _knowMore(a),
              child: Text(
                'Know More  >',
                style: TextStyle(fontSize: context.fs(11), color: DiyTokens.blue),
              ),
            ),
          ),
          _dashedLine(),
          SizedBox(height: context.h(10)),
          if (a.durationMinutes > 0)
            _fact(Icons.access_time_filled_rounded,
                'Duration ${diyDuration(a.durationMinutes)}'),
          if (a.pickupIncluded)
            _fact(Icons.directions_car_filled_rounded,
                'Pick up & Drop is included'),
          if (a.destination.isNotEmpty)
            _fact(Icons.location_on_rounded, a.destination),
          SizedBox(height: context.h(14)),
          if (picked || added)
            SizedBox(
              width: double.infinity,
              height: context.h(40),
              child: ElevatedButton(
                onPressed: added ? null : () => _toggle(a),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiyTripStyle.orange,
                  disabledBackgroundColor: DiyTripStyle.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(6)),
                  ),
                ),
                child: Text(
                  added ? 'ADDED' : 'SELECTED',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diyMoney(a.pricePerPerson, currency: a.currency),
                        style: TextStyle(
                          fontSize: context.fs(20),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'price/person',
                        style: TextStyle(
                            fontSize: context.fs(10), color: DiyTripStyle.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: context.w(120),
                  height: context.h(42),
                  child: OutlinedButton(
                    onPressed: () => _toggle(a),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DiyTripStyle.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(8)),
                      ),
                    ),
                    child: Text(
                      'SELECT',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: DiyTripStyle.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dashedLine() {
    return LayoutBuilder(
      builder: (_, box) {
        final dashes = (box.maxWidth / 8).floor();
        return Row(
          children: [
            for (var i = 0; i < dashes; i++)
              Container(
                width: 4,
                height: 1,
                margin: const EdgeInsets.only(right: 4),
                color: DiyTripStyle.border,
              ),
          ],
        );
      },
    );
  }

  Widget _fact(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(6)),
      child: Row(
        children: [
          Icon(icon, size: context.w(14), color: DiyTripStyle.grey),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: context.fs(11), color: DiyTripStyle.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// The picks so far and what the trip comes to with them, and UPDATE.
  Widget _tray() {
    final newTotal = widget.trip.grandTotal + _pickedTotal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFE6F6FD),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _transfers ? 'Transfers' : 'Activities',
                style: TextStyle(
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.blue,
                ),
              ),
              for (final a in _picked)
                Padding(
                  padding: EdgeInsets.only(top: context.h(3)),
                  child: Row(
                    children: [
                      Icon(Icons.local_activity_rounded,
                          size: context.w(11), color: DiyTokens.blue),
                      SizedBox(width: context.w(5)),
                      Expanded(
                        child: Text(
                          a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(10),
                            color: DiyTripStyle.slate,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggle(a),
                        child: Icon(Icons.close_rounded,
                            size: context.w(14), color: DiyTripStyle.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            context.w(16),
            context.h(12),
            context.w(16),
            context.h(12) + MediaQuery.of(context).padding.bottom,
          ),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: diyMoney(newTotal / _adults,
                                currency: widget.trip.currency),
                            style: TextStyle(
                              fontSize: context.fs(20),
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: '/person',
                            style: TextStyle(
                                fontSize: context.fs(11),
                                color: DiyTripStyle.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Total Price ${diyMoney(newTotal, currency: widget.trip.currency)}',
                      style: TextStyle(
                          fontSize: context.fs(9), color: DiyTripStyle.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: context.w(140),
                height: context.h(44),
                child: ElevatedButton(
                  onPressed: _updating ? null : _update,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiyTripStyle.orange,
                    disabledBackgroundColor: const Color(0xFFFFC299),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                  ),
                  child: _updating
                      ? SizedBox(
                          width: context.w(18),
                          height: context.w(18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'UPDATE',
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------- sort/filter

  Widget _sortFilterPill() {
    Widget half(IconData icon, String label, bool dot) {
      return InkWell(
        onTap: _openSortFilter,
        borderRadius: BorderRadius.circular(context.r(30)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(26),
            vertical: context.h(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: context.w(17), color: Colors.black),
              SizedBox(width: context.w(8)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              if (dot) ...[
                SizedBox(width: context.w(5)),
                Container(
                  width: context.w(6),
                  height: context.w(6),
                  decoration: const BoxDecoration(
                    color: DiyTripStyle.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(context.r(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          half(Icons.swap_vert_rounded, 'Sort', false),
          Container(
              width: 1, height: context.h(22), color: DiyTripStyle.divider),
          half(Icons.tune_rounded, 'Filter', _categories.isNotEmpty),
        ],
      ),
    );
  }

  /// Sort & Filter — the order, and the catalogue categories on this tab.
  Future<void> _openSortFilter() async {
    final categories = _addons
        .where((a) => a.isTransfer == _transfers && a.category.isNotEmpty)
        .map((a) => a.category)
        .toSet()
        .toList()
      ..sort();
    var sort = _sort;
    final picked = {..._categories};

    String label(String category) =>
        category[0] + category.substring(1).toLowerCase().replaceAll('_', ' ');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(18))),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Widget sortCard(_Sort value, IconData icon, String title,
              String caption) {
            final selected = sort == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setSheet(() => sort = value),
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
                        title,
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: selected ? DiyTokens.blue : Colors.black,
                        ),
                      ),
                      Text(
                        caption,
                        style: TextStyle(
                            fontSize: context.fs(9), color: DiyTripStyle.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sort & Filter',
                        style: TextStyle(
                          fontSize: context.fs(17),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setSheet(() {
                          sort = _Sort.popularity;
                          picked.clear();
                        }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(8)),
                  Text('Sort By',
                      style: TextStyle(
                          fontSize: context.fs(13), color: DiyTripStyle.grey)),
                  SizedBox(height: context.h(10)),
                  Row(
                    children: [
                      sortCard(_Sort.popularity, Icons.star_outline_rounded,
                          'Popularity', 'Popular First'),
                      SizedBox(width: context.w(10)),
                      sortCard(_Sort.priceLow, Icons.south_rounded, 'Price',
                          'Low to High'),
                      SizedBox(width: context.w(10)),
                      sortCard(_Sort.priceHigh, Icons.north_rounded, 'Price',
                          'High to Low'),
                    ],
                  ),
                  if (categories.isNotEmpty) ...[
                    SizedBox(height: context.h(18)),
                    Text('Category',
                        style: TextStyle(
                            fontSize: context.fs(13),
                            color: DiyTripStyle.grey)),
                    SizedBox(height: context.h(10)),
                    Wrap(
                      spacing: context.w(8),
                      runSpacing: context.h(8),
                      children: [
                        for (final c in categories)
                          GestureDetector(
                            onTap: () => setSheet(() =>
                                picked.contains(c) ? picked.remove(c) : picked.add(c)),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(10),
                                vertical: context.h(6),
                              ),
                              decoration: BoxDecoration(
                                color: picked.contains(c)
                                    ? const Color(0xFFE8F4FC)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(context.r(4)),
                                border: Border.all(
                                  color: picked.contains(c)
                                      ? DiyTokens.blue
                                      : DiyTripStyle.border,
                                ),
                              ),
                              child: Text(
                                label(c),
                                style: TextStyle(fontSize: context.fs(11)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  SizedBox(height: context.h(22)),
                  SizedBox(
                    width: double.infinity,
                    height: context.h(46),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _sort = sort;
                          _categories
                            ..clear()
                            ..addAll(picked);
                        });
                        Navigator.of(sheetContext).pop();
                      },
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
