import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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
import '../../TrishaAI/presentation/screen/trisha_chat_screen.dart';
import '../../wishlist/wishlist_screen.dart';
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
import '../visa/screen/visa_booking_summary_card.dart' show VisaBookingSummaryScreen;
import 'trip_card.dart';
import 'hotel_booking_card.dart';
import 'transfer_booking_card.dart';
import 'visa_booking_card.dart';
import '../Insurance/bloc/InsuranceBookingBloc.dart';
import '../Insurance/bloc/InsuranceBookingEvent.dart';
import '../Insurance/bloc/InsuranceBookingState.dart';
import '../Insurance/domain/entity/InsuranceBookingEntity.dart';
import '../Insurance/screen/insurance_detail_screen.dart';
import '../../home/presentation/widgets/home_sections.dart' show HomeCroppedImage;

// "My Bookings": every booking the user has — flights, hotels, transfers,
// visas — filtered by service, searchable, and (outside Visa) sorted into
// Upcoming / Past / Cancelled by travel date and cancellation state. Visa has
// its own filters (All / In Progress / Approved / Rejected) because a visa is
// tracked by its application status, not by a travel date.e4444444444444$44444

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);

enum _Tab { all, upcoming, past, cancelled }

enum _Service { all, flight, hotel, transfer, visa, insurance, holiday }

enum _VisaTab { all, inProgress, approved, rejected }

/// Where a visa application is, for the Visa  filters.
enum _VisaGroup { inProgress, approved, rejected, other }

class _Trip {
  final _Service service;

  /// Lower-cased text the search box matches against: booking id, place, names.
  final String search;

  /// Visa only: which of the Visa filters it belongs to.
  final _VisaGroup visaGroup;

  /// Set for visas, which draw their own card instead of [card].
  final Widget Function(BuildContext context)? custom;

  final _Tab tab;

  /// When the trip itself happens — departure, check-in, pickup.
  final DateTime? start;

  /// When the booking was *made*. Drives the ordering, so a trip the user
  /// just paid for sits at the top of the list however far off it is.
  final DateTime? bookedOn;

  final TripCardData Function(BuildContext context)? card;

  const _Trip(
    this.tab,
    this.start,
    this.bookedOn,
    this.card, {
    required this.service,
    this.search = '',
    this.visaGroup = _VisaGroup.other,
    this.custom,
  });
}

class MyBookingScreen extends StatefulWidget {
  /// The Trip tab of the home bottom bar; hide it when opened elsewhere.
  final bool showBottomNav;

  const MyBookingScreen({super.key, this.showBottomNav = true});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  final Map<_Service, _Tab> _tabs = {
    for (final s in _Service.values) s: _Tab.all,
  };
  _Service _service = _Service.all;
  _VisaTab _visaTab = _VisaTab.all;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  late final MyBookingBloc _transportBloc;
  late final HotelBookingListBloc _hotelBloc;
  late final FlightBookBloc _flightBloc;
  late final UpcomingTripBloc _visaBloc;
  late final InsuranceBookingBloc _insuranceBloc;
  final List<StreamSubscription<dynamic>> _subs = [];

  List<FlightBookEntity> _flights = [];
  List<HotelBookingListEntity> _hotels = [];
  List<BookingEntity> _transfers = [];
  List<TripItem> _visas = [];
  List<InsuranceBookingEntity> _insurances = [];

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
    _insuranceBloc = sl<InsuranceBookingBloc>();

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
      ..add(_insuranceBloc.stream.listen((s) {
        if (s is InsuranceBookingLoaded) _settle('insurance', () => _insurances = s.bookings);
        if (s is InsuranceBookingError) _settle('insurance', null);
      }))
      ..add(_visaBloc.stream.listen((s) {
        if (s is UpcomingTripLoaded) {
          print('VISA DEBUG: UpcomingTripLoaded with ${s.trips.length} trips');
          for (final t in s.trips) {
            print('VISA DEBUG: trip id=${t.id} dest=${t.destination} type=${t.visaType} status=${t.status} tracker_stage=${t.tracker.stage}');
          }
          _settle('visa', () {
            final all = s.trips.map(TripItem.fromEntity).toList();
            print('VISA DEBUG: After TripItem.fromEntity: ${all.length} items, categories: ${all.map((t) => t.category).toSet()}');
            _visas = all
                .where((t) => t.category.toLowerCase() == 'visa')
                .toList();
            print('VISA DEBUG: After filter: ${_visas.length} visa items');
          });
        }
        if (s is UpcomingTripError) {
          print('VISA DEBUG: UpcomingTripError: ${s.error.message}');
          _settle('visa', null);
        }
        if (s is UpcomingTripLoading) {
          print('VISA DEBUG: UpcomingTripLoading');
        }
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
    _insuranceBloc.close();
    _searchCtrl.dispose();
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
      _insurances = [];
      return Future.value();
    }

    final email = (prefs.getUserData()?['email'] as String?) ?? '';
    print('VISA DEBUG: userId=$userId, email="$email", signedIn=$_signedIn');
    _requested.addAll(['flight', 'hotel', 'transport', 'insurance', if (email.isNotEmpty) 'visa']);
    _pending.addAll(_requested);
    _flightBloc.add(FetchFlightBookings(userId: userId));
    _hotelBloc.add(const FetchHotelBookings());
    _transportBloc.add(const FetchBookings());
    _insuranceBloc.add(FetchInsuranceBookings());
    if (email.isNotEmpty) {
      print('VISA DEBUG: Dispatching FetchUpcomingTrips with email=$email');
      _visaBloc.add(FetchUpcomingTrips(userEmail: email));
    } else {
      print('VISA DEBUG: Email is empty, skipping visa fetch');
    }

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
    if (apply != null) _precacheImages(source);
    if (_pending.isEmpty && !(_refreshing?.isCompleted ?? true)) _refreshing!.complete();
  }

  void _precacheImages(String source) {
    final urls = <String>[];
    if (source == 'hotel') {
      for (final h in _hotels) {
        if (h.hotelImage.isNotEmpty) urls.add(h.hotelImage);
      }
    } else if (source == 'transport') {
      for (final t in _transfers) {
        if (t.imageUrl.isNotEmpty) urls.add(t.imageUrl);
      }
    }
    for (final url in urls) {
      precacheImage(NetworkImage(url), context);
    }
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
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OffersScreen()),
        );
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WishlistScreen()),
        );
    }
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  List<_Trip> _everyTrip() => [
    for (final f in _flights) _flightTrip(f, _push),
    for (final h in _hotels) _hotelTrip(h, _push),
    for (final t in _transfers) _transferTrip(t, _push),
    for (final v in _visas) _visaTrip(v),
    for (final i in _insurances) _insuranceTrip(i, _push),
    // for (final hd in _holidays) _holidayTrip(hd, _push),
  ];

  /// What the current chip, sub-filter and search show.
  bool _shown(_Trip t) {
    if (_service != _Service.all && t.service != _service) return false;
    if (_query.isNotEmpty && !t.search.contains(_query)) return false;
    if (_service == _Service.all) return true;
    if (_service == _Service.visa) {
      return switch (_visaTab) {
        _VisaTab.all => t.visaGroup != _VisaGroup.rejected,
        _VisaTab.inProgress => t.visaGroup == _VisaGroup.inProgress,
        _VisaTab.approved => t.visaGroup == _VisaGroup.approved,
        _VisaTab.rejected => t.visaGroup == _VisaGroup.rejected,
      };
    }
    final activeTab = _tabs[_service] ?? _Tab.upcoming;
    if (activeTab == _Tab.all) return true;
    return t.tab == activeTab;
  }

  List<_Trip> _trips() {
    final all = _everyTrip().where(_shown).toList();

    // Newest booking first, in every tab: the booking the user just made is
    // what they open this screen to check. Where the API gave us no booking
    // timestamp at all, the travel date stands in so the trip still sorts
    // somewhere sensible instead of sinking to the bottom.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    all.sort((a, b) {
      final aKey = a.bookedOn ?? a.start ?? epoch;
      final bKey = b.bookedOn ?? b.start ?? epoch;
      return bKey.compareTo(aKey);
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
                  child: CustomBottomNav(
                    currentIndex: 1,
                    onItemSelected: _onNavTap,
                    onCenterTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrishaChatScreen()),
                    ),
                  ),
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
                          switch (_service) {
                            _Service.all => 'My Bookings',
                            _Service.flight => 'Flight Bookings',
                            _Service.hotel => 'Hotel Bookings',
                            _Service.transfer => 'Transfer Bookings',
                            _Service.visa => 'Visa Bookings',
                            _Service.insurance => 'Insurance',
                            _Service.holiday => 'Holiday Bookings',
                          },
                          style: TextStyle(fontSize: context.ffs(24), fontWeight: FontWeight.w500, color: _kInk),
                        ),
                      ],
                    ),
                    SizedBox(height: context.fx(2)),
                    Text(
                      switch (_service) {
                        _Service.all => 'Track and manage all your bookings in one place.',
                        _Service.flight => 'Track and manage your flight bookings.',
                        _Service.hotel => 'Track and manage your hotel bookings.',
                        _Service.transfer => 'Track and manage your transfer bookings.',
                        _Service.visa => 'Track and manage your visa applications in one place.',
                        _Service.insurance => 'Track and manage your insurance policies.',
                        _Service.holiday => 'Track and manage your holiday packages.',
                      },
                      style: TextStyle(fontSize: context.ffs(13), color: const Color(0xFF4B5563)),
                    ),
                    SizedBox(height: context.fx(14)),
                  ],
                ),
              ),
              _ServiceChips(selected: _service, onSelect: (s) => setState(() => _service = s)),
              Padding(
                padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(12), context.fx(16), 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    ),
                    SizedBox(height: context.fx(14)),
                    if (_service == _Service.visa)
                      _SegmentBar<_VisaTab>(
                        values: _VisaTab.values,
                        labels: {
                          _VisaTab.all: 'All',
                          _VisaTab.inProgress:
                              'In Progress (${_visas.where((v) => _visaGroup(v) == _VisaGroup.inProgress).length})',
                          _VisaTab.approved: 'Approved',
                          _VisaTab.rejected: 'Rejected',
                        },
                        selected: _visaTab,
                        onSelect: (t) => setState(() => _visaTab = t),
                      )
                    else if (_service != _Service.all && _service != _Service.insurance)
                      _SegmentBar<_Tab>(
                        values: _Tab.values,
                        labels: const {_Tab.all: 'All', _Tab.upcoming: 'Upcoming', _Tab.past: 'Past Trips', _Tab.cancelled: 'Cancelled'},
                        selected: _tabs[_service] ?? _Tab.upcoming,
                        onSelect: (t) => setState(() => _tabs[_service] = t),
                      ),
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
        title: 'Sign in to see your bookings',
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
        title: "Couldn't load your bookings",
        body: 'Check your connection and try again.',
        action: ('Try again', _fetchAll),
      );
    } else if (trips.isEmpty && _query.isNotEmpty) {
      content = const _Message(
        icon: Icons.search_off_rounded,
        title: 'No bookings found',
        body: 'Try a different booking ID, destination or name.',
      );
    } else if (trips.isEmpty && _service == _Service.visa) {
      content = const _Message(
        icon: Icons.assignment_outlined,
        title: 'No visa applications here',
        body: 'Visa applications you make will show up here with their progress.',
      );
    } else if (trips.isEmpty && _service == _Service.insurance) {
      content = const _Message(
        icon: Icons.shield_outlined,
        title: 'No insurance policies here',
        body: 'Insurance policies you purchase will show up here.',
      );
    } else if (trips.isEmpty && _service == _Service.all) {
      content = const _HolidayByThemeEmpty();
    } else if (trips.isEmpty) {
      final tab = _tabs[_service] ?? _Tab.upcoming;
      content = switch (tab) {
        _Tab.all => const _Message(
          icon: Icons.luggage_outlined,
          title: 'No bookings yet',
          body: 'Bookings you make will show up here.',
        ),
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
        itemBuilder: (context, i) => trips[i].custom?.call(context) ?? TripCard(data: trips[i].card!(context)),
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

/// Service chips: All / Flights / Hotels / Transfer / Visa.
class _ServiceChips extends StatelessWidget {
  final _Service selected;
  final ValueChanged<_Service> onSelect;

  const _ServiceChips({required this.selected, required this.onSelect});

  static const _r1 = 'assets/home/services_row1.png';
  static const _r2 = 'assets/home/services_row2.png';

  static const _items = <_Service, String>{
    _Service.all: 'All',
    _Service.flight: 'Flights',
    _Service.hotel: 'Hotels',
    _Service.transfer: 'Transfer',
    _Service.visa: 'Visa',
    _Service.insurance: 'Insurance',
    _Service.holiday: 'Holiday',
  };

  static Widget? _chipIcon(_Service s, double size) {
    return switch (s) {
      _Service.flight    => HomeCroppedImage(asset: _r1, width: size, height: size, imageWidthFactor: 5.0895, imageHeightFactor: 1.6941, leftFactor: -0.1469, topFactor: -0.3765),
      _Service.hotel     => HomeCroppedImage(asset: _r1, width: size, height: size, imageWidthFactor: 5.0895, imageHeightFactor: 1.6941, leftFactor: -1.4116, topFactor: -0.3471),
      _Service.holiday   => HomeCroppedImage(asset: _r1, width: size, height: size, imageWidthFactor: 5.0895, imageHeightFactor: 1.6941, leftFactor: -2.6175, topFactor: -0.4059),
      _Service.visa      => HomeCroppedImage(asset: _r2, width: size, height: size, imageWidthFactor: 3.9512, imageHeightFactor: 1.2857, leftFactor: -0.1951, topFactor: -0.2143),
      _Service.transfer  => HomeCroppedImage(asset: _r2, width: size, height: size, imageWidthFactor: 3.3585, imageHeightFactor: 1.2857, leftFactor: -2.2909, topFactor: -0.2143),
      _Service.insurance => HomeCroppedImage(asset: _r2, width: size, height: size, imageWidthFactor: 3.9512, imageHeightFactor: 1.2857, leftFactor: -1.3422, topFactor: -0.2143),
      _Service.all       => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.fx(38),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.fx(16)),
        itemCount: _items.length,
        separatorBuilder: (_, __) => SizedBox(width: context.fx(8)),
        itemBuilder: (context, i) {
          final service = _items.keys.elementAt(i);
          final label = _items[service]!;
          final on = service == selected;
          final icon = _chipIcon(service, context.fx(20));
          return Semantics(
            button: true,
            selected: on,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(service),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: context.fx(14)),
                decoration: BoxDecoration(
                  color: on ? AppColors.AppBlue : Colors.white,
                  borderRadius: BorderRadius.circular(context.fx(20)),
                  border: Border.all(color: on ? AppColors.AppBlue : const Color(0xFFCCCCCC)),
                  boxShadow: on
                      ? [BoxShadow(color: const Color(0x4D3B82F6), blurRadius: 1, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null)
                      icon
                    else
                      Icon(Icons.grid_view_rounded, size: context.fx(14), color: on ? Colors.white : _kMuted),
                    SizedBox(width: context.fx(6)),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: context.ffs(12),
                        fontWeight: FontWeight.w600,
                        color: on ? Colors.white : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.fx(46),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: context.ffs(13.5), color: _kInk),
        decoration: InputDecoration(
          hintText: 'Search by booking ID, destination or applicant',
          hintStyle: TextStyle(fontSize: context.ffs(13), color: const Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search_rounded, size: context.fx(20), color: _kMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, size: context.fx(18), color: _kMuted),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.fx(12)),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.fx(12)),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.fx(12)),
            borderSide: BorderSide(color: AppColors.AppBlue),
          ),
        ),
      ),
    );
  }
}

/// The rounded segmented bar under the search box (Upcoming / Past / Cancelled,
/// or All / In Progress / Approved / Rejected for Visa).
class _SegmentBar<T> extends StatelessWidget {
  final List<T> values;
  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onSelect;

  const _SegmentBar({required this.values, required this.labels, required this.selected, required this.onSelect});

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
          for (final tab in values)
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
                      labels[tab] ?? '',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: context.ffs(values.length > 3 ? 12.5 : 14.5),
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

class _HolidayTheme {
  final String title;
  final String image;
  final Color overlay;
  const _HolidayTheme(this.title, this.image, this.overlay);
}

const _holidayThemes = [
  _HolidayTheme('Beach Getaway', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', Color(0xFF0EA5E9)),
  _HolidayTheme('Mountain Escape', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', Color(0xFF059669)),
  _HolidayTheme('City Break', 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400', Color(0xFF7C3AED)),
  _HolidayTheme('Heritage Tour', 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400', Color(0xFFD97706)),
  _HolidayTheme('Adventure Trip', 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=400', Color(0xFFDC2626)),
  _HolidayTheme('Romantic Escape', 'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=400', Color(0xFFEC4899)),
];

class _HolidayByThemeEmpty extends StatelessWidget {
  const _HolidayByThemeEmpty();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: context.fx(16), vertical: context.fx(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.fx(20)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.fx(16)),
            ),
            child: Column(
              children: [
                Icon(Icons.luggage_outlined, size: context.fx(40), color: Colors.white.withOpacity(0.8)),
                SizedBox(height: context.fx(12)),
                Text(
                  'Your adventures start here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.ffs(18),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: context.fx(6)),
                Text(
                  'No bookings yet — explore holidays by theme and book your dream trip today.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.ffs(13),
                    height: 1.5,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.fx(24)),
          Center(
            child: Text(
              'Pick Yours One ',
              style: TextStyle(
                fontSize: context.ffs(17),
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          SizedBox(height: context.fx(6)),
          Center(
            child: Text(
              'Pick a vibe, we\'ll plan the rest',
              style: TextStyle(fontSize: context.ffs(13), color: _kMuted),
            ),
          ),
          SizedBox(height: context.fx(14)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: context.fx(12),
              crossAxisSpacing: context.fx(12),
              childAspectRatio: 1.4,
            ),
            itemCount: _holidayThemes.length,
            itemBuilder: (context, i) {
              final theme = _holidayThemes[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(context.fx(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: theme.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: theme.overlay.withOpacity(0.2)),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.overlay.withOpacity(0.3),
                        child: Icon(Icons.landscape, color: Colors.white54, size: context.fx(32)),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [theme.overlay.withOpacity(0.85), theme.overlay.withOpacity(0.1)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: context.fx(10),
                      bottom: context.fx(10),
                      right: context.fx(10),
                      child: Text(
                        theme.title,
                        style: TextStyle(
                          fontSize: context.ffs(13),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: context.fx(24)),
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.all(context.fx(16)),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFFFF7ED),
          //     borderRadius: BorderRadius.circular(context.fx(12)),
          //     border: Border.all(color: const Color(0xFFFFDDB3)),
          //   ),
          //   child: Column(
          //     children: [
          //       Text(
          //         '✈  Exclusive deals await you!',
          //         style: TextStyle(
          //           fontSize: context.ffs(15),
          //           fontWeight: FontWeight.w700,
          //           color: const Color(0xFFC2410C),
          //         ),
          //       ),
          //       SizedBox(height: context.fx(6)),
          //       Text(
          //         'Book your first flight or hotel and get up to 20% off. '
          //         'Your perfect holiday is just a tap away!',
          //         textAlign: TextAlign.center,
          //         style: TextStyle(
          //           fontSize: context.ffs(12),
          //           height: 1.5,
          //           color: const Color(0xFF9A3412),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // SizedBox(height: context.fx(16)),
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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(context.fx(32), context.fx(24), context.fx(32), context.fx(80)),
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


String _time(DateTime? d) =>
    d == null ? '' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Parses the already-formatted "17 Oct 2026" shape a couple of the models
/// hand us, since those never survive [DateTime.tryParse].
DateTime? _parseDisplayDate(String? value) {
  final parts = (value ?? '').trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = _months.indexWhere((m) => m.toLowerCase() == parts[1].toLowerCase()) + 1;
  final year = int.tryParse(parts[2]);
  if (day == null || month == 0 || year == null) return null;
  return DateTime(year, month, day);
}

/// When the booking was placed. Each API carries this on a differently named
/// field (and the visa model pre-formats it), so callers pass the candidates
/// in priority order and the first one that parses wins.
DateTime? _bookedOn(List<String?> candidates) {
  for (final candidate in candidates) {
    final parsed = _parse(candidate) ?? _parseDisplayDate(candidate);
    if (parsed != null) return parsed;
  }
  return null;
}

/// Before today (by calendar day) — the trip has ended.
bool _isPast(DateTime? end) => end != null && _day(end).isBefore(_day(DateTime.now()));


TripStatus _status(_Tab tab, {bool processing = false, String? label}) => switch (tab) {
  _Tab.cancelled => TripStatus(TripStatusKind.cancelled, label ?? 'Cancelled'),
  _Tab.past => TripStatus(TripStatusKind.completed, label ?? 'Completed'),
  _Tab.all || _Tab.upcoming => processing
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
    _bookedOn([b.created, b.bookingDate]),
    (context) => TripCardData(
      typeLabel: 'FLIGHT BOOKING',
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
    service: _Service.flight,
    search: _hay([b.pnr, info.airline, info.flightNumber, info.fromCity, info.toCity, info.fromCode, info.toCode]),
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
  return _Trip(
    tab,
    checkIn,
    _bookedOn([h.created, h.bookingDate]),
    null,
    service: _Service.hotel,
    search: _hay([h.hotelName, h.hotelCity, h.roomType]),
    custom: (context) => HotelBookingCard(
      hotel: h,
      status: _status(tab, processing: status.contains('pending'), label: failed ? 'Failed' : null),
      onDetails: () => push(HotelBookingDetailsScreen(booking: h)),
    ),
  );
}

_Trip _transferTrip(BookingEntity t, void Function(Widget) push) {
  final pickup = _parse(t.pickupDatetime) ?? _parse(t.reservationTimestamp);
  final cancelled = t.cancelled || t.status.toLowerCase().contains('cancel');
  final tab = cancelled ? _Tab.cancelled : (_isPast(pickup) ? _Tab.past : _Tab.upcoming);
  return _Trip(
    tab,
    pickup,
    _bookedOn([t.created, t.bookedDate, t.reservationTimestamp]),
    null,
    service: _Service.transfer,
    search: _hay([t.vehicleName, t.providerName, t.confirmationNumber, t.startAddress, t.endAddress, t.destination]),
    custom: (context) => TransferBookingCard(
      vehicleName: t.vehicleName,
      destination: t.destination,
      startAddress: t.startAddress,
      endAddress: t.endAddress,
      imageUrl: t.imageUrl,
      pickupTime: pickup,
      dropoffTime: null,
      passengers: t.applicantCount,
      category: t.category,
      status: _status(tab, processing: t.status.toLowerCase().contains('pending')),
      onDetails: () => push(BookingDetailsScreen(booking: t)),
    ),
  );
}

/// Lower-cased text for the search box.
String _hay(List<String?> parts) => parts.whereType<String>().where((p) => p.isNotEmpty).join(' ').toLowerCase();

/// Which Visa filter an application belongs to. Unpaid applications (no
/// tracker yet) are in none of them and only show under "All".
_VisaGroup _visaGroup(TripItem v) {
  final t = v.tracker;
  if (t.rejected) return _VisaGroup.rejected;
  if (t.approved) return _VisaGroup.approved;
  if (t.started) return _VisaGroup.inProgress;
  return _VisaGroup.other;
}

_Trip _insuranceTrip(InsuranceBookingEntity i, void Function(Widget) push) {
  final start = _parse(i.startDate);
  final end = _parse(i.endDate);
  final status = i.status.toLowerCase();
  final cancelled = status.contains('cancel');
  final tab = cancelled ? _Tab.cancelled : (_isPast(end ?? start) ? _Tab.past : _Tab.upcoming);
  return _Trip(
    tab,
    start,
    _bookedOn([i.created]),
    null,
    service: _Service.insurance,
    search: _hay([i.policyNumber, i.planName, i.providerName, i.destination, i.holderName]),
    custom: (context) => _InsuranceBookingCard(
      planName: i.planName,
      providerName: i.providerName,
      destination: i.destination,
      policyNumber: i.policyNumber,
      startDate: start,
      endDate: end,
      travellers: i.travellers,
      amount: i.totalAmount,
      currency: i.currency,
      status: _status(tab, processing: status.contains('pending')),
      onDetails: () => push(InsuranceBookingDetailsScreen(booking: i)),
    ),
  );
}

_Trip _visaTrip(TripItem v) {
  final onward = _parse(v.onwardDate);
  final back = _parse(v.returnDate);
  final status = v.status.toLowerCase();
  final group = _visaGroup(v);
  final tab = status.contains('cancel')
      ? _Tab.cancelled
      : ((group == _VisaGroup.rejected || _isPast(back ?? onward)) ? _Tab.past : _Tab.upcoming);

  return _Trip(
    tab,
    onward,
    _bookedOn([v.bookedDate]),
    null,
    service: _Service.visa,
    visaGroup: group,
    search: _hay([v.bookingId, v.destination, v.type, ...v.travellerNames]),
    custom: (context) => VisaBookingCard(
      visa: v,
      onDetails: () => VisaBookingSummaryScreen.open(context, v),
    ),
  );
}

// ---------------------------------------------------------------------------
// Insurance booking card
// ---------------------------------------------------------------------------

String _fmtInsDate(DateTime? dt) {
  if (dt == null) return '';
  final d = dt.toLocal();
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

class _InsuranceBookingCard extends StatelessWidget {
  final String planName;
  final String providerName;
  final String destination;
  final String policyNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final int travellers;
  final String amount;
  final String currency;
  final TripStatus status;
  final VoidCallback onDetails;

  const _InsuranceBookingCard({
    required this.planName,
    required this.providerName,
    required this.destination,
    required this.policyNumber,
    required this.startDate,
    required this.endDate,
    required this.travellers,
    required this.amount,
    required this.currency,
    required this.status,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetails,
      child: Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4.95,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Insurance label
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: context.ffs(11),
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.shield_outlined, size: context.fx(16), color: _kMuted),
              SizedBox(width: context.w(4)),
              Text(
                'Insurance',
                style: TextStyle(fontSize: context.ffs(11), color: _kMuted),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),

          // Plan name
          Text(
            planName.isNotEmpty ? planName : 'Insurance Policy',
            style: TextStyle(
              fontSize: context.ffs(15),
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          if (providerName.isNotEmpty) ...[
            SizedBox(height: context.h(2)),
            Text(
              providerName,
              style: TextStyle(fontSize: context.ffs(12), color: _kMuted),
            ),
          ],
          SizedBox(height: context.h(12)),

          // Destination + Travellers
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: context.fx(14), color: _kMuted),
              SizedBox(width: context.w(4)),
              Text(
                destination.isNotEmpty ? destination : '—',
                style: TextStyle(fontSize: context.ffs(12), color: _kInk),
              ),
              SizedBox(width: context.w(16)),
              Icon(Icons.people_outline, size: context.fx(14), color: _kMuted),
              SizedBox(width: context.w(4)),
              Text(
                '$travellers Traveller${travellers == 1 ? '' : 's'}',
                style: TextStyle(fontSize: context.ffs(12), color: _kInk),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),

          const TripDashedLine(color: Color(0xFFCCCCCC)),
          SizedBox(height: context.h(12)),

          // Dates + Amount
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coverage Period', style: TextStyle(fontSize: context.ffs(10), color: _kMuted)),
                    SizedBox(height: context.h(2)),
                    Text(
                      '${_fmtInsDate(startDate)} – ${_fmtInsDate(endDate)}',
                      style: TextStyle(fontSize: context.ffs(12), fontWeight: FontWeight.w500, color: _kInk),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Premium', style: TextStyle(fontSize: context.ffs(10), color: _kMuted)),
                  SizedBox(height: context.h(2)),
                  Text(
                    '$currency $amount',
                    style: TextStyle(fontSize: context.ffs(13), fontWeight: FontWeight.w600, color: _kInk),
                  ),
                ],
              ),
            ],
          ),

          if (policyNumber.isNotEmpty) ...[
            SizedBox(height: context.h(8)),
            Text(
              'Policy: $policyNumber',
              style: TextStyle(fontSize: context.ffs(10), color: _kMuted),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
