import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/airline_logo.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/MyBookings/Flights/Screen/flight_trip_details_screen.dart';
import 'package:wander_nova/views/MyBookings/Flights/domain/flight_trip_info.dart';
import 'package:wander_nova/views/MyBookings/Hotels/domain/entity/HotelBookingEntity.dart';
import 'package:wander_nova/views/MyBookings/Transport/domain/entity/MyBooking_entity.dart';

import '../../../core/utils/storage/shared_preference.dart';
import '../../../injection_container.dart';
import '../../../newUIWidgets/Home_nav.dart';
import '../../UpcomingTrips/data/models/tripModel.dart';
import '../../UpcomingTrips/presentation/bloc/upcomingTrip_bloc.dart';
import '../../UpcomingTrips/presentation/bloc/upcomingTrip_event.dart';
import '../../UpcomingTrips/presentation/bloc/upcomingTrip_state.dart';
import '../../login/presentation/screen/login.dart';
import '../../offers/offers_screen.dart';
import '../Flights/domain/entities/FlightBookEntity.dart';
import '../Flights/presentation/bloc/FlightBookBloc.dart';
import '../Flights/presentation/bloc/FlightBookEvent.dart';
import '../Flights/presentation/bloc/FlightBookState.dart';
import '../Hotels/Screen/hotel_detail_mainScreen.dart';
import '../Hotels/bloc/BookingListBloc.dart';
import '../Hotels/bloc/BookingListEvent.dart';
import '../Hotels/bloc/BookingListState.dart';
import '../Transport/Screen/Transport_detail_main_screen.dart';
import '../Transport/bloc/MyBooking_bloc.dart';
import '../Transport/bloc/MyBooking_event.dart';
import '../Transport/bloc/MyBooking_state.dart';
import '../visa/screen/visa_booking_summary_card.dart';
import 'trip_card.dart';

// Figma "Trip" frames (upcoming / past trip / cancelled). Every booking the
// user has — flights, hotels, transfers, visas — sorted into the three tabs
// by its travel date and cancellation state.

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);

enum _Tab { upcoming, past, cancelled }

class _Trip {
  final _Tab tab;
  final DateTime? start;
  final TripCardData Function(BuildContext context) card;

  const _Trip(this.tab, this.start, this.card);
}

class MyBookingScreen extends StatefulWidget {
  /// The Trip tab of the home bottom bar; hide it when opened elsewhere.
  final bool showBottomNav;

  const MyBookingScreen({super.key, this.showBottomNav = true});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  _Tab _tab = _Tab.upcoming;

  late final MyBookingBloc _transportBloc;
  late final HotelBookingListBloc _hotelBloc;
  late final FlightBookBloc _flightBloc;
  late final UpcomingTripBloc _visaBloc;
  final List<StreamSubscription<dynamic>> _subs = [];

  List<FlightBookEntity> _flights = [];
  List<HotelBookingListEntity> _hotels = [];
  List<BookingEntity> _transfers = [];
  List<TripItem> _visas = [];

  /// Sources still loading, and those that failed on the last fetch.
  final Set<String> _requested = {};
  final Set<String> _pending = {};
  final Set<String> _failed = {};
  Completer<void>? _refreshing;

  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _transportBloc = sl<MyBookingBloc>();
    _hotelBloc = sl<HotelBookingListBloc>();
    _flightBloc = sl<FlightBookBloc>();
    _visaBloc = sl<UpcomingTripBloc>();

    _subs
      ..add(_flightBloc.stream.listen((s) {
        if (s is FlightBookLoaded) _settle('flight', () => _flights = s.bookings);
        if (s is FlightBookError) _settle('flight', null);
      }))
      ..add(_hotelBloc.stream.listen((s) {
        if (s is HotelLoaded) _settle('hotel', () => _hotels = s.bookings);
        if (s is HotelError) _settle('hotel', null);
      }))
      ..add(_transportBloc.stream.listen((s) {
        if (s is BookingLoaded) _settle('transport', () => _transfers = s.bookings);
        if (s is BookingError) _settle('transport', null);
      }))
      ..add(_visaBloc.stream.listen((s) {
        if (s is UpcomingTripLoaded) {
          _settle('visa', () {
            _visas = s.trips
                .map(TripItem.fromEntity)
                .where((t) => t.category.toLowerCase() == 'visa')
                .toList();
          });
        }
        if (s is UpcomingTripError) _settle('visa', null);
      }));

    _startFetch();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _transportBloc.close();
    _hotelBloc.close();
    _flightBloc.close();
    _visaBloc.close();
    super.dispose();
  }

  /// Pull-to-refresh / retry / after sign-in.
  Future<void> _fetchAll() {
    final done = _startFetch();
    setState(() {});
    return done;
  }

  /// Kicks off every source; completes once they've all answered. Mutates
  /// state directly so it can also run from [initState].
  Future<void> _startFetch() {
    final prefs = sl<PreferencesManager>();
    final userId = prefs.getUserId();
    _signedIn = prefs.isLoggedIn() && userId != null;
    _failed.clear();
    _pending.clear();
    _requested.clear();
    if (!_signedIn) {
      // The bookings endpoints aren't scoped without a user, so never call
      // them for a guest.
      _flights = [];
      _hotels = [];
      _transfers = [];
      _visas = [];
      return Future.value();
    }

    final email = (prefs.getUserData()?['email'] as String?) ?? '';
    _requested.addAll(['flight', 'hotel', 'transport', if (email.isNotEmpty) 'visa']);
    _pending.addAll(_requested);
    _flightBloc.add(FetchFlightBookings(userId: userId));
    _hotelBloc.add(const FetchHotelBookings());
    _transportBloc.add(const FetchBookings());
    if (email.isNotEmpty) _visaBloc.add(FetchUpcomingTrips(userEmail: email));

    _refreshing = Completer<void>();
    return _refreshing!.future;
  }

  void _settle(String source, VoidCallback? apply) {
    if (!mounted) return;
    setState(() {
      apply?.call();
      if (apply == null) _failed.add(source);
      _pending.remove(source);
    });
    if (_pending.isEmpty && !(_refreshing?.isCompleted ?? true)) _refreshing!.complete();
  }

  void _openLogin() {
    Navigator.of(context)
        .push(PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const LoginSignupScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ))
        .then((_) {
          if (mounted) _fetchAll();
        });
  }

  void _onNavTap(int index) {
    if (index == 0) Navigator.of(context).maybePop();
    if (index == 2) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OffersScreen()));
    }
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  List<_Trip> _trips() {
    final all = <_Trip>[
      for (final f in _flights) _flightTrip(f, _push),
      for (final h in _hotels) _hotelTrip(h, _push),
      for (final t in _transfers) _transferTrip(t, _push),
      for (final v in _visas) _visaTrip(v),
    ].where((t) => t.tab == _tab).toList();

    // Soonest first for upcoming; most recent first for the others.
    final far = DateTime(9999);
    all.sort((a, b) {
      final cmp = (a.start ?? far).compareTo(b.start ?? far);
      return _tab == _Tab.upcoming ? cmp : -cmp;
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        bottomNavigationBar: widget.showBottomNav
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: context.h(12)),
                  child: CustomBottomNav(currentIndex: 1, onItemSelected: _onNavTap),
                ),
              )
            : null,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(20), context.fx(16), 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!widget.showBottomNav && Navigator.of(context).canPop()) ...[
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Icon(Icons.arrow_back, size: context.fx(24), color: _kInk),
                          ),
                          SizedBox(width: context.fx(12)),
                        ],
                        Text(
                          'Trip',
                          style: TextStyle(fontSize: context.ffs(24), fontWeight: FontWeight.w500, color: _kInk),
                        ),
                      ],
                    ),
                    SizedBox(height: context.fx(2)),
                    Text(
                      'Plan, save and manage your next adventure with ease.',
                      style: TextStyle(fontSize: context.ffs(13), color: const Color(0xFF4B5563)),
                    ),
                    SizedBox(height: context.fx(18)),
                    _TabBar(selected: _tab, onSelect: (t) => setState(() => _tab = t)),
                  ],
                ),
              ),
              SizedBox(height: context.fx(8)),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (!_signedIn) {
      return _Message(
        icon: Icons.luggage_outlined,
        title: 'Sign in to see your trips',
        body: 'Your flights, hotels, transfers and visas will all show up here.',
        action: ('Sign in', _openLogin),
      );
    }
    final loading = _pending.isNotEmpty;
    final trips = _trips();
    if (loading && _flights.isEmpty && _hotels.isEmpty && _transfers.isEmpty && _visas.isEmpty) {
      return const AppLoadingView(message: 'Loading your trips');
    }

    final Widget content;
    if (trips.isEmpty && _failed.isNotEmpty && _failed.length == _requested.length) {
      content = _Message(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load your trips",
        body: 'Check your connection and try again.',
        action: ('Try again', _fetchAll),
      );
    } else if (trips.isEmpty) {
      content = switch (_tab) {
        _Tab.upcoming => const _Message(
          icon: Icons.flight_takeoff_rounded,
          title: 'No upcoming trips',
          body: 'Trips you book will show up here.',
        ),
        _Tab.past => const _Message(
          icon: Icons.history_rounded,
          title: 'No past trips',
          body: 'Completed trips will show up here.',
        ),
        _Tab.cancelled => const _Message(
          icon: Icons.event_busy_rounded,
          title: 'No cancelled trips',
          body: 'Good news — nothing has been cancelled.',
        ),
      };
    } else {
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.fx(16),
          context.fx(12),
          context.fx(16),
          context.fx(widget.showBottomNav ? 120 : 24) + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: trips.length,
        separatorBuilder: (_, __) => SizedBox(height: context.fx(16)),
        itemBuilder: (context, i) => TripCard(data: trips[i].card(context)),
      );
    }

    return RefreshIndicator(
      color: AppColors.AppBlue,
      onRefresh: _fetchAll,
      child: trips.isEmpty
          ? LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: c.maxHeight, child: content),
              ),
            )
          : content,
    );
  }
}

class _TabBar extends StatelessWidget {
  final _Tab selected;
  final ValueChanged<_Tab> onSelect;

  const _TabBar({required this.selected, required this.onSelect});

  static const _labels = {_Tab.upcoming: 'Upcoming', _Tab.past: 'Past Trips', _Tab.cancelled: 'Cancelled'};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.fx(50),
      padding: EdgeInsets.all(context.fx(5)),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6FD),
        borderRadius: BorderRadius.circular(context.fx(26)),
      ),
      child: Row(
        children: [
          for (final tab in _Tab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(context.fx(22)),
                      boxShadow: tab == selected
                          ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Text(
                      _labels[tab]!,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: context.ffs(14.5),
                        fontWeight: FontWeight.w500,
                        color: tab == selected ? AppColors.AppBlue : _kMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final (String, VoidCallback)? action;

  const _Message({required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.fx(32), 0, context.fx(32), context.fx(80)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.fx(84),
              height: context.fx(84),
              decoration: const BoxDecoration(color: Color(0xFFE9F6FD), shape: BoxShape.circle),
              child: Icon(icon, size: context.fx(36), color: AppColors.AppBlue),
            ),
            SizedBox(height: context.fx(16)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.ffs(16), fontWeight: FontWeight.w600, color: _kInk),
            ),
            SizedBox(height: context.fx(6)),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.ffs(13), height: 1.4, color: _kMuted),
            ),
            if (action != null) ...[
              SizedBox(height: context.fx(18)),
              FilledButton(
                onPressed: action!.$2,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.AppBlue,
                  padding: EdgeInsets.symmetric(horizontal: context.fx(28), vertical: context.fx(12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.fx(24))),
                ),
                child: Text(action!.$1, style: TextStyle(fontSize: context.ffs(14), fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking → card mapping
// ---------------------------------------------------------------------------

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

DateTime? _parse(String? s) => (s == null || s.trim().isEmpty) ? null : DateTime.tryParse(s.trim());

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String _date(DateTime? d) => d == null ? '' : '${d.day} ${_months[d.month - 1]} ${d.year}';

String _shortDate(DateTime? d) => d == null ? '—' : '${d.day} ${_months[d.month - 1]}';

String _time(DateTime? d) =>
    d == null ? '' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Before today (by calendar day) — the trip has ended.
bool _isPast(DateTime? end) => end != null && _day(end).isBefore(_day(DateTime.now()));

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

TripStatus _status(_Tab tab, {bool processing = false, String? label}) => switch (tab) {
  _Tab.cancelled => TripStatus(TripStatusKind.cancelled, label ?? 'Cancelled'),
  _Tab.past => TripStatus(TripStatusKind.completed, label ?? 'Completed'),
  _Tab.upcoming => processing
      ? TripStatus(TripStatusKind.processing, label ?? 'Processing')
      : TripStatus(TripStatusKind.confirmed, label ?? 'Confirmed'),
};

_Trip _flightTrip(FlightBookEntity b, void Function(Widget) push) {
  final info = FlightTripInfo(b);
  final tab = switch (info.state) {
    FlightTripState.upcoming => _Tab.upcoming,
    FlightTripState.past => _Tab.past,
    FlightTripState.cancelled => _Tab.cancelled,
  };
  final dep = info.departure;
  final arr = info.arrival;
  final baggage = info.checkInBaggage.replaceAll(' kg', 'kg');

  return _Trip(
    tab,
    dep,
    (context) => TripCardData(
      leading: AirlineLogo(
        code: info.airlineCode,
        name: info.airline,
        size: context.fx(32),
        borderRadius: BorderRadius.circular(context.fx(6)),
      ),
      title: info.airline,
      titleSuffix: info.flightNumber,
      subtitle: [
        if (info.isConfirmed) 'PNR ${b.pnr}',
        if (info.cabinClass.isNotEmpty) info.cabinClass,
        if (info.isRoundTrip) 'Round trip',
      ].join(' • '),
      status: _status(tab, processing: !info.isConfirmed),
      from: TripEndpoint(
        code: info.fromCode,
        place: info.fromCity,
        time: info.hasSegments ? _time(dep) : '',
        date: _date(dep),
      ),
      to: TripEndpoint(code: info.toCode, place: info.toCity, time: _time(arr), date: _date(arr)),
      middleTop: info.routeSummary,
      middleIcon: Icons.flight_rounded,
      middleBottom: info.checkInOpen ? 'Check-in Open' : null,
      facts: [
        (Icons.person_rounded, info.paxLabel),
        if (info.cabinClass.isNotEmpty) (Icons.airline_seat_recline_normal_rounded, info.cabinClass),
        if (baggage.isNotEmpty) (Icons.luggage_rounded, baggage),
      ],
      onDetails: () => push(FlightTripDetailsScreen(booking: b)),
    ),
  );
}

_Trip _hotelTrip(HotelBookingListEntity h, void Function(Widget) push) {
  final checkIn = _parse(h.checkIn);
  final checkOut = _parse(h.checkOut);
  final status = h.status.toLowerCase();
  final failed = status.contains('fail');
  final tab = (status.contains('cancel') || failed)
      ? _Tab.cancelled
      : (_isPast(checkOut ?? checkIn) ? _Tab.past : _Tab.upcoming);
  final nights = h.nights > 0
      ? h.nights
      : (checkIn != null && checkOut != null ? checkOut.difference(checkIn).inDays : 0);
  final guests = [
    if (h.adults > 0) '${h.adults} Adult',
    if (h.children > 0) _plural(h.children, 'Child').replaceAll('Childs', 'Children'),
  ].join(', ');

  return _Trip(
    tab,
    checkIn,
    (context) => TripCardData(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(context.fx(6)),
        child: h.hotelImage.isNotEmpty
            ? Image.network(
                h.hotelImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const TripIconTile(icon: Icons.hotel_rounded),
              )
            : const TripIconTile(icon: Icons.hotel_rounded),
      ),
      title: h.hotelName.isNotEmpty ? h.hotelName : 'Hotel stay',
      subtitle: [
        if (h.roomType.isNotEmpty) h.roomType,
        if (h.hotelStars > 0) '${h.hotelStars}★',
      ].join(' • '),
      status: _status(tab, processing: status.contains('pending'), label: failed ? 'Failed' : null),
      from: TripEndpoint(code: _shortDate(checkIn), place: 'Check-in', date: checkIn == null ? '' : '${checkIn.year}'),
      to: TripEndpoint(code: _shortDate(checkOut), place: 'Check-out', date: checkOut == null ? '' : '${checkOut.year}'),
      middleTop: nights > 0 ? _plural(nights, 'Night') : 'Stay',
      middleIcon: Icons.hotel_rounded,
      middleBottom: h.hotelCity.isNotEmpty ? h.hotelCity : null,
      facts: [
        if (guests.isNotEmpty) (Icons.person_rounded, guests),
        if (h.rooms > 0) (Icons.meeting_room_rounded, _plural(h.rooms, 'Room')),
      ],
      onDetails: () => push(HotelBookingDetailsScreen(booking: h)),
    ),
  );
}

_Trip _transferTrip(BookingEntity t, void Function(Widget) push) {
  final pickup = _parse(t.pickupDatetime) ?? _parse(t.reservationTimestamp);
  final cancelled = t.cancelled || t.status.toLowerCase().contains('cancel');
  final tab = cancelled ? _Tab.cancelled : (_isPast(pickup) ? _Tab.past : _Tab.upcoming);
  String short(String address) => address.split(',').first.trim();

  return _Trip(
    tab,
    pickup,
    (context) => TripCardData(
      leading: const TripIconTile(icon: Icons.local_taxi_rounded),
      title: t.vehicleName.isNotEmpty ? t.vehicleName : 'Transfer',
      subtitle: [
        if (t.providerName.isNotEmpty) t.providerName,
        if (t.confirmationNumber.isNotEmpty) t.confirmationNumber,
      ].join(' • '),
      status: _status(tab, processing: t.status.toLowerCase().contains('pending')),
      from: TripEndpoint(
        code: t.startAddress.isNotEmpty ? short(t.startAddress) : 'Pickup',
        place: 'Pickup',
        time: _time(pickup),
        date: _date(pickup),
      ),
      to: TripEndpoint(
        code: t.endAddress.isNotEmpty ? short(t.endAddress) : (t.destination.isNotEmpty ? t.destination : 'Drop'),
        place: 'Drop',
      ),
      middleTop: t.type.isNotEmpty ? t.type : 'Transfer',
      middleIcon: Icons.directions_car_rounded,
      middleBottom: t.flightNumber.isNotEmpty ? 'Flight ${t.flightNumber}' : null,
      facts: [
        if (t.applicantCount > 0) (Icons.person_rounded, _plural(t.applicantCount, 'Passenger')),
        if (t.category.isNotEmpty) (Icons.directions_car_filled_rounded, t.category),
      ],
      onDetails: () => push(BookingDetailsScreen(booking: t)),
    ),
  );
}

_Trip _visaTrip(TripItem v) {
  final onward = _parse(v.onwardDate);
  final back = _parse(v.returnDate);
  final status = v.status.toLowerCase();
  final rejected = status.contains('reject');
  final tab = status.contains('cancel')
      ? _Tab.cancelled
      : ((rejected || _isPast(back ?? onward)) ? _Tab.past : _Tab.upcoming);
  final inProgress = ['pending', 'review', 'process', 'submit'].any(status.contains);
  final applicants = int.tryParse(v.applicantCount) ?? 0;

  return _Trip(
    tab,
    onward,
    (context) => TripCardData(
      leading: const TripIconTile(icon: Icons.assignment_rounded),
      title: v.destination.isNotEmpty ? v.destination : 'Visa',
      titleSuffix: 'Visa',
      subtitle: [if (v.type.isNotEmpty) v.type, if (v.refId.isNotEmpty) v.refId].join(' • '),
      status: rejected
          ? const TripStatus(TripStatusKind.cancelled, 'Rejected')
          : _status(tab, processing: inProgress, label: tab == _Tab.upcoming && v.status.isNotEmpty ? v.status : null),
      from: TripEndpoint(code: _shortDate(onward), place: 'Onward', date: onward == null ? '' : '${onward.year}'),
      to: TripEndpoint(code: _shortDate(back), place: 'Return', date: back == null ? '' : '${back.year}'),
      middleTop: v.bookedDate.isNotEmpty ? 'Applied ${v.bookedDate}' : 'Visa',
      middleIcon: Icons.assignment_turned_in_rounded,
      facts: [
        if (applicants > 0) (Icons.person_rounded, _plural(applicants, 'Applicant')),
      ],
      onDetails: () => VisaBookingSummaryCard.showFromTrip(context, v),
    ),
  );
}
