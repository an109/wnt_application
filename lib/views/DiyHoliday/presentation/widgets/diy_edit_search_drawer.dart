import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/diy_dates.dart';
import '../../data/diy_origins.dart';
import '../../data/diy_search_query.dart';
import '../../data/models/diy_models.dart';
import '../screens/diy_calendar_screen.dart';
import '../screens/diy_destination_search_screen.dart';
import '../screens/diy_image_search_screen.dart';
import '../screens/diy_origin_search_screen.dart';
import 'diy_common.dart';

/// "Edit Your Search" — the top drawer the results screen opens from its edit
/// pencil.
///
/// Slides down from the top over a dimmed page, with a circular × floating
/// below it, matching the transfer flow's [showTpollEditSearchDrawer]. The
/// form is the holiday search form without its hero image: origin,
/// destination, starting date and room/party, then MODIFY SEARCH.
///
/// Returns the edited [DiySearchQuery] when the customer taps MODIFY SEARCH,
/// or null if they dismiss it — so the caller only re-runs the search on a
/// deliberate change.
Future<DiySearchQuery?> showDiyEditSearchDrawer(
  BuildContext context, {
  required DiySearchQuery query,
}) {
  return showGeneralDialog<DiySearchQuery>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit your search',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => _DiyEditSearchDrawer(query: query),
    transitionBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        ),
        child: child,
      );
    },
  );
}

class _DiyEditSearchDrawer extends StatefulWidget {
  final DiySearchQuery query;

  const _DiyEditSearchDrawer({required this.query});

  @override
  State<_DiyEditSearchDrawer> createState() => _DiyEditSearchDrawerState();
}

class _DiyEditSearchDrawerState extends State<_DiyEditSearchDrawer> {
  static const String _icCalendar = 'assets/NewIcons/departureCalendar.png';
  static const String _icAdult = 'assets/NewIcons/TravellerAdult.png';
  static const String _icChild = 'assets/NewIcons/TravellerChild.png';

  late DiyOrigin _origin = widget.query.origin;
  late DiyDestination? _destination = widget.query.destination;
  late DateTime? _departureDate =
      widget.query.departureDate ?? DiyDates.defaultDeparture();
  late int _rooms = widget.query.rooms;
  late int _adults = widget.query.adults;
  late int _children = widget.query.children;

  Future<void> _pickOrigin() async {
    final picked = await Navigator.of(context).push<DiyOrigin>(
      MaterialPageRoute(builder: (_) => const DiyOriginSearchScreen()),
    );
    if (picked != null) setState(() => _origin = picked);
  }

  Future<void> _pickDestination() async {
    final picked = await Navigator.of(context).push<DiyDestination>(
      MaterialPageRoute(builder: (_) => const DiyDestinationSearchScreen()),
    );
    if (picked != null) setState(() => _destination = picked);
  }

  Future<void> _pickDate() async {
    final picked = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => DiyCalendarScreen(initialDate: _departureDate),
      ),
    );
    if (picked != null) setState(() => _departureDate = picked);
  }

  void _modify() {
    Navigator.of(context).pop(
      DiySearchQuery(
        origin: _origin,
        destination: _destination,
        departureDate: _departureDate,
        rooms: _rooms,
        adults: _adults,
        children: _children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(context.r(24));

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: radius,
                    bottomRight: radius,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(18),
                      context.h(8),
                      context.w(18),
                      context.h(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title(),
                        SizedBox(height: context.h(16)),
                        _fieldBox(
                          label: 'STARTING FROM',
                          onTap: _pickOrigin,
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: context.w(18),
                                color: DiyTokens.blue,
                              ),
                              SizedBox(width: context.w(8)),
                              Expanded(
                                child: Text(
                                  _origin.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _valueStyle(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.h(12)),
                        _fieldBox(
                          label: 'TRAVELLING TO',
                          onTap: _pickDestination,
                          trailing: _cameraButton(),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: context.w(18),
                                color: DiyTokens.blue,
                              ),
                              SizedBox(width: context.w(8)),
                              Expanded(
                                child: Text(
                                  _destination?.name ?? 'Anywhere',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _valueStyle(
                                    muted: _destination == null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.h(12)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _dateField()),
                            SizedBox(width: context.w(12)),
                            Expanded(child: _roomField()),
                          ],
                        ),
                        SizedBox(height: context.h(18)),
                        _modifyButton(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.h(14)),
              // Close — floats outside the drawer, bottom centre, same as the
              // transfer drawer.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: context.w(38),
                  height: context.w(38),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: context.w(21),
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: context.h(16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: Icon(
            Icons.arrow_back,
            size: context.w(22),
            color: DiyTokens.navy,
          ),
        ),
        SizedBox(width: context.w(14)),
        Text(
          'Edit Your Search',
          style: TextStyle(
            fontSize: context.fs(19),
            fontWeight: FontWeight.w700,
            color: DiyTokens.navy,
          ),
        ),
      ],
    );
  }

  TextStyle _valueStyle({bool muted = false}) => TextStyle(
        fontSize: context.fs(15),
        fontWeight: FontWeight.w600,
        color: muted ? DiyTokens.labelGrey : DiyTokens.navy,
      );

  TextStyle _labelStyle() => TextStyle(
        fontSize: context.fs(9.5),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DiyTokens.labelGrey,
      );

  Widget _fieldBox({
    required String label,
    required Widget child,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          context.w(14),
          context.h(10),
          context.w(10),
          context.h(12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE3E7EF)),
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: _labelStyle()),
                  SizedBox(height: context.h(6)),
                  child,
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  /// "Search with a image" — the same visual-search entry the Holidays search
  /// card offers, so the drawer is not a reduced version of the form.
  Widget _cameraButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickByImage,
      child: Container(
        width: context.w(38),
        height: context.w(34),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DiyTokens.orange,
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Icon(
          Icons.photo_camera_rounded,
          size: context.w(19),
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _pickByImage() async {
    final picked = await Navigator.of(context).push<DiyDestination>(
      MaterialPageRoute(builder: (_) => const DiyImageSearchScreen()),
    );
    if (picked != null) setState(() => _destination = picked);
  }

  Widget _dateField() {
    final d = _departureDate;
    return _fieldBox(
      label: 'STARTING DATE',
      onTap: _pickDate,
      child: Row(
        children: [
          Image.asset(
            _icCalendar,
            width: context.w(19),
            height: context.w(19),
            errorBuilder: (_, __, ___) => Icon(
              Icons.calendar_today_rounded,
              size: context.w(17),
              color: DiyTokens.blue,
            ),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d == null ? 'Select' : diyFullDate(d),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _valueStyle(muted: d == null),
                ),
                if (d != null)
                  Text(
                    diyWeekday(d),
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: DiyTokens.subGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomField() {
    return _fieldBox(
      label: 'ROOM',
      onTap: _openPartySheet,
      child: Row(
        children: [
          _countChip(icon: Icons.bed_rounded, count: _rooms),
          _countDivider(),
          _countChip(asset: _icAdult, count: _adults),
          _countDivider(),
          _countChip(asset: _icChild, count: _children),
        ],
      ),
    );
  }

  Widget _countDivider() => Container(
        width: 0.5,
        height: context.w(18),
        margin: EdgeInsets.symmetric(horizontal: context.w(8)),
        color: Colors.grey.shade300,
      );

  Widget _countChip({IconData? icon, String? asset, required int count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null)
          Image.asset(
            asset,
            width: context.w(14),
            height: context.w(14),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.person_rounded,
              size: context.w(15),
              color: DiyTokens.blue,
            ),
          )
        else
          Icon(icon, size: context.w(15), color: DiyTokens.blue),
        SizedBox(width: context.w(4)),
        Text(
          '$count',
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w600,
            color: DiyTokens.navy,
          ),
        ),
      ],
    );
  }

  /// Room / adults / children steppers. Kept in a small sheet rather than
  /// inline so the drawer stays the height of the Figma.
  Future<void> _openPartySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.r(18))),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Widget row(
              String label,
              int value,
              int min,
              int max,
              ValueChanged<int> onChanged,
            ) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(18),
                  vertical: context.h(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                          color: DiyTokens.navy,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: value > min
                          ? () {
                              onChanged(value - 1);
                              setSheetState(() {});
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: DiyTokens.blue,
                    ),
                    SizedBox(
                      width: context.w(28),
                      child: Text(
                        '$value',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w700,
                          color: DiyTokens.navy,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: value < max
                          ? () {
                              onChanged(value + 1);
                              setSheetState(() {});
                            }
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: DiyTokens.blue,
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: context.h(14)),
                  Text(
                    'Rooms & travellers',
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                      color: DiyTokens.navy,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  row('Rooms', _rooms, 1, 9, (v) => _rooms = v),
                  // The price API (API 5) needs at least one adult.
                  row('Adults', _adults, 1, 20, (v) => _adults = v),
                  row('Children', _children, 0, 10, (v) => _children = v),
                  SizedBox(height: context.h(10)),
                ],
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Widget _modifyButton() {
    return SizedBox(
      width: double.infinity,
      height: context.h(52),
      child: ElevatedButton(
        onPressed: _modify,
        style: ElevatedButton.styleFrom(
          backgroundColor: DiyTokens.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(30)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MODIFY SEARCH',
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: context.w(10)),
            Icon(Icons.arrow_forward, size: context.w(18)),
          ],
        ),
      ),
    );
  }
}
