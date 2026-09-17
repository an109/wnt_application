import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/services/pdf_generator.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../AKHotelRetrieveBooking/domain/entity/AKHotelRetrieveBooking_entity.dart';
import '../../../MyBookings/Hotels/Screen/hotel_pdf_builder.dart';
import '../../../MyBookings/Hotels/domain/entity/HotelBookingEntity.dart';

/// Final confirmation screen, reached only after StartPay reports the room
/// as actually booked (BookStatus "B0"). Every value shown here is either
/// StartPay's own response (transactionId, crsPnr), data collected earlier
/// in the flow (hotel Content, priced room, lead guest — threaded through
/// [AkHotelPriceConfirmScreen] -> [AkHotelPaymentScreen]), or [booking]
/// (the RetrieveBooking read-back, best-effort enrichment). Nothing on this
/// screen is fabricated/static.
///
/// UI mirrors [AkTicketConfirmationScreen]'s look (fonts, colours, Lottie
/// celebration) while following the reference hotel-voucher layout.
class AkHotelBookingConfirmedScreen extends StatefulWidget {
  final String hotelName;
  final String transactionId;
  final String crsPnr;

  /// MM/DD/YYYY, as threaded from Search Init.
  final String checkIn;
  final String checkOut;
  final String checkInTime;
  final String checkOutTime;

  final String hotelImage;
  final String hotelAddress;
  final String hotelCity;
  final String hotelCountry;
  final int starRating;
  final double reviewRating;

  final String roomType;
  final String mealPlan;
  final int roomsCount;
  final int adultsCount;
  final int childrenCount;

  /// Pre-tax fare, summed across every priced room. Taxes & fees are derived
  /// as (amount actually paid − this) rather than sourced separately, since
  /// Pricing only ever returns one combined total.
  final double baseFare;

  /// Amount actually paid (Total Paid) — this app's own charge, in INR.
  final double netAmount;

  final String leadGuestName;
  final String leadGuestEmail;
  final String leadGuestPhone;

  /// 'wallet' | 'razorpay' — the gateway [AkHotelPaymentScreen] actually
  /// charged, not a fabricated "UPI"/"Card" (the checkout SDK's success
  /// callback doesn't report the underlying instrument).
  final String paymentGateway;

  /// Captured the moment StartPay confirmed the booking — the API returns
  /// no booking timestamp, so this is the closest honest value (same
  /// approach [AkTicketConfirmationScreen] uses for its payment date).
  final DateTime? bookedAt;

  final AkHotelRetrieveBookingEntity? booking;

  const AkHotelBookingConfirmedScreen({
    super.key,
    required this.hotelName,
    required this.transactionId,
    required this.crsPnr,
    required this.checkIn,
    required this.checkOut,
    this.checkInTime = '',
    this.checkOutTime = '',
    this.hotelImage = '',
    this.hotelAddress = '',
    this.hotelCity = '',
    this.hotelCountry = '',
    this.starRating = 0,
    this.reviewRating = 0,
    this.roomType = '',
    this.mealPlan = '',
    this.roomsCount = 1,
    this.adultsCount = 1,
    this.childrenCount = 0,
    this.baseFare = 0,
    this.netAmount = 0,
    this.leadGuestName = '',
    this.leadGuestEmail = '',
    this.leadGuestPhone = '',
    this.paymentGateway = '',
    this.bookedAt,
    this.booking,
  });

  @override
  State<AkHotelBookingConfirmedScreen> createState() => _AkHotelBookingConfirmedScreenState();
}

class _AkHotelBookingConfirmedScreenState extends State<AkHotelBookingConfirmedScreen> {
  static const _pri = AppColors.AppBlue;
  static const _sec = AppColors.OrangeColor;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFCCCCCC);
  static const _ink = AppColors.black;
  static const _green = Color(0xFF34C759);
  static const _headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.AppBlue, Color(0xFF56B0FF)],
  );

  bool _downloading = false;

  final DateTime _bookedAt = DateTime.now();
  DateTime get _at => widget.bookedAt ?? _bookedAt;

  AkHotelRetrieveBookingEntity? get _b => widget.booking;

  // -------------------------------------------------------------------------
  // Dynamic data helpers — every value here reads the real booking response
  // -------------------------------------------------------------------------

  /// This app's own booking id — the transaction charged through Razorpay/
  /// wallet, shown at the top with a copy affordance.
  String get _bookingId => widget.transactionId.trim().isEmpty ? '--' : widget.transactionId.trim();

  /// The vendor's own confirmation code for this stay — StartPay's CrsPnr,
  /// falling back to the booking id only when the vendor didn't return one.
  String get _confirmationCode => widget.crsPnr.trim().isEmpty ? _bookingId : widget.crsPnr.trim();

  String get _hotelName => widget.hotelName.trim().isEmpty ? (_b?.hotelName ?? '') : widget.hotelName.trim();

  String get _addressLine {
    final parts = <String>[
      if (widget.hotelAddress.trim().isNotEmpty) widget.hotelAddress.trim(),
      if (widget.hotelCity.trim().isNotEmpty) widget.hotelCity.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    final city = _b?.city ?? '';
    final country = _b?.country ?? '';
    return [city, country].where((s) => s.trim().isNotEmpty).join(', ');
  }

  int get _starRating => widget.starRating > 0 ? widget.starRating : (_b?.starRating ?? 0);

  String get _prettyCheckIn => _prettyDate(widget.checkIn);
  String get _prettyCheckOut => _prettyDate(widget.checkOut);

  String _prettyDate(String mmddyyyy) {
    try {
      return DateFormat('d MMM\'yy').format(DateFormat('MM/dd/yyyy').parseStrict(mmddyyyy));
    } catch (_) {
      return mmddyyyy;
    }
  }

  String get _roomsAndGuests {
    final adults = widget.adultsCount;
    final children = widget.childrenCount;
    return [
      '${widget.roomsCount} Room${widget.roomsCount == 1 ? '' : 's'}',
      '$adults Adult${adults == 1 ? '' : 's'}',
      if (children > 0) '$children Child${children == 1 ? '' : 'ren'}',
    ].join(', ');
  }

  String get _roomType => widget.roomType.trim().isEmpty
      ? (_b != null && _b!.rooms.isNotEmpty ? _b!.rooms.first.name : '')
      : widget.roomType.trim();

  String get _mealPlan => widget.mealPlan.trim().isEmpty ? '--' : widget.mealPlan.trim();

  /// Pre-tax fare — real figure threaded from Pricing when available,
  /// otherwise the RetrieveBooking read-back's own base rate sum.
  double get _baseFare {
    if (widget.baseFare > 0) return widget.baseFare;
    final rooms = _b?.rooms ?? const [];
    if (rooms.isNotEmpty) return rooms.fold(0.0, (sum, r) => sum + r.baseRate);
    return _totalPaid;
  }

  double get _totalPaid => widget.netAmount > 0 ? widget.netAmount : (_b?.netFare ?? 0);

  /// Taxes & fees are never sourced directly (Pricing only returns one
  /// combined total) — derived as paid − base, clamped so a stale/looser
  /// base figure can never show a negative line.
  double get _taxesAndFees => (_totalPaid - _baseFare).clamp(0, _totalPaid);

  String _money(double v) => '₹${v.toStringAsFixed(0)}';

  String get _paymentMethodLabel => switch (widget.paymentGateway.trim().toLowerCase()) {
        'wallet' => 'Wallet',
        'razorpay' => 'Online Payment',
        _ => widget.paymentGateway.trim().isEmpty ? '--' : widget.paymentGateway.trim(),
      };

  String get _bookingDateLabel => DateFormat('d MMM\'yy').format(_at);

  String get _statusLabel {
    final raw = (_b?.currentStatus ?? '').trim().toUpperCase();
    if (raw == 'B0' || raw.isEmpty) return 'Confirmed';
    if (raw == 'CD') return 'Cancelled';
    return raw;
  }

  Color get _statusColor => _statusLabel.toLowerCase() == 'cancelled' ? const Color(0xffB42318) : _green;

  void _copyBookingId() {
    Clipboard.setData(ClipboardData(text: _bookingId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking ID copied'), duration: Duration(seconds: 1)),
    );
  }

  void _goHome() => Navigator.of(context).popUntil((r) => r.isFirst);

  // -------------------------------------------------------------------------
  // Voucher PDF — built from the same real fields the screen renders, via
  // the existing HotelPdfBuilder used by MyBookings.
  // -------------------------------------------------------------------------

  Future<void> _downloadVoucher() async {
    setState(() => _downloading = true);
    try {
      final nights = _nights;
      final entity = HotelBookingListEntity(
        id: 0,
        confirmationNumber: _confirmationCode,
        bookingReferenceId: _bookingId,
        tboBookingId: '',
        hotelName: _hotelName,
        hotelCode: '',
        hotelAddress: widget.hotelAddress,
        hotelCity: widget.hotelCity.isNotEmpty ? widget.hotelCity : (_b?.city ?? ''),
        hotelCountry: widget.hotelCountry.isNotEmpty ? widget.hotelCountry : (_b?.country ?? ''),
        hotelStars: _starRating,
        hotelImage: widget.hotelImage,
        roomType: _roomType,
        checkIn: _toIsoDate(widget.checkIn),
        checkOut: _toIsoDate(widget.checkOut),
        nights: nights,
        rooms: widget.roomsCount,
        guests: widget.adultsCount + widget.childrenCount,
        adults: widget.adultsCount,
        children: widget.childrenCount,
        totalFare: _totalPaid.toStringAsFixed(2),
        tax: _taxesAndFees.toStringAsFixed(2),
        currency: 'INR',
        guestName: widget.leadGuestName,
        email: widget.leadGuestEmail,
        phone: widget.leadGuestPhone,
        paymentMode: _paymentMethodLabel,
        checkoutId: widget.transactionId,
        guestReference: _confirmationCode,
        status: _statusLabel,
        bookingDate: _bookingDateLabel,
        created: _at.toIso8601String(),
        updated: _at.toIso8601String(),
      );

      final pdf = await HotelPdfBuilder.buildTicket(entity);
      final file = await PDFService.savePDF(pdf, 'hotel_voucher_$_bookingId.pdf');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher saved: ${file.path.split(RegExp(r'[\\/]')).last}'),
          action: SnackBarAction(label: 'Share', onPressed: () => PDFService.sharePDF(file)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate voucher: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  int get _nights {
    try {
      final inDate = DateFormat('MM/dd/yyyy').parseStrict(widget.checkIn);
      final outDate = DateFormat('MM/dd/yyyy').parseStrict(widget.checkOut);
      final diff = outDate.difference(inDate).inDays;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  String _toIsoDate(String mmddyyyy) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat('MM/dd/yyyy').parseStrict(mmddyyyy));
    } catch (_) {
      return mmddyyyy;
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(context.w(16), context.h(16), context.w(16), context.h(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _successHeader(context),
              SizedBox(height: context.h(14)),
              _bookingIdPill(context),
              SizedBox(height: context.h(20)),
              _confirmationCard(context),
              SizedBox(height: context.h(16)),
              _hotelDetailsCard(context),
              SizedBox(height: context.h(16)),
              _amountPaidCard(context),
              SizedBox(height: context.h(16)),
              _bookingSummaryCard(context),
              SizedBox(height: context.h(22)),
              _footer(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  // ==================== SUCCESS HEADER ====================
  Widget _successHeader(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: context.h(150),
          child: Lottie.asset(
            'assets/animation/celebrate.json',
            repeat: true,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(
              child: Container(
                width: context.w(74),
                height: context.w(74),
                decoration: const BoxDecoration(color: Color(0xFFEAFBF1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: _green, size: context.w(44)),
              ),
            ),
          ),
        ),
        SizedBox(height: context.h(4)),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFF00A1E4), Color(0xFF0088FF)],
          ).createShader(rect),
          child: Text(
            'Payment Successful!',
            textAlign: TextAlign.center,
            style: GoogleFonts.pottaOne(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          'Your booking is confirmed.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w500, color: _muted),
        ),
      ],
    );
  }

  // ==================== BOOKING ID PILL ====================
  Widget _bookingIdPill(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _copyBookingId,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(10)),
          decoration: BoxDecoration(
            color: const Color(0xFF56B0FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(context.r(24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: 'Booking ID: ',
                    style: TextStyle(fontSize: context.fs(12.5), color: _muted, fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: _bookingId,
                    style: TextStyle(fontSize: context.fs(12.5), color: _pri, fontWeight: FontWeight.w800),
                  ),
                ]),
              ),
              SizedBox(width: context.w(8)),
              Image.asset('assets/HbookImage/copy.png', width: context.w(15), height: context.w(15)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CONFIRMATION HOLDER CARD ====================
  Widget _confirmationCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.w(16)),
            decoration: const BoxDecoration(gradient: _headerGradient),
            child: Stack(
              children: [
                Positioned(
                  right: -context.w(6),
                  top: -context.h(4),
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.asset('assets/HbookImage/book.png', width: context.w(90), height: context.h(70), fit: BoxFit.contain),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONFIRMATION HOLDER',
                      style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.5),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      _confirmationCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: _stroke, width: 0.5),
                right: BorderSide(color: _stroke, width: 0.5),
                bottom: BorderSide(color: _stroke, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GUEST CONTACT',
                        style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.5),
                      ),
                      SizedBox(height: context.h(6)),
                      Text(
                        widget.leadGuestName.isEmpty ? 'Guest' : widget.leadGuestName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.fs(13.5), fontWeight: FontWeight.w700, color: _ink),
                      ),
                      if (widget.leadGuestEmail.isNotEmpty) ...[
                        SizedBox(height: context.h(6)),
                        _contactLine(context, Icons.mail_outline_rounded, widget.leadGuestEmail),
                      ],
                      if (widget.leadGuestPhone.isNotEmpty) ...[
                        SizedBox(height: context.h(4)),
                        _contactLine(context, Icons.call_outlined, widget.leadGuestPhone),
                      ],
                    ],
                  ),
                ),
                Image.asset('assets/HbookImage/guest.png', width: context.w(52), height: context.w(52)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactLine(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: context.w(12), color: _muted),
        SizedBox(width: context.w(6)),
        Expanded(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: context.fs(11.5), color: _muted)),
        ),
      ],
    );
  }

  // ==================== HOTEL DETAILS CARD ====================
  /// Row(details column, 142×159 hero image with the rating badged over its
  /// top-left corner), then two stat rows — matches the reference layout.
  Widget _hotelDetailsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke, width: 0.5),
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
                      'HOTEL DETAILS',
                      style: TextStyle(fontSize: context.fs(9.5), fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.5),
                    ),
                    SizedBox(height: context.h(5)),
                    Text(
                      _hotelName.isEmpty ? 'Hotel' : _hotelName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: _ink),
                    ),
                    if (_addressLine.isNotEmpty) ...[
                      SizedBox(height: context.h(5)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: context.w(12), color: _muted),
                          SizedBox(width: context.w(3)),
                          Expanded(
                            child: Text(_addressLine, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: context.fs(11), color: _muted)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: context.w(10)),
              _hotelHeroImage(context),
            ],
          ),
          SizedBox(height: context.h(16)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _hotelStat(context, icon: Icons.calendar_today_outlined, label: 'CHECK-IN', value: _prettyCheckIn, sub: _weekday(widget.checkIn))),
              Expanded(child: _hotelStat(context, icon: Icons.calendar_today_outlined, label: 'CHECK-OUT', value: _prettyCheckOut, sub: _weekday(widget.checkOut))),
              Expanded(child: _hotelStat(context, icon: Icons.bed_outlined, label: 'ROOM TYPE', value: _roomType.isEmpty ? '--' : _roomType, valueColor: _pri)),
            ],
          ),
          SizedBox(height: context.h(14)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _hotelStat(context, iconAsset: 'assets/HbookImage/persons.png', label: 'ROOM & GUESTS', value: _roomsAndGuests),
              ),
              Expanded(child: _hotelStat(context, icon: Icons.restaurant_outlined, label: 'MEAL PLAN', value: _mealPlan, valueColor: _pri)),
            ],
          ),
        ],
      ),
    );
  }

  /// Hero photo — fixed 142×159 per the reference layout — with the guest
  /// review rating badged over its top-left corner.
  Widget _hotelHeroImage(BuildContext context) {
    const width = 142.0;
    const height = 159.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(context.r(10)),
          child: widget.hotelImage.isEmpty
              ? Container(
                  width: context.w(width),
                  height: context.h(height),
                  color: const Color(0xFFF1F5F9),
                  child: Icon(Icons.apartment_rounded, size: context.w(32), color: _muted),
                )
              : CachedNetworkImage(
                  imageUrl: widget.hotelImage,
                  cacheManager: FastNetworkImageCacheManager.instance,
                  width: context.w(width),
                  height: context.h(height),
                  fit: BoxFit.cover,
                  memCacheWidth: 340,
                  placeholder: (_, __) => Container(width: context.w(width), height: context.h(height), color: const Color(0xFFF1F5F9)),
                  errorWidget: (_, __, ___) => Container(
                    width: context.w(width),
                    height: context.h(height),
                    color: const Color(0xFFF1F5F9),
                    child: Icon(Icons.apartment_rounded, size: context.w(32), color: _muted),
                  ),
                ),
        ),
        if (widget.reviewRating > 0)
          Positioned(
            left: context.w(6),
            top: context.h(6),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(2)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(6)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFB020), size: 12),
                  SizedBox(width: context.w(2)),
                  Text(
                    widget.reviewRating.toStringAsFixed(1),
                    style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w800, color: _ink),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// The stay's day-of-week for the CHECK-IN/CHECK-OUT sub-line — real,
  /// derived from the booked date, not a fabricated hotel check-in time.
  String _weekday(String mmddyyyy) {
    try {
      return DateFormat('EEEE').format(DateFormat('MM/dd/yyyy').parseStrict(mmddyyyy));
    } catch (_) {
      return '';
    }
  }

  Widget _hotelStat(
    BuildContext context, {
    IconData? icon,
    String? iconAsset,
    required String label,
    required String value,
    String? sub,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            iconAsset != null
                ? Image.asset(iconAsset, width: context.w(12), height: context.w(12), color: _pri)
                : Icon(icon, size: context.w(12), color: _pri),
            SizedBox(width: context.w(4)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(5)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800, color: valueColor ?? _ink),
        ),
        if (sub != null && sub.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(sub, style: TextStyle(fontSize: context.fs(9.5), color: _muted)),
        ],
      ],
    );
  }

  // ==================== AMOUNT PAID CARD ====================
  Widget _amountPaidCard(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: context.w(84),
            padding: EdgeInsets.symmetric(vertical: context.h(14)),
            decoration: BoxDecoration(
              color: _pri,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(12)),
                bottomLeft: Radius.circular(context.r(12)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/HbookImage/amountPaid.png', width: context.w(38), height: context.w(38)),
                SizedBox(height: context.h(8)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(6)),
                  child: Text(
                    'Amount Paid',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(context.w(14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(context.r(12)),
                  bottomRight: Radius.circular(context.r(12)),
                ),
                border: Border.all(color: _stroke, width: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _fareRow(context, 'Base Fare', _money(_baseFare)),
                  SizedBox(height: context.h(8)),
                  _fareRow(context, 'Taxes & Fees', _money(_taxesAndFees)),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.h(8)),
                    child: Divider(height: 1, color: _stroke.withValues(alpha: 0.7)),
                  ),
                  _fareRow(context, 'Total Paid', _money(_totalPaid), big: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(BuildContext context, String label, String value, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: context.fs(big ? 13 : 12), fontWeight: big ? FontWeight.w700 : FontWeight.w500, color: big ? _ink : _muted)),
        Text(
          value,
          style: TextStyle(fontSize: context.fs(big ? 15 : 12.5), fontWeight: FontWeight.w800, color: big ? _green : _ink),
        ),
      ],
    );
  }

  // ==================== BOOKING SUMMARY CARD ====================
  Widget _bookingSummaryCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BOOKING SUMMARY', style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w800, color: _pri, letterSpacing: 0.4)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(context.r(20)),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: _statusColor),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _hotelStat(
                  context,
                  iconAsset: 'assets/HbookImage/walletIcon.png',
                  label: 'PAYMENT METHOD',
                  value: _paymentMethodLabel,
                ),
              ),
              Expanded(child: _hotelStat(context, icon: Icons.event_available_rounded, label: 'BOOKING DATE', value: _bookingDateLabel)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== FOOTER ====================
  /// Suitcase + wordmark + paper-plane accent — mirrors the reference
  /// footer graphic. Built from [Wrap]s (not fixed-width [Row]s) so it
  /// reflows onto extra lines on very narrow phones instead of overflowing.
  Widget _footer(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.w(8),
      runSpacing: context.h(4),
      children: [
        Image.asset('assets/HbookImage/bag.png', width: context.w(40), height: context.w(40)),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for choosing',
              style: TextStyle(fontSize: context.fs(10.5), color: _ink, fontWeight: FontWeight.w600),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'WANDER ', style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: const Color(0xFF0054A0))),
                    TextSpan(text: 'NOVA', style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: const Color(0xFFFF7200))),
                  ]),
                ),
                SizedBox(width: context.w(6)),
                Text('Have a great trip!', style: TextStyle(fontSize: context.fs(10.5), color: _green, fontWeight: FontWeight.w600)),
                SizedBox(width: context.w(4)),
                Transform.rotate(
                  angle: -0.35,
                  child: Image.asset('assets/HbookImage/plane.png', width: context.w(14), height: context.w(14)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ==================== BOTTOM BAR ====================
  Widget _bottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(24))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(19), vertical: context.h(12)),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: context.h(48),
                  child: OutlinedButton(
                    onPressed: _goHome,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _sec),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                    ),
                    child: FittedBox(
                      child: Text('GO TO HOME', style: TextStyle(color: _sec, fontSize: context.fs(14), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: SizedBox(
                  height: context.h(48),
                  child: ElevatedButton(
                    onPressed: _downloading ? null : _downloadVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sec,
                      disabledBackgroundColor: _sec.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_downloading)
                          SizedBox(
                            width: context.w(16),
                            height: context.w(16),
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          Icon(Icons.download_rounded, size: context.w(18), color: Colors.white),
                        SizedBox(width: context.w(8)),
                        Flexible(
                          child: FittedBox(
                            child: Text(
                              _downloading ? 'PREPARING…' : 'DOWNLOAD',
                              style: TextStyle(color: Colors.white, fontSize: context.fs(14), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
