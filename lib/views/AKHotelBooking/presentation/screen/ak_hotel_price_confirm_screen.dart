import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../core/error/data_state.dart';
import '../../../AKHotelCreateItinerary/domain/entity/AKHotelCreateItinerary_entity.dart';
import '../../../AKHotelCreateItinerary/domain/usecase/AKHotelCreateItinerary_usecase.dart';
import '../../../AKHotelDetailContent/domain/entity/AKHotelDetailContent_entity.dart';
import '../../../AKHotelPrice/domain/entity/AKHotelPrice_entity.dart';
import '../../../AKHotelPrice/domain/usecase/AKHotelPrice_usecase.dart';
import '../../../AKHotelRooms/domain/entity/AKHotelRooms_entity.dart';
import '../../../AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../../../Profile/domain/entities/ProfileEntity.dart';
import '../../../Profile/domain/usecase/get_profile_usecase.dart';
import '../../../login/presentation/screen/login.dart';
import '../widgets/ak_hotel_add_guest_sheet.dart';
import 'ak_hotel_payment_screen.dart';

class AkHotelPriceConfirmScreen extends StatefulWidget {
  final String searchId;
  final String searchTracingKey;
  final String hotelId;
  final String hotelName;
  /// MM/DD/YYYY, as threaded from Search Init.
  final String checkIn;
  final String checkOut;
  final String recommendationId;
  final AkHotelRoomGroupEntity roomGroup;
  final String nationality;
  /// The exact per-room adults/children/childAges the user searched with —
  /// see the class doc for why this, not [roomGroup].occupancies, drives the
  /// guest forms and the itinerary's Rooms[].
  final List<AkHotelSearchInitRoomEntity> rooms;
  /// The hotel's Content (star rating, address, gallery) already fetched by
  /// [AkHotelDetailScreen] — optional and display-only (star rating, hero
  /// image, address line on the summary card); null just hides those bits
  /// rather than fabricating them.
  final AkHotelDetailContentEntity? content;

  const AkHotelPriceConfirmScreen({
    super.key,
    required this.searchId,
    required this.searchTracingKey,
    required this.hotelId,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.recommendationId,
    required this.roomGroup,
    required this.nationality,
    required this.rooms,
    this.content,
  });

  @override
  State<AkHotelPriceConfirmScreen> createState() => _AkHotelPriceConfirmScreenState();
}

class _AkHotelPriceConfirmScreenState extends State<AkHotelPriceConfirmScreen> {
  static const _blue = AppColors.AppBlue;
  static const _navy = AppColors.black;
  static const _pageBg = AppColors.white;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;
  static const _accent = AppColors.OrangeColor;

  final _formKey = GlobalKey<FormState>();

  /// One entry per guest (adults first, then children, per occupancy). Built
  /// once in [initState] from the occupancy data so nothing rebuilds while the
  /// user types.
  final List<_GuestInput> _guests = [];

  bool _pricing = true;
  String? _priceError;
  AkHotelPricedRoomGroupEntity? _priced;
  /// Every room-group the Price API returned, in order. For a multi-room
  /// booking the vendor returns one entry per physical room — each with its
  /// own [AkHotelPricedRoomGroupEntity.occupancyId], which is the ID
  /// CreateItinerary's GuestCode must key off (see [_buildGuestCode]).
  /// [_priced] stays the first entry, used wherever the screen only needs
  /// "the" room (display header, loading gate) or as the fallback when this
  /// list has fewer entries than [_occupancies].
  List<AkHotelPricedRoomGroupEntity> _pricedRooms = [];

  bool _submitting = false;
  String? _submitError;

  /// Cosmetic only — matches the agreement checkbox in the redesigned
  /// layout but does not gate [_confirmBooking]; the booking flow's actual
  /// terms are unchanged.
  bool _agreedToTerms = false;

  /// "I am booking for: Myself / Someone Else" — Myself pre-fills the lead
  /// guest's fields from the signed-in user's own [ProfileEntity] (real
  /// account data, fetched once and cached in [_profile]); Someone Else just
  /// clears them back out for manual entry.
  bool _bookingForSelf = true;
  ProfileEntity? _profile;
  bool _profileLoading = false;

  /// Display-only selection for the phone code dropdown — cosmetic, see
  /// [_labeledPhoneField].
  String _leadPhoneCode = '+91';

  bool get _isLoggedIn => sl<PreferencesManager>().isLoggedIn();

  /// The searched party, one entry per PHYSICAL room — built straight from
  /// [widget.rooms] (what the user actually picked on the search form), NOT
  /// from [roomGroup].occupancies (the vendor's echo, whose collapsing/
  /// shape proved unreliable to reverse-engineer — see the class doc).
  /// Falls back to a single default adult only if the search screen
  /// somehow didn't pass any rooms (defensive; shouldn't happen in
  /// practice since every entry point into this screen supplies it).
  List<AkHotelOccupancyEntity> get _occupancies {
    if (widget.rooms.isEmpty) {
      return const [AkHotelOccupancyEntity(occupancyId: 1, numOfAdults: 1, numOfChildren: 0, childAges: [])];
    }
    return [
      for (var i = 0; i < widget.rooms.length; i++)
        AkHotelOccupancyEntity(
          occupancyId: i + 1,
          numOfAdults: widget.rooms[i].adults,
          numOfChildren: widget.rooms[i].children,
          childAges: widget.rooms[i].childAges,
        ),
    ];
  }

  int get _adultCount => _guests.where((g) => g.paxType == 'A').length;
  int get _childCount => _guests.where((g) => g.paxType == 'C').length;

  /// Sum of every priced room's [AkHotelPricedRoomGroupEntity.totalRate].
  /// For a single room this equals `_priced.totalRate` exactly (list has one
  /// entry) — for multiple rooms it's the real payable total instead of just
  /// the first room's rate, which is also what's sent as CreateItinerary's
  /// NetAmount (a mismatch there is a plausible reason a multi-room
  /// itinerary gets rejected).
  double get _totalPayable => _pricedRooms.isEmpty
      ? (_priced?.totalRate ?? 0)
      : _pricedRooms.fold(0.0, (sum, r) => sum + r.totalRate);

  @override
  void initState() {
    super.initState();
    _buildGuests();
    _loadPrice();
    // "Myself" is the default selection, so pre-fill the lead guest from the
    // real signed-in profile as soon as the form exists — only when actually
    // logged in, so there is nothing to fetch otherwise.
    if (_isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyBookingForSelf(true));
    }
  }

  @override
  void dispose() {
    for (final g in _guests) {
      g.dispose();
    }
    super.dispose();
  }

  /// Materialises one [_GuestInput] per adult and per child across every
  /// occupancy. The first adult encountered becomes the lead (contact) guest.
  /// Each guest is tagged with its room's 1-based POSITION in [_occupancies]
  /// (not the vendor's occupancyId — see the class doc for why).
  void _buildGuests() {
    var leadAssigned = false;
    for (var r = 0; r < _occupancies.length; r++) {
      final occ = _occupancies[r];
      final roomIndex = r + 1;
      for (var a = 0; a < occ.numOfAdults; a++) {
        final isLead = !leadAssigned;
        if (isLead) leadAssigned = true;
        _guests.add(_GuestInput(
          occupancyId: roomIndex,
          paxType: 'A',
          isLead: isLead,
          title: 'Mr',
          age: 25,
        ));
      }
      for (var c = 0; c < occ.numOfChildren; c++) {
        _guests.add(_GuestInput(
          occupancyId: roomIndex,
          paxType: 'C',
          isLead: false,
          title: 'Mstr',
          age: c < occ.childAges.length ? occ.childAges[c] : 5,
        ));
      }
    }
    // No adults anywhere (occupancies empty or, pathologically, child-only):
    // guarantee a lead adult so the booking contact can still be collected —
    // mirrors the previous single-adult default.
    if (!leadAssigned) {
      _guests.insert(
        0,
        _GuestInput(occupancyId: 1, paxType: 'A', isLead: true, title: 'Mr', age: 25),
      );
    }
  }

  /// Applies the "I am booking for" toggle to the lead guest's fields.
  /// [self] = true fetches (once, then cached in [_profile]) and fills in
  /// the signed-in user's own name/mobile/email; false clears those fields
  /// back out for manual entry. No-ops quietly when not logged in — there is
  /// no profile to fetch, and the existing login prompt already covers that.
  Future<void> _applyBookingForSelf(bool self) async {
    if (!mounted) return;
    setState(() => _bookingForSelf = self);
    final lead = _guests.isEmpty ? null : _guests.firstWhere((g) => g.isLead, orElse: () => _guests.first);
    if (lead == null) return;

    if (!self) {
      lead.firstName.clear();
      lead.lastName.clear();
      lead.mobile?.clear();
      lead.email?.clear();
      setState(() {});
      return;
    }

    if (!_isLoggedIn) return;

    if (_profile == null && !_profileLoading) {
      setState(() => _profileLoading = true);
      final result = await sl<GetProfileUseCase>().call();
      if (!mounted) return;
      if (result is DataSuccess<ProfileEntity>) {
        _profile = result.data;
      }
      setState(() => _profileLoading = false);
    }

    final profile = _profile;
    if (profile == null || !mounted) return;
    setState(() {
      if (_titleItemsFor('A').contains(profile.title)) lead.title = profile.title;
      lead.firstName.text = profile.firstName;
      lead.lastName.text = profile.lastName;
      lead.mobile?.text = profile.phoneNumber;
      lead.email?.text = profile.email ?? '';
    });
  }

  Future<void> _loadPrice() async {
    setState(() {
      _pricing = true;
      _priceError = null;
    });

    final result = await sl<AkHotelPriceUseCase>().call(
      AkHotelPriceRequestEntity(
        searchId: widget.searchId,
        hotelId: widget.hotelId,
        priceProvider: widget.roomGroup.providerName,
        recommendationId: widget.recommendationId,
        searchTracingKey: widget.searchTracingKey,
      ),
    );

    if (!mounted) return;

    if (result is DataSuccess<AkHotelPriceEntity> && result.data!.roomGroups.isNotEmpty) {
      setState(() {
        _pricedRooms = result.data!.roomGroups;
        _priced = _pricedRooms.first;
        _pricing = false;
      });
    } else {
      setState(() {
        _pricing = false;
        _priceError = 'Could not confirm the live price for this room. Please go back and try again.';
      });
    }
  }

  /// Occupancy encoding for one room, per Akbar's documented CreateItinerary
  /// spec: `|<OccupancyID>|<count>:<A|C>:<age1>:<age2>:…|` per pax group,
  /// ages always in the same order Pricing returned them, adults always at
  /// age 25. [occupancyId] must be the vendor's own OccupancyID from the
  /// Price response (`RoomGroup -> Room -> Occupancy -> OccupancyID`), not
  /// an arbitrary room index — using the room's 1-based search position
  /// instead of the real ID is what broke multi-room bookings (single-room
  /// bookings happened to still work since the vendor's own OccupancyID for
  /// one room is 1, same as the position).
  ///   1 adult                     -> `|1|1:A:25|`
  ///   2 adults + 2 children(10,6) -> `|1|2:A:25:25|2:C:10:6|`
  ///   1 adult + 2 children(3,7)   -> `|1|1:A:25|2:C:3:7|`
  String _buildGuestCode(int occupancyId, List<_GuestInput> guests) {
    final buffer = StringBuffer('|$occupancyId|');
    final adults = guests.where((g) => g.paxType == 'A').length;
    if (adults > 0) {
      buffer.write('$adults:A:${List.filled(adults, '25').join(':')}|');
    }
    final childAges = guests.where((g) => g.paxType == 'C').map((g) => g.age).toList();
    if (childAges.isNotEmpty) {
      buffer.write('${childAges.length}:C:${childAges.join(':')}|');
    }
    return buffer.toString();
  }

  /// Same transparent-overlay login popup used elsewhere in the app (e.g.
  /// the transport booking flow) — a dimmed, dismissible dialog rather than
  /// a full-screen page push, so the booking screen stays visible behind
  /// it. Deliberately local to this screen: [LoginSignupScreen] itself is
  /// untouched, so login triggered from anywhere else in the app is
  /// unaffected.
  void _showLoginPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Login',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const LoginSignupScreen(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    ).then((_) {
      // Refresh so the login prompt/button reflect the now-logged-in state.
      if (mounted) setState(() {});
    });
  }

  Future<void> _confirmBooking() async {
    if (!_isLoggedIn) {
      _showLoginPopup();
      return;
    }
    final priced = _priced;
    if (priced == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final lead = _guests.firstWhere((g) => g.isLead, orElse: () => _guests.first);
    final leadEmail = lead.email?.text.trim() ?? '';

    // One Rooms[] entry per occupancy; each carries its own guests + guest
    // code. When Pricing returned one room-group per physical room (the
    // normal multi-room case) each entry uses THAT room's own ids and real
    // OccupancyID; if it returned fewer entries than rooms searched, the
    // extra rooms fall back to the first (only) priced entry + the room's
    // 1-based search position, same as before this was fixed.
    final rooms = <AkHotelItineraryRoomEntity>[];
    // GuestID must be unique across the WHOLE itinerary, not just within a
    // room — resetting to 0 per room sent duplicate GuestIDs (0,1,2,3 in
    // every room) for multi-room bookings. For a single room this counter
    // still starts at 0 and runs consecutively, so the single-room request
    // is unaffected.
    var guestCounter = 0;
    for (var r = 0; r < _occupancies.length; r++) {
      final roomIndex = r + 1;
      final occGuests = _guests.where((g) => g.occupancyId == roomIndex).toList();
      if (occGuests.isEmpty) continue;
      final roomPriced = r < _pricedRooms.length ? _pricedRooms[r] : priced;
      final occupancyId = r < _pricedRooms.length ? roomPriced.occupancyId : roomIndex;
      rooms.add(AkHotelItineraryRoomEntity(
        roomId: roomPriced.roomId,
        roomGroupId: roomPriced.id,
        supplierName: roomPriced.providerName,
        guestCode: _buildGuestCode(occupancyId, occGuests),
        guests: [
          for (final guest in occGuests)
            AkHotelGuestEntity(
              guestId: '${guestCounter++}',
              title: guest.title,
              firstName: guest.firstName.text.trim(),
              lastName: guest.lastName.text.trim(),
              paxType: guest.paxType,
              email: leadEmail,
            ),
        ],
      ));
    }

    final checkInIso = _toIsoDate(widget.checkIn);
    final checkOutIso = _toIsoDate(widget.checkOut);

    final result = await sl<AkHotelCreateItineraryUseCase>().call(
      AkHotelCreateItineraryRequestEntity(
        searchId: widget.searchId,
        searchTracingKey: widget.searchTracingKey,
        hotelCode: widget.hotelId,
        recommendationId: widget.recommendationId,
        // Sum across every room, not just the first — for a multi-room
        // booking `priced.totalRate` alone was only one room's rate, which
        // would undercharge/mismatch what the vendor computed for the whole
        // itinerary.
        netAmount: _totalPayable.toString(),
        checkInDate: checkInIso,
        checkOutDate: checkOutIso,
        contactInfo: AkHotelContactInfoEntity(
          title: lead.title,
          fName: lead.firstName.text.trim(),
          lName: lead.lastName.text.trim(),
          mobile: lead.mobile?.text.trim() ?? '',
          email: leadEmail,
          countryCode: widget.nationality,
          isGuest: false,
        ),
        rooms: rooms,
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result is DataSuccess<AkHotelCreateItineraryEntity> && result.data!.transactionId.isNotEmpty) {
      final leadName = '${lead.firstName.text.trim()} ${lead.lastName.text.trim()}'.trim();
      // Title is the only gender-adjacent field this form collects — "Mr" is
      // the one clearly-male option, everything else (Mrs/Ms/child titles)
      // maps to "F", same inference the guest form itself implies.
      final genderLetter = lead.title == 'Mr' ? 'M' : 'F';
      final paymentGuestsSummary = [
        '${leadName.isEmpty ? 'Guest' : leadName}($genderLetter)',
        '${_occupancies.length} Room${_occupancies.length == 1 ? '' : 's'}',
        '$_adultCount Adult${_adultCount == 1 ? '' : 's'}',
        if (_childCount > 0) '$_childCount Child${_childCount == 1 ? '' : 'ren'}',
      ].join(', ');

      final content = widget.content;
      final leadPhone = (lead.mobile?.text.trim() ?? '').isEmpty
          ? ''
          : '$_leadPhoneCode ${lead.mobile!.text.trim()}';
      // Sum of every priced room's baseRate — the pre-tax figure the
      // confirmation screen's "Base Fare" line shows; taxes/fees there are
      // derived as (amount actually paid − this), never fabricated.
      final baseFare = _pricedRooms.isEmpty ? (priced.baseRate) : _pricedRooms.fold(0.0, (sum, r) => sum + r.baseRate);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AkHotelPaymentScreen(
            transactionId: result.data!.transactionId,
            netAmount: result.data!.netAmount,
            hotelName: widget.hotelName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            searchTracingKey: widget.searchTracingKey,
            hotelImage: _summaryImage,
            checkInTime: content?.checkinBeginTime ?? '',
            checkOutTime: content?.checkoutTime ?? '',
            guestsSummary: paymentGuestsSummary,
            hotelAddress: content?.addressLine1 ?? '',
            hotelCity: content?.city ?? '',
            hotelCountry: content?.country ?? '',
            starRating: (content?.starRating ?? 0).round(),
            reviewRating: content?.reviewRating ?? 0,
            roomType: widget.roomGroup.roomName,
            mealPlan: widget.roomGroup.boardBasisDescription,
            roomsCount: _occupancies.length,
            adultsCount: _adultCount,
            childrenCount: _childCount,
            baseFare: baseFare,
            leadGuestName: leadName.isEmpty ? 'Guest' : leadName,
            leadGuestEmail: leadEmail,
            leadGuestPhone: leadPhone,
          ),
        ),
      );
    } else {
      setState(() => _submitError = _extractItineraryError(result));
    }
  }

  /// Surfaces Akbar's actual rejection reason (e.g. "Akbar Hotel Create
  /// Itinerary failed: ['Bad Request']") when the backend forwards one,
  /// instead of always showing a generic message — this is the only signal
  /// available to diagnose which request shape the vendor rejected, since
  /// their multi-guest GuestCode format isn't documented (see
  /// [_buildGuestCode]).
  String _extractItineraryError(DataState<AkHotelCreateItineraryEntity> result) {
    final data = result.error?.response?.data;
    if (data is Map && data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
      return data['error'] as String;
    }
    return 'Could not create the booking itinerary. Please try again.';
  }

  String _toIsoDate(String mmddyyyy) {
    try {
      final parsed = DateFormat('MM/dd/yyyy').parseStrict(mmddyyyy);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return mmddyyyy;
    }
  }

  String _prettyDate(String mmddyyyy) {
    try {
      return DateFormat('dd MMM yyyy, EEE').format(DateFormat('MM/dd/yyyy').parseStrict(mmddyyyy));
    } catch (_) {
      return mmddyyyy;
    }
  }

  /// Nights between [widget.checkIn] and [widget.checkOut] — same
  /// parse-and-diff the room rate details screen uses.
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

  String get _guestsSummary {
    final childAges = <int>[for (final occ in _occupancies) ...occ.childAges];
    final guestParts = <String>['$_adultCount Adult${_adultCount == 1 ? '' : 's'}'];
    if (_childCount > 0) {
      final agesText = childAges.isEmpty ? '' : ' (${childAges.map((a) => '${a}y').join(', ')})';
      guestParts.add('$_childCount Child${_childCount == 1 ? '' : 'ren'}$agesText');
    }
    final roomsText = '${_occupancies.length} Room${_occupancies.length == 1 ? '' : 's'}';
    return '${guestParts.join(', ')} • $roomsText';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _pricing
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _priceError != null
              ? _buildError(_priceError!, onRetry: _loadPrice)
              : Column(
                  children: [
                    Expanded(child: _buildScrollBody(context)),
                    _buildBottomBar(context),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Review Booking',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w600, fontSize: context.fs(16)),
      ),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 4,
      scrolledUnderElevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: _navy),
    );
  }

  Widget _buildScrollBody(BuildContext context) {
    return SingleChildScrollView(
      physics: context.scrollPhysics,
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.h(20)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            SizedBox(height: context.gapLarge),
            if (_priced?.cancellationRules.isNotEmpty == true) ...[
              _buildCancellationCard(context),
              SizedBox(height: context.gapLarge),
            ],
            if (!_isLoggedIn) _buildLoginPrompt(context),
            _sectionHeader(context, 'Guest Details', 'Enter each guest\'s name as on their government ID'),
            SizedBox(height: context.gapMedium),
            _buildBookingForRow(context),
            SizedBox(height: context.gapMedium),
            ..._buildGuestCards(context),
            SizedBox(height: context.gapSmall),
            _buildAddOtherGuestButton(context),
            SizedBox(height: context.gapLarge),
            _buildTermsRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: context.horizontalPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: context.iconLarge * 2, color: Colors.grey.shade400),
            SizedBox(height: context.gapLarge),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: context.gapLarge),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  /// Hero image for the summary card: the hotel's own Content photo when
  /// [widget.content] was supplied, falling back to this room's own photos
  /// (same fallback order the room rate details screen uses) — empty only
  /// when neither source has one, in which case a placeholder icon shows.
  String get _summaryImage {
    final hero = widget.content?.heroImage ?? '';
    if (hero.isNotEmpty) return hero;
    if (widget.roomGroup.images.isNotEmpty) return widget.roomGroup.images.first;
    final contentImages = widget.content?.images ?? const <String>[];
    return contentImages.isNotEmpty ? contentImages.first : '';
  }

  Widget _buildSummaryCard(BuildContext context) {
    final content = widget.content;
    final starRating = (content?.starRating ?? 0).round().clamp(0, 5);
    final addressParts = <String>[
      if (content?.addressLine1.isNotEmpty == true) content!.addressLine1,
      if (content?.city.isNotEmpty == true) content!.city,
    ];
    final image = _summaryImage;

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hotelName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: _navy),
                    ),
                    if (starRating > 0) ...[
                      SizedBox(height: context.h(5)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 5; i++)
                            Icon(
                              i < starRating ? Icons.star_rounded : Icons.star_border_rounded,
                              size: context.w(14),
                              // Filled stars up to the real rating are gold;
                              // the remaining ones are a plain grey outline
                              // instead of a fainter gold, so an unfilled
                              // star doesn't read as "half-lit".
                              color: i < starRating ? const Color(0xFFFFB020) : _border,
                            ),
                        ],
                      ),
                    ],
                    SizedBox(height: context.h(5)),
                    Text(
                      addressParts.isNotEmpty
                          ? addressParts.join(', ')
                          : (widget.roomGroup.roomName.isEmpty ? 'Room' : widget.roomGroup.roomName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(12), color: _muted),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(10)),
              ClipRRect(
                borderRadius: BorderRadius.circular(context.r(10)),
                child: image.isEmpty
                    ? Container(
                        width: context.w(76),
                        height: context.w(76),
                        color: _pageBg,
                        child: Icon(Icons.apartment_rounded, color: _muted, size: context.w(24)),
                      )
                    : CachedNetworkImage(
                        imageUrl: image,
                        cacheManager: FastNetworkImageCacheManager.instance,
                        width: context.w(76),
                        height: context.w(76),
                        fit: BoxFit.cover,
                        memCacheWidth: 220,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (_, __) => Container(color: _pageBg),
                        errorWidget: (_, __, ___) => Container(
                          color: _pageBg,
                          child: Icon(Icons.apartment_rounded, color: _muted, size: context.w(24)),
                        ),
                      ),
              ),
            ],
          ),
          Divider(height: context.h(22), color: _border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _summaryStat(context, 'CHECK-IN', _prettyDate(widget.checkIn))),
              _nightsPill(context),
              Expanded(child: _summaryStat(context, 'CHECK-OUT', _prettyDate(widget.checkOut), alignEnd: true)),
            ],
          ),
          Divider(height: context.h(22), color: _border),
          _summaryStat(context, 'GUESTS & ROOMS', _guestsSummary, maxLines: 2),
        ],
      ),
    );
  }

  Widget _summaryStat(BuildContext context, String label, String value, {bool alignEnd = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(9), color: _muted, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
        SizedBox(height: context.h(3)),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(fontSize: context.fs(12.5), color: _navy, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  /// The small "N NIGHT(S)" pill between check-in/check-out, derived from
  /// the real stay length ([_nights]) rather than a fixed label.
  Widget _nightsPill(BuildContext context) {
    final nights = _nights;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: context.w(26), height: 2, color: _accent),
          SizedBox(height: context.h(5)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
            decoration: BoxDecoration(
              color: _pageBg,
              borderRadius: BorderRadius.circular(context.r(20)),
              border: Border.all(color: _border),
            ),
            child: Text(
              '$nights NIGHT${nights == 1 ? '' : 'S'}',
              style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.w800, color: _muted, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_outlined, size: context.w(16), color: _navy),
              SizedBox(width: context.w(8)),
              Flexible(
                child: Text(
                  'Cancellation Schedule',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w800, color: _navy),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          for (final rule in _priced!.cancellationRules)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(6)),
              child: Text(
                rule.value == 0
                    ? 'Free cancellation until ${rule.end}'
                    : '${rule.valueType == 'Percentage' ? '${rule.value.toStringAsFixed(0)}%' : rule.value.toStringAsFixed(0)} charge from ${rule.start} to ${rule.end}',
                style: TextStyle(fontSize: context.fs(12), color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapLarge),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              'Hotel bookings require you to be logged in.',
              style: TextStyle(fontSize: context.fs(12), color: const Color(0xFF9A3412), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// "I am booking for: Myself / Someone Else" — sits above the guest cards
  /// and drives [_applyBookingForSelf]. Hidden fields/data are never
  /// fabricated: "Myself" pulls the real signed-in profile, nothing else.
  Widget _buildBookingForRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Text('I am booking for', style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: _navy)),
          SizedBox(width: context.w(18)),
          _bookingForOption(context, 'Myself', true),
          SizedBox(width: context.w(18)),
          _bookingForOption(context, 'Someone Else', false),
          if (_profileLoading) ...[
            SizedBox(width: context.w(10)),
            SizedBox(width: context.w(14), height: context.w(14), child: const CircularProgressIndicator(strokeWidth: 2, color: _blue)),
          ],
        ],
      ),
    );
  }

  Widget _bookingForOption(BuildContext context, String label, bool value) {
    final selected = _bookingForSelf == value;
    return InkWell(
      onTap: () => _applyBookingForSelf(value),
      borderRadius: BorderRadius.circular(context.r(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            size: context.w(18),
            color: selected ? _accent : _border,
          ),
          SizedBox(width: context.w(6)),
          Text(label, style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _navy)),
        ],
      ),
    );
  }

  /// Opens [AkHotelAddGuestSheet] (a real saved-guest book, backed by the
  /// same traveller API the Dashboard uses) and drops any guests the
  /// traveller ticked into the next empty guest slot of the matching
  /// paxType. Does not add headcount — a pick with no empty slot left is
  /// simply skipped, since the room's occupancy is fixed by what was priced.
  Widget _buildAddOtherGuestButton(BuildContext context) {
    return InkWell(
      onTap: _openAddGuestSheet,
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1_rounded, size: context.w(18), color: _accent),
            SizedBox(width: context.w(8)),
            Text('Add Other Guest', style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w800, color: _accent)),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddGuestSheet() async {
    final picks = await AkHotelAddGuestSheet.show(context);
    if (picks == null || picks.isEmpty || !mounted) return;

    var applied = 0;
    for (final pick in picks) {
      final paxType = pick.isChild ? 'C' : 'A';
      _GuestInput? slot;
      for (final g in _guests) {
        if (g.paxType == paxType && g.firstName.text.trim().isEmpty) {
          slot = g;
          break;
        }
      }
      if (slot == null) continue;
      if (_titleItemsFor(paxType).contains(pick.title)) slot.title = pick.title;
      slot.firstName.text = pick.firstName;
      slot.lastName.text = pick.lastName;
      applied++;
    }

    setState(() {});
    if (applied < picks.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Some guests had no empty slot left in this booking and were not added.')),
      );
    }
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: _navy)),
        SizedBox(height: context.h(2)),
        Text(subtitle, style: TextStyle(fontSize: context.fs(11.5), color: _muted)),
      ],
    );
  }

  /// Groups guest cards by room (position in [_occupancies]) so a multi-room
  /// booking clearly shows which guests belong to which room. Adult/Child
  /// numbering restarts per room. For a single room this renders identically
  /// to before (no room header, one continuous numbering run).
  List<Widget> _buildGuestCards(BuildContext context) {
    final cards = <Widget>[];
    final multiRoom = _occupancies.length > 1;
    for (var r = 0; r < _occupancies.length; r++) {
      final roomIndex = r + 1;
      final roomGuests = _guests.where((g) => g.occupancyId == roomIndex).toList();
      if (roomGuests.isEmpty) continue;
      if (multiRoom) {
        if (cards.isNotEmpty) cards.add(SizedBox(height: context.gapLarge));
        cards.add(_roomHeader(context, roomIndex));
        cards.add(SizedBox(height: context.gapMedium));
      }
      var adultNo = 0;
      var childNo = 0;
      for (var i = 0; i < roomGuests.length; i++) {
        final g = roomGuests[i];
        final String label;
        if (g.paxType == 'A') {
          adultNo++;
          label = 'Adult $adultNo';
        } else {
          childNo++;
          label = 'Child $childNo';
        }
        cards.add(_buildGuestCard(context, g, label));
        if (i != roomGuests.length - 1) cards.add(SizedBox(height: context.gapMedium));
      }
    }
    return cards;
  }

  Widget _roomHeader(BuildContext context, int roomIndex) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(5)),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: Text(
            'Room $roomIndex',
            style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        SizedBox(width: context.w(8)),
        Expanded(child: Divider(color: _border, height: 1)),
      ],
    );
  }

  Widget _buildGuestCard(BuildContext context, _GuestInput g, String label) {
    final isChild = g.paxType == 'C';
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(34),
                height: context.w(34),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Icon(
                  isChild ? Icons.child_care_rounded : Icons.person_outline_rounded,
                  color: _blue,
                  size: context.w(19),
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w800, color: _navy)),
              ),
              if (g.isLead) _tagChip(context, 'Lead guest', _accent),
              if (isChild) _tagChip(context, 'Age ${g.age}', _muted),
            ],
          ),
          SizedBox(height: context.gapMedium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: context.w(76),
                child: _labeledDropdown(
                  context,
                  'Title',
                  g.title,
                  _titleItemsFor(g.paxType),
                  (v) => setState(() => g.title = v ?? g.title),
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _labeledField(
                  context,
                  'First Name',
                  controller: g.firstName,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _labeledField(
                  context,
                  'Last Name',
                  controller: g.lastName,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          if (g.isLead) ...[
            SizedBox(height: context.gapMedium),
            _labeledField(
              context,
              'Email ID',
              controller: g.email!,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.mail_outline_rounded,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            SizedBox(height: context.gapMedium),
            _labeledPhoneField(
              context,
              controller: g.mobile!,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: context.h(8)),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: context.w(13), color: _muted),
                SizedBox(width: context.w(6)),
                Expanded(
                  child: Text(
                    'Booking confirmation and voucher will be sent here.',
                    style: TextStyle(fontSize: context.fs(11), color: _muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagChip(BuildContext context, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: context.fs(10), color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  List<String> _titleItemsFor(String paxType) =>
      paxType == 'C' ? const ['Mstr', 'Miss'] : const ['Mr', 'Mrs', 'Ms'];

  /// Floating-label decoration: the label sits inline until the field is
  /// focused or filled, then floats above it — same Material behaviour as
  /// the rest of the app's forms, instead of a separate static caption.
  InputDecoration _boxedDecoration(BuildContext context, {required String label, IconData? icon}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.r(10)),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      isDense: true,
      filled: true,
      fillColor: _pageBg,
      prefixIcon: icon != null ? Icon(icon, size: context.w(18), color: _muted) : null,
      labelStyle: TextStyle(color: _muted, fontSize: context.fs(12.5)),
      floatingLabelStyle: TextStyle(color: _blue, fontSize: context.fs(12)),
      contentPadding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(14)),
      border: border(_border),
      enabledBorder: border(_border),
      focusedBorder: border(_blue),
      errorBorder: border(Colors.red.shade300),
      focusedErrorBorder: border(Colors.red.shade400),
    );
  }

  Widget _labeledField(
    BuildContext context,
    String label, {
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyle(fontSize: context.fs(13), color: _navy, fontWeight: FontWeight.w600),
      decoration: _boxedDecoration(context, label: label, icon: icon),
      validator: validator,
    );
  }

  Widget _labeledDropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: TextStyle(fontSize: context.fs(13), color: _navy, fontWeight: FontWeight.w600),
      decoration: _boxedDecoration(context, label: label),
      items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: onChanged,
    );
  }

  /// Mobile number field as two fully separate boxed fields — a small code
  /// dropdown (display-only, like [ProfilePhoneField] elsewhere in the app;
  /// [AkHotelContactInfoEntity.countryCode] is always [widget.nationality],
  /// not this) and the number itself with its own floating label — instead
  /// of one merged box.
  Widget _labeledPhoneField(
    BuildContext context, {
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.w(92),
          child: DropdownButtonFormField<String>(
            value: _leadPhoneCode,
            isExpanded: true,
            style: TextStyle(fontSize: context.fs(13), color: _navy, fontWeight: FontWeight.w700),
            decoration: _boxedDecoration(context, label: 'Code'),
            items: const [
              DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
              DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
              DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
            ],
            onChanged: (v) => setState(() => _leadPhoneCode = v ?? _leadPhoneCode),
          ),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: _labeledField(
            context,
            'Mobile Number',
            controller: controller,
            keyboardType: TextInputType.phone,
            validator: validator,
          ),
        ),
      ],
    );
  }

  /// Static booking-agreement disclaimer, same non-interactive style the
  /// login screen uses for its own Terms/Agreement copy — display only, does
  /// not gate [_confirmBooking].
  Widget _buildTermsRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.w(20),
          height: context.w(20),
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: _accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: context.h(2)),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: context.fs(11), color: _muted, height: 1.4),
                children: const [
                  TextSpan(text: "By proceeding, I agree to Wander Nova's "),
                  TextSpan(text: 'User Agreement', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
                  TextSpan(text: ', '),
                  TextSpan(text: 'Terms of Service', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
                  TextSpan(text: ' and cancellation & property Booking Policies.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(12), context.w(16), context.bottomBarHeight + context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: context.r(16), offset: Offset(0, -context.h(4))),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_submitError != null) ...[
            Row(
              children: [
                Icon(Icons.error_outline, size: context.w(16), color: Colors.red.shade400),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(_submitError!, style: TextStyle(color: Colors.red.shade400, fontSize: context.fs(12))),
                ),
              ],
            ),
            SizedBox(height: context.h(10)),
          ],
          Row(
            children: [
              // ── Price block: left side ──
              Expanded(                       // takes whatever is left of the button
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _priced == null ? '—' : '₹${_totalPayable.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w900, color: _navy),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      'Include taxes & fees',
                      style: TextStyle(fontSize: context.fs(10.5), color: _muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              SizedBox(width: context.w(14)),

              // ── Button: right side, fixed width ──
              SizedBox(
                width: context.w(149),        // 👈 fixed width keeps it on the right
                height: context.h(44),
                child: ElevatedButton(
                  onPressed: _submitting ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(12)),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    _isLoggedIn ? 'Continue' : 'Log-In to Book',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: context.fs(14),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

/// Mutable per-guest form state. Adults and children both carry a title and a
/// first/last name; only the lead guest additionally owns the contact
/// [mobile] / [email] controllers. [age] is fixed at 25 for adults (matching
/// the documented GuestCode) and taken from the searched child ages for
/// children.
class _GuestInput {
  /// 1-based room position within [_AkHotelPriceConfirmScreenState._occupancies]
  /// — not the vendor's occupancyId (see the screen's class doc for why).
  final int occupancyId;
  final String paxType; // 'A' (adult) or 'C' (child)
  final bool isLead;
  final int age;
  String title;

  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController? mobile;
  final TextEditingController? email;

  _GuestInput({
    required this.occupancyId,
    required this.paxType,
    required this.isLead,
    required this.age,
    required this.title,
  })  : mobile = isLead ? TextEditingController() : null,
        email = isLead ? TextEditingController() : null;

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    mobile?.dispose();
    email?.dispose();
  }
}
