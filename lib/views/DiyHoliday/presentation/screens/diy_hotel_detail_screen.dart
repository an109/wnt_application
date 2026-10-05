import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';
import 'diy_room_detail_screen.dart';

/// What the hotel page hands back: the room picked in a hotel, and — when the
/// page applied a change itself — the repriced trip. A change made through
/// Change Hotel carries only the trip.
class DiyRoomPick {
  final String hotelRef;
  final String hotelName;
  final DiyRoomOption? room;
  final DiyTrip? trip;

  const DiyRoomPick({
    this.hotelRef = '',
    this.hotelName = '',
    this.room,
    this.trip,
  });
}

/// A hotel's own page — More Details on the stay, and Change Room from the
/// hotel list: photos, rating, place, dates and guests, check-in/out times,
/// amenities, then every room and board it offers.
///
/// Without [hotelRef] it is the hotel already on the stay, and SELECT pins
/// the room straight away (**POST /hotels/** with its `room_ref`), popping a
/// [DiyRoomPick] with the repriced trip. With [hotelRef] it is a hotel the
/// customer is considering; SELECT only reports the room back, and the
/// change-hotel screen applies it with the hotel on UPDATE.
class DiyHotelDetailScreen extends StatefulWidget {
  final DiyTrip trip;
  final DiyStop stop;
  final String? hotelRef;

  /// Shown while the page loads, and where the supplier sends less.
  final String hotelName;
  final List<String> previewImages;
  final String checkIn;
  final String checkOut;
  final int rooms;

  /// The More Details page's "Change Hotel" link; null hides it.
  final VoidCallback? onChangeHotel;

  const DiyHotelDetailScreen({
    super.key,
    required this.trip,
    required this.stop,
    this.hotelRef,
    required this.hotelName,
    this.previewImages = const [],
    this.checkIn = '',
    this.checkOut = '',
    this.rooms = 1,
    this.onChangeHotel,
  });

  @override
  State<DiyHotelDetailScreen> createState() => _DiyHotelDetailScreenState();
}

class _DiyHotelDetailScreenState extends State<DiyHotelDetailScreen> {
  final DiyHolidayApi _api = sl<DiyHolidayApi>();

  DiyHotelRooms? _hotel;
  bool _loading = true;
  String? _error;
  String? _applyingRef;

  bool get _pinnedHotel => widget.hotelRef == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hotel = await _api.getRooms(
        tripId: widget.trip.tripId,
        stopId: widget.stop.stopId,
        hotelRef: widget.hotelRef,
      );
      if (!mounted) return;
      setState(() {
        _hotel = hotel;
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

  Future<void> _pick(DiyRoomOption room) async {
    final hotel = _hotel;
    if (hotel == null || room.isSelected) return;
    final hotelRef = hotel.hotelRef.isNotEmpty
        ? hotel.hotelRef
        : (widget.hotelRef ?? '');
    final name = hotel.hotelName.isNotEmpty
        ? hotel.hotelName
        : widget.hotelName;

    if (!_pinnedHotel) {
      Navigator.of(
        context,
      ).pop(DiyRoomPick(hotelRef: hotelRef, hotelName: name, room: room));
      return;
    }
    setState(() => _applyingRef = room.roomRef);
    try {
      final trip = await _api.changeHotel(
        tripId: widget.trip.tripId,
        stopId: widget.stop.stopId,
        hotelRef: hotelRef,
        roomRef: room.roomRef,
        previous: widget.trip,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        DiyRoomPick(
          hotelRef: hotelRef,
          hotelName: name,
          room: room,
          trip: trip,
        ),
      );
    } catch (e) {
      if (mounted) diySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _applyingRef = null);
    }
  }

  Future<void> _openRoom(DiyRoomOption room) async {
    final hotel = _hotel;
    if (hotel == null) return;
    // The same room at every board it is sold at: the page's rate plans.
    final plans = hotel.rooms.where((r) => r.name == room.name).toList();
    final picked = await Navigator.of(context).push<DiyRoomOption>(
      MaterialPageRoute(
        builder: (_) => DiyRoomDetailScreen(
          roomName: room.name,
          plans: plans,
          hotelFacilities: hotel.facilities,
          adults: widget.trip.adults,
          rooms: _roomCount,
          nights: widget.stop.nights,
          currency: widget.trip.currency,
        ),
      ),
    );
    if (picked != null && mounted) _pick(picked);
  }

  int get _roomCount => widget.rooms > 0 ? widget.rooms : 1;

  // ----------------------------------------------------------------- build

  String get _dateLine {
    final a = diyParseDate(widget.checkIn);
    final b = diyParseDate(widget.checkOut);
    final nights = widget.stop.nights;
    final dates = a == null || b == null
        ? ''
        : '${DateFormat('EEE dd MMM').format(a)} - ${DateFormat('EEE dd MMM').format(b)}';
    return [
      if (dates.isNotEmpty) dates,
      if (nights > 0) '$nights Night${nights == 1 ? '' : 's'}',
    ].join('  •  ');
  }

  @override
  Widget build(BuildContext context) {
    final hotel = _hotel;
    final name = hotel?.hotelName.isNotEmpty == true
        ? hotel!.hotelName
        : widget.hotelName;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              _dateLine,
              style: TextStyle(
                fontSize: context.fs(10),
                color: DiyTripStyle.grey,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onChangeHotel != null)
            TextButton(
              onPressed: widget.onChangeHotel,
              child: Text(
                'Change Hotel',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                  color: DiyTokens.blue,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const DiyLoading(message: 'Loading rooms…')
          : _error != null
          ? DiyErrorView(message: _error!, onRetry: _load)
          : _content(hotel!),
    );
  }

  Widget _content(DiyHotelRooms hotel) {
    final images = hotel.images.isNotEmpty
        ? hotel.images
        : widget.previewImages;
    final stars = (double.tryParse(hotel.starRating) ?? 0).round().clamp(0, 5);
    final guests = widget.trip.adults + widget.trip.children;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(32),
      ),
      children: [
        _gallery(images),
        SizedBox(height: context.h(18)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                hotel.hotelName.isNotEmpty ? hotel.hotelName : widget.hotelName,
                style: TextStyle(
                  fontSize: context.fs(19),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            for (var i = 0; i < stars; i++)
              SvgPicture.asset(
                DiyTripStyle.star,
                width: context.w(15),
                height: context.w(15),
              ),
            if (hotel.reviewRating.isNotEmpty) ...[
              SizedBox(width: context.w(4)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: hotel.reviewRating,
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (hotel.reviewCount > 0)
                      TextSpan(
                        text: '(${hotel.reviewCount})',
                        style: TextStyle(
                          fontSize: context.fs(8),
                          color: DiyTripStyle.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (hotel.location.isNotEmpty) ...[
          SizedBox(height: context.h(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.w(24),
                height: context.w(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6EC),
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: context.w(15),
                  color: DiyTripStyle.orange,
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Text(
                  hotel.location,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: DiyTripStyle.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: context.h(14)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chip(Icons.calendar_month_rounded, _shortDates()),
            SizedBox(width: context.w(10)),
            _chip(
              Icons.person_rounded,
              '$guests Guest${guests == 1 ? '' : 's'}/$_roomCount room',
            ),
          ],
        ),
        if (hotel.checkInTime.isNotEmpty || hotel.checkOutTime.isNotEmpty) ...[
          SizedBox(height: context.h(6)),
          Center(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: context.fs(8), color: Colors.black),
                children: [
                  if (hotel.checkInTime.isNotEmpty) ...[
                    const TextSpan(text: 'Check in : '),
                    TextSpan(
                      text: hotel.checkInTime,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  if (hotel.checkInTime.isNotEmpty &&
                      hotel.checkOutTime.isNotEmpty)
                    const TextSpan(text: ' / '),
                  if (hotel.checkOutTime.isNotEmpty) ...[
                    const TextSpan(text: 'Check out : '),
                    TextSpan(
                      text: hotel.checkOutTime,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: context.h(12)),
        const Divider(height: 1, color: DiyTripStyle.divider),
        if (hotel.facilities.isNotEmpty) ...[
          SizedBox(height: context.h(18)),
          _amenities(hotel.facilities),
        ],
        SizedBox(height: context.h(24)),
        Text(
          'Room',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: context.h(12)),
        if (hotel.rooms.isEmpty)
          Text(
            'No rooms are available for these dates.',
            style: TextStyle(
              fontSize: context.fs(12),
              color: DiyTripStyle.grey,
            ),
          ),
        for (final room in hotel.rooms)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(14)),
            child: _roomCard(room),
          ),
      ],
    );
  }

  String _shortDates() {
    final a = diyParseDate(widget.checkIn);
    final b = diyParseDate(widget.checkOut);
    if (a == null || b == null) return '${widget.stop.nights} Nights';
    return '${DateFormat('dd MMM').format(a)} - ${DateFormat('dd MMM').format(b)}';
  }

  Widget _gallery(List<String> images) {
    String at(int i) => i < images.length ? images[i] : '';
    final radius = BorderRadius.circular(context.r(10));
    return SizedBox(
      height: context.h(184),
      child: Row(
        children: [
          Expanded(
            child: DiyImage(
              url: at(0),
              width: double.infinity,
              height: context.h(184),
              radius: radius,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              children: [
                DiyImage(
                  url: at(1),
                  width: double.infinity,
                  height: context.h(87),
                  radius: radius,
                ),
                SizedBox(height: context.h(10)),
                Stack(
                  children: [
                    DiyImage(
                      url: at(2),
                      width: double.infinity,
                      height: context.h(87),
                      radius: radius,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              DiyTripStyle.photo,
                              width: context.w(16),
                              height: context.w(16),
                            ),
                            SizedBox(height: context.h(4)),
                            Text(
                              'Property photos',
                              style: TextStyle(
                                fontSize: context.fs(11),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(4)),
        border: Border.all(color: DiyTokens.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.w(12), color: DiyTokens.blue),
          SizedBox(width: context.w(5)),
          Text(
            text,
            style: TextStyle(fontSize: context.fs(9), color: DiyTokens.blue),
          ),
        ],
      ),
    );
  }

  Widget _amenities(List<String> facilities) {
    final shown = facilities.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: context.h(12)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(8)),
            border: Border.all(color: DiyTripStyle.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final f in shown)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(diyFacilityIcon(f), size: context.w(15)),
                      SizedBox(width: context.w(5)),
                      Flexible(
                        child: Text(
                          f,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: context.fs(11)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (facilities.length > shown.length)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _allAmenities(facilities),
              child: Text(
                'See All Amenities  >',
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: DiyTokens.blue,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _allAmenities(List<String> facilities) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(18)),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.all(context.w(20)),
          children: [
            Text(
              'Amenities',
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(12)),
            for (final f in facilities)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.h(6)),
                child: Row(
                  children: [
                    Icon(diyFacilityIcon(f), size: context.w(16)),
                    SizedBox(width: context.w(10)),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roomCard(DiyRoomOption room) {
    final adults = widget.trip.adults > 0 ? widget.trip.adults : 1;
    final applying = _applyingRef == room.roomRef;
    final subtitle = [
      room.planName,
      if (room.description.isNotEmpty) room.description,
    ].join(' • ');
    final bullets = [
      ...room.inclusions.take(3),
      room.refundable ? 'Free cancellation available' : 'Non-refundable',
    ];

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(
          color: room.isSelected ? DiyTokens.blue : DiyTripStyle.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room.name,
            style: TextStyle(
              fontSize: context.fs(15),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(11),
              color: DiyTripStyle.grey,
            ),
          ),
          SizedBox(height: context.h(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  DiyImage(
                    url: room.images.isNotEmpty ? room.images.first : '',
                    width: context.w(100),
                    height: context.w(84),
                    radius: BorderRadius.circular(context.r(6)),
                  ),
                  if (room.images.length > 1)
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(5),
                          vertical: context.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(context.r(6)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: context.w(10),
                              color: DiyTokens.blue,
                            ),
                            SizedBox(width: context.w(3)),
                            Text(
                              '${room.images.length}',
                              style: TextStyle(
                                fontSize: context.fs(9),
                                color: DiyTokens.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (room.beds.isNotEmpty)
                      _roomFact(Icons.bed_outlined, room.beds),
                    for (final f in room.facilities.take(2))
                      _roomFact(diyFacilityIcon(f), f),
                    SizedBox(height: context.h(6)),
                    GestureDetector(
                      onTap: () => _openRoom(room),
                      child: Text(
                        'View Room Details  >',
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: DiyTokens.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(color: DiyTripStyle.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: context.w(14),
                      color: DiyTripStyle.green,
                    ),
                    SizedBox(width: context.w(6)),
                    Expanded(
                      child: Text(
                        '${room.planName} Plan',
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (room.isSelected)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(6),
                          vertical: context.h(1),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F6EA),
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: context.fs(9),
                            color: DiyTripStyle.green,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: context.h(6)),
                for (final b in bullets)
                  Padding(
                    padding: EdgeInsets.only(top: context.h(3)),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: context.w(12),
                          color: DiyTripStyle.green,
                        ),
                        SizedBox(width: context.w(6)),
                        Expanded(
                          child: Text(
                            b,
                            style: TextStyle(
                              fontSize: context.fs(10.5),
                              color: DiyTripStyle.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.h(12)),
          if (room.isSelected)
            SizedBox(
              width: double.infinity,
              height: context.h(40),
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
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: room.delta == null
                              ? diyMoney(
                                  room.total / adults,
                                  currency: widget.trip.currency,
                                )
                              : diyDelta(
                                  room.delta! / adults,
                                  currency: widget.trip.currency,
                                ),
                          style: TextStyle(
                            fontSize: context.fs(20),
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: '/adult',
                          style: TextStyle(
                            fontSize: context.fs(11),
                            color: DiyTripStyle.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: context.w(100),
                  height: context.h(38),
                  child: OutlinedButton(
                    onPressed: _applyingRef != null ? null : () => _pick(room),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DiyTripStyle.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(6)),
                      ),
                    ),
                    child: applying
                        ? SizedBox(
                            width: context.w(16),
                            height: context.w(16),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DiyTripStyle.orange,
                            ),
                          )
                        : Text(
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

  Widget _roomFact(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(4)),
      child: Row(
        children: [
          Icon(icon, size: context.w(14), color: DiyTripStyle.grey),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(11),
                color: DiyTripStyle.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon for a supplier facility name — matched on words, so "Outdoor
/// Swimming Pool" and "Pool" both get the pool.
IconData diyFacilityIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('pool')) return Icons.pool_rounded;
  if (n.contains('restaurant') || n.contains('dining')) {
    return Icons.restaurant_rounded;
  }
  if (n.contains('spa') || n.contains('sauna') || n.contains('steam')) {
    return Icons.spa_rounded;
  }
  if (n.contains('wifi') ||
      n.contains('wi-fi') ||
      n.contains('internet') ||
      n.contains('lan')) {
    return Icons.wifi_rounded;
  }
  if (n.contains('parking')) return Icons.local_parking_rounded;
  if (n.contains('gym') || n.contains('fitness')) {
    return Icons.fitness_center_rounded;
  }
  if (n.contains('room service')) return Icons.room_service_rounded;
  if (n.contains('air condition') || n.contains(' ac')) {
    return Icons.ac_unit_rounded;
  }
  if (n.contains('bar')) return Icons.local_bar_rounded;
  if (n.contains('power')) return Icons.power_rounded;
  if (n.contains('tv') || n.contains('television')) return Icons.tv_rounded;
  if (n.contains('laundry')) return Icons.local_laundry_service_rounded;
  if (n.contains('view')) return Icons.landscape_rounded;
  if (n.contains('smok')) return Icons.smoking_rooms_rounded;
  return Icons.check_circle_outline_rounded;
}
