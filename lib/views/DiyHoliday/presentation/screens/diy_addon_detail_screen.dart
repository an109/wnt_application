import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';

/// Know More on an activity or a transfer add-on: its photos, the day and the
/// party, what it is, what it includes, the option itself with its price,
/// and what it leaves out. Pops true when the customer picks it.
///
/// Every line comes from the catalogue row; the design's languages and
/// cancellation lines are not shown because the catalogue does not hold them.
class DiyAddonDetailScreen extends StatefulWidget {
  final DiyAddon addon;
  final DiyTrip trip;
  final DiyDay day;
  final bool selected;

  const DiyAddonDetailScreen({
    super.key,
    required this.addon,
    required this.trip,
    required this.day,
    this.selected = false,
  });

  @override
  State<DiyAddonDetailScreen> createState() => _DiyAddonDetailScreenState();
}

class _DiyAddonDetailScreenState extends State<DiyAddonDetailScreen> {
  int _page = 0;
  late bool _picked = widget.selected;

  DiyAddon get _a => widget.addon;
  int get _pax => widget.trip.adults + widget.trip.children;

  List<String> get _images =>
      _a.images.isNotEmpty ? _a.images : [if (_a.image.isNotEmpty) _a.image];

  @override
  Widget build(BuildContext context) {
    final d = diyParseDate(widget.day.date);
    final party = [
      '${widget.trip.adults} Adult${widget.trip.adults == 1 ? '' : 's'}',
      if (widget.trip.children > 0)
        '${widget.trip.children} Child${widget.trip.children == 1 ? '' : 'ren'}',
    ].join(', ');
    final highlights = _a.inclusionLines;
    final noun = _a.isTransfer ? 'Transfer' : 'Activity';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: context.w(24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          _a.name,
          maxLines: 2,
          style: TextStyle(
            fontSize: context.fs(15),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(16),
          context.w(16),
          context.h(24),
        ),
        children: [
          _carousel(),
          SizedBox(height: context.h(16)),
          Text(
            _a.name,
            style: TextStyle(
              fontSize: context.fs(17),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(14)),
          Row(
            children: [
              Expanded(
                child: _factBox(
                  Icons.calendar_month_rounded,
                  DiyTokens.blue,
                  'DATE & DAY',
                  'Day ${widget.day.day}'
                      '${d == null ? '' : ' • ${DateFormat('MMM d, yyyy').format(d)}'}',
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _factBox(
                  Icons.groups_rounded,
                  DiyTripStyle.green,
                  'TRAVELLERS',
                  party,
                ),
              ),
            ],
          ),
          if (_a.shortDescription.isNotEmpty) ...[
            SizedBox(height: context.h(16)),
            _card(
              Icons.info_rounded,
              DiyTokens.blue,
              'About $noun',
              Text(
                _a.shortDescription,
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: DiyTripStyle.grey,
                  height: 1.45,
                ),
              ),
            ),
          ],
          if (highlights.isNotEmpty) ...[
            SizedBox(height: context.h(16)),
            _card(
              Icons.stars_rounded,
              DiyTripStyle.orange,
              'Highlights',
              Column(
                children: [
                  for (final h in highlights)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.h(10)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: context.w(18),
                            height: context.w(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DiyTokens.blue.withValues(alpha: 0.12),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: context.w(12),
                              color: DiyTokens.blue,
                            ),
                          ),
                          SizedBox(width: context.w(10)),
                          Expanded(
                            child: Text(
                              h,
                              style: TextStyle(
                                fontSize: context.fs(12),
                                color: DiyTripStyle.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          SizedBox(height: context.h(16)),
          _card(
            _a.isTransfer
                ? Icons.directions_car_filled_rounded
                : Icons.local_activity_rounded,
            DiyTokens.blue,
            '$noun Options',
            _option(),
            trailing: Text(
              '1 Available',
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTripStyle.grey,
              ),
            ),
          ),
          SizedBox(height: context.h(16)),
          _additionalInfo(),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _carousel() {
    final images = _images;
    final radius = BorderRadius.circular(context.r(10));
    if (images.isEmpty) {
      return DiyImage(
        url: '',
        width: double.infinity,
        height: context.h(190),
        radius: radius,
      );
    }
    return SizedBox(
      height: context.h(190),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Container(
              color: _a.isTransfer ? const Color(0xFFF5F6FB) : null,
              child: DiyImage(
                url: images[i],
                width: double.infinity,
                height: context.h(190),
                fit: _a.isTransfer ? BoxFit.contain : BoxFit.cover,
                radius: radius,
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: context.h(8),
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    Container(
                      width: context.w(6),
                      height: context.w(6),
                      margin: EdgeInsets.symmetric(horizontal: context.w(2)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page ? DiyTokens.blue : Colors.white,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _factBox(IconData icon, Color tint, String label, String value) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: DiyTripStyle.divider),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(28),
            height: context.w(28),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Icon(icon, size: context.w(16), color: tint),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(8),
                    fontWeight: FontWeight.w600,
                    color: DiyTripStyle.grey,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    IconData icon,
    Color color,
    String title,
    Widget child, {
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: DiyTripStyle.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.w(18), color: color),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: context.h(10)),
          const Divider(height: 1, color: DiyTripStyle.divider),
          SizedBox(height: context.h(10)),
          child,
        ],
      ),
    );
  }

  Widget _option() {
    final total = _a.pricePerPerson * _pax;
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(
          color: _picked ? DiyTokens.blue : DiyTripStyle.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _a.name,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          if (_a.durationMinutes > 0) ...[
            SizedBox(height: context.h(4)),
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: context.w(12),
                  color: DiyTripStyle.grey,
                ),
                SizedBox(width: context.w(4)),
                Text(
                  'Duration ${diyDuration(_a.durationMinutes)}',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTripStyle.grey,
                  ),
                ),
              ],
            ),
          ],
          if (_a.pickupIncluded) ...[
            SizedBox(height: context.h(8)),
            Row(
              children: [
                Icon(
                  Icons.local_taxi_rounded,
                  size: context.w(14),
                  color: DiyTripStyle.orange,
                ),
                SizedBox(width: context.w(6)),
                Expanded(
                  child: Text(
                    'Pick up & Drop is included',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: DiyTripStyle.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: context.h(10)),
          const Divider(height: 1, color: DiyTripStyle.divider),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diyMoney(_a.pricePerPerson, currency: _a.currency),
                      style: TextStyle(
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'price/person (Total ${diyMoney(total, currency: _a.currency)})',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: context.w(110),
                height: context.h(38),
                child: _picked
                    ? ElevatedButton(
                        onPressed: widget.selected
                            ? null
                            : () => setState(() => _picked = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DiyTripStyle.orange,
                          disabledBackgroundColor: DiyTripStyle.orange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                        ),
                        child: Text(
                          'SELECTED',
                          style: TextStyle(
                            fontSize: context.fs(13),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => setState(() => _picked = true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DiyTripStyle.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                        ),
                        child: Text(
                          'SELECT',
                          style: TextStyle(
                            fontSize: context.fs(13),
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

  Widget _additionalInfo() {
    String label(String category) => category.isEmpty
        ? ''
        : category[0] +
              category.substring(1).toLowerCase().replaceAll('_', ' ');
    final rows = <(String, String)>[
      if (_a.category.isNotEmpty) ('Category', label(_a.category)),
      if (_a.durationMinutes > 0) ('Duration', diyDuration(_a.durationMinutes)),
      if (_a.destination.isNotEmpty) ('Location', _a.destination),
      for (final x in _a.exclusionLines.take(4)) ('Not included', x),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: DiyTripStyle.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADDITIONAL INFO',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(10)),
          for (final (k, v) in rows) ...[
            const Divider(height: 1, color: DiyTripStyle.divider),
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: context.w(110),
                    child: Text(
                      k,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: DiyTripStyle.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      v,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "+₹1,534/person" and UPDATE — which hands the pick back to the list.
  Widget _bottomBar() {
    final adults = widget.trip.adults > 0 ? widget.trip.adults : 1;
    final add = _a.pricePerPerson * _pax;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(19),
        context.h(14),
        context.w(19),
        context.h(14) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: context.w(12),
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
                        text: _picked
                            ? diyDelta(add / adults, currency: _a.currency)
                            : diyMoney(
                                widget.trip.grandTotal / adults,
                                currency: widget.trip.currency,
                              ),
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
                          color: DiyTripStyle.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Total Price ${diyMoney(widget.trip.grandTotal + (_picked ? add : 0), currency: widget.trip.currency)}',
                  style: TextStyle(
                    fontSize: context.fs(9),
                    color: DiyTripStyle.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: context.w(140),
            height: context.h(44),
            child: ElevatedButton(
              onPressed: _picked && !widget.selected
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DiyTripStyle.orange,
                disabledBackgroundColor: const Color(0xFFFFC299),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
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
    );
  }
}
