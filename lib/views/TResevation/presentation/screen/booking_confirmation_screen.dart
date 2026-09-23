import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/services/pdf_generator.dart';
import '../../../MyBookings/Transport/Screen/transport_pdf_builder.dart';
import '../../../MyBookings/Transport/domain/entity/MyBooking_entity.dart';
import '../../../TReservation_poll/presentation/bloc/poll_bloc.dart';
import '../../../TReservation_poll/presentation/bloc/poll_event.dart';
import '../../../TReservation_poll/presentation/bloc/poll_state.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../domain/entities/TReservation-entity.dart';
import '../../../../injection_container.dart' as di;

/// Booking confirmation — Figma "Payment Successful" voucher. Every value
/// shown is either the reservation actually charged/created
/// ([widget.reservation]), the response status/confirmation number, or a
/// poll update — nothing here is a static placeholder. A row/card is simply
/// hidden when the underlying data is blank.
class BookingConfirmationScreen extends StatefulWidget {
  final TransportReservationEntity reservation;
  final String status;
  final String confirmationNumber;

  const BookingConfirmationScreen({
    super.key,
    required this.reservation,
    required this.status,
    required this.confirmationNumber,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  static const _pri = AppColors.AppBlue;
  static const _sec = AppColors.OrangeColor;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFCCCCCC);
  static const _ink = AppColors.black;
  static const _green = Color(0xFF34C759);
  static const _amber = Color(0xffF59E0B);
  static const _headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.AppBlue, Color(0xFF56B0FF)],
  );

  late ReservationPollBloc _pollBloc;
  bool _downloading = false;

  // Captured the moment this screen opens — the reservation response has no
  // booking timestamp of its own, so "now" is the closest honest value
  // (same approach AkHotelBookingConfirmedScreen uses).
  final DateTime _bookedAt = DateTime.now();

  // Local state to hold updated data from polling.
  String? _updatedStatus;
  String? _updatedConfirmationNumber;

  bool get _isPending =>
      (_updatedStatus ?? widget.status).toLowerCase() == 'pending';
  bool get _isConfirmed =>
      (_updatedStatus ?? widget.status).toLowerCase() == 'confirmed' ||
      (_updatedStatus ?? widget.status).toLowerCase() == 'completed';

  Color get _statusColor =>
      _isConfirmed ? _green : (_isPending ? _amber : _pri);

  String get _statusLabel {
    final s = _updatedStatus ?? widget.status;
    return s.isEmpty ? 'Pending' : s[0].toUpperCase() + s.substring(1);
  }

  /// This app's own charge reference (Razorpay payment id / wallet
  /// reference), falling back through whatever the reservation actually
  /// carries — never a fabricated code.
  String get _referenceCode {
    if (_updatedConfirmationNumber != null &&
        _updatedConfirmationNumber!.isNotEmpty) {
      return _updatedConfirmationNumber!;
    }
    if (widget.confirmationNumber.isNotEmpty) return widget.confirmationNumber;
    if (widget.reservation.razorpayPaymentId.isNotEmpty)
      return widget.reservation.razorpayPaymentId;
    if (widget.reservation.paymentReferenceId.isNotEmpty)
      return widget.reservation.paymentReferenceId;
    return '';
  }

  String get _paymentMethodLabel =>
      switch (widget.reservation.paidVia.trim().toLowerCase()) {
        'wallet' => 'Wallet',
        'razorpay' => 'Online Payment',
        _ =>
          widget.reservation.paidVia.trim().isEmpty
              ? ''
              : widget.reservation.paidVia.trim(),
      };

  String get _bookingDateLabel =>
      DateFormat('d MMM\'yy | hh:mma').format(_bookedAt);

  String get _tripTypeLabel =>
      widget.reservation.tripType == 'round_trip' ? 'Round Trip' : 'One Way';

  String get _currency => widget.reservation.displayCurrency.isNotEmpty
      ? widget.reservation.displayCurrency
      : 'INR';

  String _money(double v) =>
      '₹${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

  @override
  void initState() {
    super.initState();
    _pollBloc = di.sl<ReservationPollBloc>();
    if (widget.status.toLowerCase() == 'pending') {
      final searchId = widget.reservation.searchId;
      if (searchId.isNotEmpty) {
        _pollBloc.add(FetchReservationPoll(searchId: searchId));
      }
    }
  }

  @override
  void dispose() {
    _pollBloc.close();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _copyReference() {
    if (_referenceCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referenceCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reference copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Voucher PDF — built from the same real fields the screen renders, via
  // the existing TransportPdfBuilder used by My Bookings.
  // -------------------------------------------------------------------------
  Future<void> _downloadVoucher() async {
    setState(() => _downloading = true);
    try {
      final r = widget.reservation;
      final entity = BookingEntity(
        id: 0,
        userId: r.userId,
        status: _statusLabel,
        email: r.email,
        phoneNumber: r.phoneNumber,
        firstName: r.customerInfo.firstName,
        lastName: r.customerInfo.lastName,
        currency: _currency,
        amountPaid: r.displayTotalPrice.toStringAsFixed(2),
        totalPrice: r.displayTotalPrice.toStringAsFixed(2),
        canCancel: false,
        cancelled: false,
        providerName: r.providerName,
        confirmationNumber: _referenceCode,
        created: _bookedAt.toIso8601String(),
        updated: _bookedAt.toIso8601String(),
        destination: r.tripEndAddress,
        type: r.vehicleName.isNotEmpty ? r.vehicleName : r.flightNumber,
        applicantCount: r.numPassengers,
        bookedDate: _bookingDateLabel,
        category: 'Transport',
        startAddress: r.tripStartAddress,
        endAddress: r.tripEndAddress,
        pickupDatetime: r.tripPickupDatetime,
        flightNumber: r.flightNumber,
        vehicleName: r.vehicleName,
        rawTotalPrice: r.displayTotalPrice.toStringAsFixed(2),
        rawCurrency: r.currency.isNotEmpty ? r.currency : 'USD',
      );

      final pdf = TransportPdfBuilder.buildTicket(entity);
      final file = await PDFService.savePDF(
        pdf,
        'transport_voucher_${_referenceCode.isEmpty ? 'wnt' : _referenceCode}.pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voucher saved: ${file.path.split(RegExp(r'[\\/]')).last}',
          ),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => PDFService.sharePDF(file),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not generate voucher: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return BlocListener<ReservationPollBloc, ReservationPollState>(
      bloc: _pollBloc,
      listener: (context, state) {
        if (state is ReservationPollSuccess) {
          final entity = state.reservationPoll;
          setState(() {
            if (entity.status != null) _updatedStatus = entity.status;
            if (entity.confirmationNumber != null)
              _updatedConfirmationNumber = entity.confirmationNumber;
          });
        }
      },
      child: PopScope(
        // Hardware back also returns home, never to the payment screen.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goHome(context);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                context.w(16),
                context.h(16),
                context.w(16),
                context.h(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _successHeader(context),
                  SizedBox(height: context.h(14)),
                  _referencePill(context),
                  SizedBox(height: context.h(20)),
                  _tripAndContactCard(context),
                  SizedBox(height: context.h(16)),
                  _routeAndVehicleCard(context),
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
        ),
      ),
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
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPending
                      ? Icons.hourglass_top_rounded
                      : Icons.check_circle_rounded,
                  color: _statusColor,
                  size: context.w(44),
                ),
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
            _isPending ? 'Booking Received!' : 'Payment Successful!',
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
          _isPending
              ? 'Your booking is being confirmed.'
              : 'Your booking is confirmed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
      ],
    );
  }

  // ==================== REFERENCE PILL ====================
  Widget _referencePill(BuildContext context) {
    if (_referenceCode.isEmpty) return const SizedBox.shrink();
    return Center(
      child: GestureDetector(
        onTap: _copyReference,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(10),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF56B0FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(context.r(24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Reference: ',
                        style: TextStyle(
                          fontSize: context.fs(12.5),
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: _referenceCode,
                        style: TextStyle(
                          fontSize: context.fs(12.5),
                          color: _pri,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: context.w(8)),
              Image.asset(
                'assets/HbookImage/copy.png',
                width: context.w(15),
                height: context.w(15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TRIP + TRAVELLER CONTACT CARD ====================
  Widget _tripAndContactCard(BuildContext context) {
    final r = widget.reservation;
    final name = '${r.customerInfo.firstName} ${r.customerInfo.lastName}'
        .trim();
    final contactRows = <Widget>[
      if (r.email.isNotEmpty) _contactLine(context, Icons.mail, r.email),
      if (r.phoneNumber.isNotEmpty)
        _contactLine(context, Icons.call, r.phoneNumber),
    ];

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRIP',
                  style: TextStyle(
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  _tripTypeLabel,
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (name.isNotEmpty || contactRows.isNotEmpty)
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRAVELLER CONTACT',
                    style: TextStyle(
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (name.isNotEmpty) ...[
                    SizedBox(height: context.h(6)),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(13.5),
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                  for (final row in contactRows) ...[
                    SizedBox(height: context.h(6)),
                    row,
                  ],
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
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: context.fs(11.5), color: _muted),
          ),
        ),
      ],
    );
  }

  // ==================== ROUTE + VEHICLE CARD ====================
  Widget _routeAndVehicleCard(BuildContext context) {
    final r = widget.reservation;
    final tiles = <Widget>[
      if (r.tripStartAddress.isNotEmpty)
        _iconStat(
          context,
          label: 'From:',
          value: r.tripStartAddress,
          iconBg: AppColors.white,
          iconColor: AppColors.OrangeColor,
          svgAsset: 'assets/NewIcons/location.svg',
        ),
      if (r.tripEndAddress.isNotEmpty)
        _iconStat(
          context,
          label: 'To:',
          value: r.tripEndAddress,
          iconBg: AppColors.white,
          iconColor: _pri,
          svgAsset: 'assets/NewIcons/location_outline.svg',
        ),
      if (r.vehicleName.isNotEmpty)
        _iconStat(
          context,
          label: 'Vehicle',
          value: r.vehicleName,
          iconBg: AppColors.white,
          iconColor: const Color(0xFF16A34A),
          pngAsset: 'assets/NewIcons/car.png',
        ),
      if (r.providerName.isNotEmpty)
        _iconStat(
          context,
          label: 'Provider',
          value: r.providerName,
          iconBg: AppColors.white,
          iconColor: Colors.amber,
          pngAsset: 'assets/NewIcons/provider.png',
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke, width: 0.5),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final gap = context.w(14);
          final w = (c.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: context.h(14),
            children: [for (final t in tiles) SizedBox(width: w, child: t)],
          );
        },
      ),
    );
  }

  Widget _iconStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color iconBg,
    required Color iconColor,
    String? svgAsset,
    String? pngAsset,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.w(36),
          height: context.w(36),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(context.r(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset,
                  width: context.w(14),
                  height: context.w(14),
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                )
              : Image.asset(
                  pngAsset!,
                  width: context.w(17),
                  height: context.w(17),
                  color: iconColor,
                ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.fs(11.5), color: _muted),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _amountPaidCard(BuildContext context) {
    final r = widget.reservation;
    final rows = <Widget>[
      _fareRow(context, 'Base Fare', _money(r.displayBasePrice)),
      if (r.displayDiscountAmount > 0) ...[
        SizedBox(height: context.h(8)),
        _fareRow(context, 'Discount', '- ${_money(r.displayDiscountAmount)}'),
      ],
      Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Divider(height: 1, color: _stroke.withValues(alpha: 0.7)),
      ),
      _fareRow(context, 'Total Paid', _money(r.displayTotalPrice), big: true),
    ];

    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          // Gradient background
          gradient: LinearGradient(
            colors: [
              AppColors.AppBlue,
              const Color(0xFFF1F5F9),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(context.r(14)),
        ),
        padding: EdgeInsets.all(context.w(4)), // space around white card
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left icon section (transparent, shows gradient behind)
            Container(
              width: context.w(84),
              padding: EdgeInsets.symmetric(vertical: context.h(14)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/HbookImage/amountPaid.png',
                    width: context.w(24),
                    height: context.w(24),
                  ),
                  SizedBox(height: context.h(8)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(6)),
                    child: Text(
                      'Amount Paid',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right white card
            Expanded(
              child: Container(
                padding: EdgeInsets.all(context.w(14)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rows,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _fareRow(
    BuildContext context,
    String label,
    String value, {
    bool big = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.fs(big ? 13 : 12),
            fontWeight: big ? FontWeight.w700 : FontWeight.w500,
            color: big ? _ink : _muted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.fs(big ? 15 : 12.5),
            fontWeight: FontWeight.w800,
            color: big ? _green : _ink,
          ),
        ),
      ],
    );
  }

  // ==================== BOOKING SUMMARY CARD ====================
  // Widget _bookingSummaryCard(BuildContext context) {
  //   final tiles = <Widget>[
  //     if (_paymentMethodLabel.isNotEmpty)
  //       Expanded(
  //         child: _tile(
  //           context,
  //           label: 'PAYMENT METHOD',
  //           value: _paymentMethodLabel,
  //           iconBg: const Color(0xFFF1F5F9),
  //           iconColor: _pri,
  //           pngAsset: 'assets/NewIcons/credit.png',
  //         ),
  //       ),
  //     Expanded(
  //       child: _tile(
  //         context,
  //         label: 'BOOKING DATE & TIME',
  //         value: _bookingDateLabel,
  //         iconBg: const Color(0xFFF1F5F9),
  //         iconColor: _pri,
  //         pngAsset: 'assets/NewIcons/departureCalendar.png',
  //       ),
  //     ),
  //   ];
  //
  //   return Container(
  //     padding: EdgeInsets.all(context.w(12)),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(context.r(12)),
  //       border: Border.all(color: _stroke, width: 0.5),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'BOOKING SUMMARY',
  //               style: TextStyle(
  //                 fontSize: context.fs(12),
  //                 fontWeight: FontWeight.w600,
  //                 color: _pri,
  //                 letterSpacing: 0.6,
  //               ),
  //             ),
  //             Container(
  //               padding: EdgeInsets.symmetric(
  //                 horizontal: context.w(10),
  //                 vertical: context.h(4),
  //               ),
  //               decoration: BoxDecoration(
  //                 color: _statusColor.withValues(alpha: 0.08),
  //                 borderRadius: BorderRadius.circular(context.r(24)),
  //                 border: Border.all(
  //                   color: _statusColor.withValues(alpha: 0.4),
  //                 ),
  //               ),
  //               child: Text(
  //                 _statusLabel,
  //                 style: TextStyle(
  //                   fontSize: context.fs(10),
  //                   fontWeight: FontWeight.w600,
  //                   color: _statusColor,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: context.h(14)),
  //         Row(crossAxisAlignment: CrossAxisAlignment.start, children: tiles),
  //       ],
  //     ),
  //   );
  // }
  Widget _bookingSummaryCard(BuildContext context) {
    final tiles = <Widget>[
      if (_paymentMethodLabel.isNotEmpty)
        Expanded(
          child: _tile(
            context,
            label: 'PAYMENT METHOD',
            value: _paymentMethodLabel,
            pngAsset: 'assets/NewIcons/paymethod.png',
          ),
        ),
      if (_paymentMethodLabel.isNotEmpty)
        Container(
          width: 0.7,
          height: context.h(40),
          color: _stroke.withValues(alpha: 0.4),
          margin: EdgeInsets.symmetric(horizontal: context.w(12)),
        ),
      Expanded(
        child: _tile(
          context,
          label: 'BOOKING DATE & Time',
          value: _bookingDateLabel,
          pngAsset: 'assets/NewIcons/TCalender.png',
        ),
      ),
    ];

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
              Text(
                'BOOKING SUMMARY',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                  color: _pri,
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(5),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(24)),
                  border: Border.all(
                    color: _statusColor,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          // Gray rounded container holding tiles
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(12),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: tiles,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
      BuildContext context, {
        required String label,
        required String value,
        String? svgAsset,
        String? pngAsset,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon without background box
        svgAsset != null
            ? SvgPicture.asset(
          svgAsset,
          width: context.w(18),
          height: context.w(18),
          colorFilter: ColorFilter.mode(
            _muted.withValues(alpha: 0.6),
            BlendMode.srcIn,
          ),
        )
            : Image.asset(
          pngAsset!,
          width: context.w(18),
          height: context.w(18),
          color: _muted.withValues(alpha: 0.6),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== FOOTER ====================
  Widget _footer(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.w(8),
      runSpacing: context.h(4),
      children: [
        Image.asset(
          'assets/HbookImage/bag.png',
          width: context.w(40),
          height: context.w(40),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for choosing',
              style: TextStyle(
                fontSize: context.fs(10.5),
                color: _ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'WANDER ',
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w800,
                          color: AppColors.AppBlue,
                        ),
                      ),
                      TextSpan(
                        text: 'NOVA',
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w800,
                          color: AppColors.OrangeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(6)),
                Text(
                  'Have a great trip!',
                  style: TextStyle(
                    fontSize: context.fs(10.5),
                    color: _green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: context.w(4)),
                Transform.rotate(
                  angle: -0.35,
                  child: Image.asset(
                    'assets/HbookImage/plane.png',
                    width: context.w(14),
                    height: context.w(14),
                  ),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(24)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(19),
            vertical: context.h(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: context.h(48),
                  child: OutlinedButton(
                    onPressed: () => _goHome(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _sec),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                    ),
                    child: FittedBox(
                      child: Text(
                        'GO TO HOME',
                        style: TextStyle(
                          color: _sec,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_downloading)
                          SizedBox(
                            width: context.w(16),
                            height: context.w(16),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            Icons.download_rounded,
                            size: context.w(18),
                            color: Colors.white,
                          ),
                        SizedBox(width: context.w(8)),
                        Flexible(
                          child: FittedBox(
                            child: Text(
                              _downloading ? 'PREPARING…' : 'DOWNLOAD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.fs(14),
                                fontWeight: FontWeight.w600,
                              ),
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
