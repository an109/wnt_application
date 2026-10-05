import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';
import 'diy_hotel_detail_screen.dart';

/// "Room Details" — one room type: its photos, beds and sleeping, its own
/// facilities and the hotel's, then every board it is sold at as a rate plan.
/// Pops the [DiyRoomOption] picked, or null.
class DiyRoomDetailScreen extends StatefulWidget {
  final String roomName;

  /// The same room at each board it is sold at.
  final List<DiyRoomOption> plans;
  final List<String> hotelFacilities;
  final int adults;
  final int rooms;
  final int nights;
  final String currency;

  const DiyRoomDetailScreen({
    super.key,
    required this.roomName,
    required this.plans,
    required this.hotelFacilities,
    required this.adults,
    required this.rooms,
    required this.nights,
    required this.currency,
  });

  @override
  State<DiyRoomDetailScreen> createState() => _DiyRoomDetailScreenState();
}

class _DiyRoomDetailScreenState extends State<DiyRoomDetailScreen> {
  int _page = 0;
  final Set<int> _open = {0};

  List<String> get _images {
    final out = <String>[];
    for (final p in widget.plans) {
      for (final i in p.images) {
        if (!out.contains(i)) out.add(i);
      }
    }
    return out;
  }

  DiyRoomOption? get _first => widget.plans.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final room = _first;
    final roomFacilities = <String>{
      for (final p in widget.plans) ...p.facilities,
    }.toList();
    final groups = <(String, List<String>)>[
      if (roomFacilities.isNotEmpty) ('Room Amenities', roomFacilities),
      if (widget.hotelFacilities.isNotEmpty)
        ('Hotel Facilities', widget.hotelFacilities),
    ];

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
        title: Text(
          'Room Details',
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(24),
          context.w(16),
          context.h(32),
        ),
        children: [
          _carousel(images),
          SizedBox(height: context.h(12)),
          Text(
            widget.roomName,
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(6)),
          Wrap(
            spacing: context.w(16),
            runSpacing: context.h(4),
            children: [
              _fact(Icons.people_alt_outlined,
                  'Sleeps ${(widget.adults / (widget.rooms > 0 ? widget.rooms : 1)).ceil()}'),
              if (room != null && room.beds.isNotEmpty)
                _fact(Icons.bed_outlined, room.beds),
            ],
          ),
          if (room != null && room.description.isNotEmpty) ...[
            SizedBox(height: context.h(8)),
            Text(
              room.description,
              style: TextStyle(fontSize: context.fs(11), color: DiyTripStyle.grey),
            ),
          ],
          SizedBox(height: context.h(12)),
          const Divider(height: 1, color: DiyTripStyle.divider),
          if (groups.isNotEmpty) ...[
            SizedBox(height: context.h(18)),
            Text(
              'Amenities',
              style: TextStyle(
                fontSize: context.fs(17),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: context.h(12)),
            for (var i = 0; i < groups.length; i++) _group(i, groups[i]),
          ],
          SizedBox(height: context.h(24)),
          Text(
            'Rate Plans',
            style: TextStyle(
              fontSize: context.fs(17),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: context.h(12)),
          Container(
            padding: EdgeInsets.all(context.w(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.r(10)),
              border: Border.all(color: DiyTripStyle.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < widget.plans.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.h(14)),
                      child: const Divider(
                          height: 1, color: DiyTripStyle.divider),
                    ),
                  _plan(widget.plans[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carousel(List<String> images) {
    final radius = BorderRadius.circular(context.r(10));
    if (images.isEmpty) {
      return DiyImage(
        url: '',
        width: double.infinity,
        height: context.h(170),
        radius: radius,
      );
    }
    return SizedBox(
      height: context.h(170),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => DiyImage(
              url: images[i],
              width: double.infinity,
              height: context.h(170),
              radius: radius,
            ),
          ),
          Positioned(
            bottom: context.h(8),
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length && i < 8; i++)
                  Container(
                    width: i == _page ? context.w(14) : context.w(6),
                    height: context.w(6),
                    margin: EdgeInsets.symmetric(horizontal: context.w(2)),
                    decoration: BoxDecoration(
                      color: i == _page ? DiyTokens.blue : Colors.white,
                      borderRadius: BorderRadius.circular(context.r(3)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fact(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.w(14), color: DiyTripStyle.grey),
        SizedBox(width: context.w(4)),
        Text(
          text,
          style: TextStyle(fontSize: context.fs(11), color: DiyTripStyle.grey),
        ),
      ],
    );
  }

  Widget _group(int index, (String, List<String>) group) {
    final (title, items) = group;
    final open = _open.contains(index);
    return Container(
      margin: EdgeInsets.only(bottom: context.h(8)),
      decoration: BoxDecoration(
        color: open ? const Color(0xFFF2FAFE) : Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(
          color: open ? const Color(0xFFBFE6F8) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
                () => open ? _open.remove(index) : _open.add(index)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: title,
                            style: TextStyle(
                              fontSize: context.fs(12),
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' (${items.length} Facilities)',
                            style: TextStyle(
                              fontSize: context.fs(9),
                              color: DiyTripStyle.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(open ? Icons.remove_rounded : Icons.add_rounded,
                      size: context.w(18)),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(10),
                0,
                context.w(10),
                context.h(10),
              ),
              child: Column(
                children: [
                  for (final f in items)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.h(5)),
                      child: Row(
                        children: [
                          Icon(diyFacilityIcon(f),
                              size: context.w(16), color: Colors.black87),
                          SizedBox(width: context.w(8)),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: context.fs(12),
                                color: DiyTripStyle.slate,
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
      ),
    );
  }

  Widget _plan(DiyRoomOption plan) {
    final bullets = [
      ...plan.inclusions.take(3),
      plan.refundable ? 'Free cancellation available' : 'Non-refundable',
    ];
    final roomsLabel = '${widget.rooms} Room${widget.rooms == 1 ? '' : 's'}';
    final nightsLabel = '${widget.nights} Night${widget.nights == 1 ? '' : 's'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.planName,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            if (plan.isSelected)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.r(10)),
                  border: Border.all(color: DiyTokens.blue),
                  color: const Color(0xFFEAF7FD),
                ),
                child: Text(
                  'ON YOUR PACKAGE',
                  style: TextStyle(
                    fontSize: context.fs(8),
                    fontWeight: FontWeight.w700,
                    color: DiyTokens.blue,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.h(8)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in bullets)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.h(4)),
                      child: Text(
                        '•  $b',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          color: DiyTripStyle.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  diyMoney(plan.total, currency: widget.currency),
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (plan.delta != null && !plan.isSelected)
                  Text(
                    '${diyDelta(plan.delta!, currency: widget.currency)} on your package',
                    style: TextStyle(
                      fontSize: context.fs(8),
                      color: DiyTripStyle.grey,
                    ),
                  ),
                Text(
                  'For $nightsLabel, $roomsLabel',
                  style: TextStyle(
                    fontSize: context.fs(8),
                    color: DiyTripStyle.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        SizedBox(
          width: plan.isSelected ? double.infinity : null,
          height: context.h(38),
          child: Align(
            alignment: Alignment.centerRight,
            child: plan.isSelected
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: DiyTripStyle.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(6)),
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
                    ),
                  )
                : SizedBox(
                    width: context.w(110),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(plan),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: DiyTripStyle.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(6)),
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
          ),
        ),
      ],
    );
  }
}
