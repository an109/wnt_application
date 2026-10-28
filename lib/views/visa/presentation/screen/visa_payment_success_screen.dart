import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/services/pdf_generator.dart';

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../../data/visa_form_data.dart';
import '../../data/visa_pdf_builder.dart';
import '../utils/visa_rules.dart';
import 'visa_landing_screen.dart';

/// Full-screen payment-success confirmation for visa applications.
///
/// Mirrors the flight module's [AkTicketConfirmationScreen] structure:
/// celebration Lottie → gradient title → booking-ID pill → visa card →
/// trip-details card → dates card → amount-paid card → booking-summary card →
/// branding footer → bottom bar (Go Home / Download).
///
/// Figma "Payment done visa" node 3604:9567.
class VisaPaymentSuccessScreen extends StatefulWidget {
  final VisaPopularDestinationEntity destination;
  final VisaTypeEntity visaType;
  final List<VisaTravellerForm> travellers;
  final VisaTripForm trip;
  final double totalInr;
  final double visaFeeInr;
  final double insuranceInr;
  final int? insuranceDays;
  final String bookingId;
  final String? trackId;
  final String paymentMode;

  const VisaPaymentSuccessScreen({
    super.key,
    required this.destination,
    required this.visaType,
    required this.travellers,
    required this.trip,
    required this.totalInr,
    required this.visaFeeInr,
    this.insuranceInr = 0,
    this.insuranceDays,
    required this.bookingId,
    this.trackId,
    this.paymentMode = 'UPI',
  });

  @override
  State<VisaPaymentSuccessScreen> createState() =>
      _VisaPaymentSuccessScreenState();
}

class _VisaPaymentSuccessScreenState extends State<VisaPaymentSuccessScreen> {
  static const _pri = AppColors.AppBlue;
  static const _sec = AppColors.OrangeColor;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFCCCCCC);
  static const _ink = Color(0xFF0F172A);
  static const _green = Color(0xFF34C759);

  final DateTime _paidAt = DateTime.now();
  bool _downloading = false;

  VisaPopularDestinationEntity get _d => widget.destination;
  VisaTypeEntity get _type => widget.visaType;
  int get _count => widget.travellers.length;

  String _money(double inr) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(inr.round())}';

  void _goHome() => Navigator.of(context).popUntil(
        (r) => r.settings.name == VisaLandingScreen.routeName || r.isFirst,
      );

  Future<void> _downloadInvoice() async {
    setState(() => _downloading = true);
    try {
      final logoData = await rootBundle.load('assets/appLogo/wanderlogo2.png');
      final logoBytes = logoData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      final pdf = VisaPdfBuilder.buildInvoice(
        destination: _d.shortName,
        visaType: _type.title,
        visaStay: _type.stay.isNotEmpty ? _type.stay : _type.validity,
        travellers: widget.travellers,
        trip: widget.trip,
        visaFeeInr: widget.visaFeeInr,
        insuranceInr: widget.insuranceInr,
        insuranceDays: widget.insuranceDays,
        totalInr: widget.totalInr,
        bookingId: widget.bookingId,
        trackId: widget.trackId,
        paymentMode: widget.paymentMode,
        logo: logoImage,
      );

      final fileName = 'visa_invoice_${widget.bookingId}.pdf';
      final file = await PDFService.savePDF(pdf, fileName);
      final savedPath =
          await PDFService.saveToDevice(file, fileName: fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(savedPath == null
              ? 'Invoice ready: $fileName'
              : 'Invoice saved to your phone'),
          action: SnackBarAction(
              label: 'Share', onPressed: () => PDFService.sharePDF(file)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(
              context.fx(16), context.fx(20), context.fx(16), context.fx(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _successHeader(context),
              SizedBox(height: context.fx(12)),
              _bookingIdPill(context),
              SizedBox(height: context.fx(24)),
              _visaGradientCard(context),
              SizedBox(height: context.fx(24)),
              _tripDetailsCard(context),
              SizedBox(height: context.fx(24)),
              _datesCard(context),
              SizedBox(height: context.fx(24)),
              _amountPaidCard(context),
              SizedBox(height: context.fx(24)),
              _bookingSummaryCard(context),
              SizedBox(height: context.fx(24)),
              _brandingFooter(context),
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
          height: context.fx(230),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Lottie.asset(
                  'assets/animation/celebrate.json',
                  repeat: true,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              _SuccessTick(
                  size: context.fx(96), color: const Color(0xFF16A34A)),
            ],
          ),
        ),
        SizedBox(height: context.fx(4)),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFF00A1E4), Color(0xFF0088FF)],
          ).createShader(rect),
          child: Text(
            'Payment Successful!',
            textAlign: TextAlign.center,
            style: GoogleFonts.pottaOne(
              fontSize: context.ffs(24),
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
        ),
        SizedBox(height: context.fx(3)),
        Text(
          'Your booking is confirmed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.ffs(14),
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
      ],
    );
  }

  // ==================== BOOKING ID PILL ====================
  Widget _bookingIdPill(BuildContext context) {
    final id = widget.bookingId;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.fx(12), vertical: context.fx(4)),
        decoration: BoxDecoration(
          color: const Color(0xFFD9F4FF),
          borderRadius: BorderRadius.circular(context.fx(24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: 'Booking ID: ',
                    style: TextStyle(
                      fontSize: context.ffs(10),
                      fontWeight: FontWeight.w500,
                      color: _muted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  TextSpan(
                    text: id,
                    style: TextStyle(
                      fontSize: context.ffs(10),
                      fontWeight: FontWeight.w700,
                      color: _pri,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: context.fx(8)),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking ID copied'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Image.asset(
                'assets/HbookImage/copy.png',
                width: context.w(15),
                height: context.w(15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== VISA GRADIENT CARD ====================
  Widget _visaGradientCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.fx(16)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6007A), Color(0xFF9D1C98), Color(0xFF581C87)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: context.fx(30),
            child: Transform.rotate(
              angle: -6 * math.pi / 180,
              child: Container(
                width: context.fx(70),
                height: context.fx(70),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.fx(6)),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://flagcdn.com/w320/${(_d.countryCode ?? 'ae').toLowerCase()}.png',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.white.withValues(alpha: 0.2),
                    child: Icon(Icons.flag,
                        size: context.fx(22), color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.fx(10), vertical: context.fx(2)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'VISA',
                      style: TextStyle(
                        fontSize: context.ffs(12),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.55,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: context.fx(8)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.fx(12), vertical: context.fx(2)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: context.ffs(11),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.fx(10)),
              SizedBox(
                width: context.fx(245),
                child: Text(
                  '${_d.shortName} – ${_type.stay.isNotEmpty ? _type.stay : _type.validity}\n${_type.title}',
                  style: TextStyle(
                    fontSize: context.ffs(14),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              SizedBox(height: context.fx(6)),
              Text(
                'Ref: ${widget.trackId ?? 'VISA'}',
                style: TextStyle(
                  fontSize: context.ffs(12),
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TRIP DETAILS CARD ====================
  // Widget _tripDetailsCard(BuildContext context) {
  //   return _sectionCard(
  //     context,
  //     children: [
  //       _sectionHeader(context, Icons.description_outlined, 'Trip Details'),
  //       SizedBox(height: context.fx(12)),
  //       _dataRow(context, 'Details', '$_count applicant(s)'),
  //       SizedBox(height: context.fx(8)),
  //       _dataRow(context, 'Travellers', '$_count Person'),
  //       SizedBox(height: context.fx(8)),
  //       _dataRow(context, 'Applicants', '$_count'),
  //     ],
  //   );
  // }
  Widget _tripDetailsCard(BuildContext context) {
    return _sectionCard(
      context,
      children: [
        Row(                                    // <-- new Row wrapping the header
          children: [
            SvgPicture.asset(                   // <-- SVG here
              'assets/visa/tripdetails.svg',
              width: context.fx(20),
              height: context.fx(20),
              // colorFilter: const ColorFilter.mode(_ink, BlendMode.srcIn),
            ),
            SizedBox(width: context.fx(8)),
            Text(
              'Trip Details',
              style: TextStyle(
                fontSize: context.ffs(16),
                fontWeight: FontWeight.w600,
                color: _ink,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
        SizedBox(height: context.fx(12)),
        _dataRow(context, 'Details', '$_count applicant(s)'),
        SizedBox(height: context.fx(8)),
        _dataRow(context, 'Travellers', '$_count Person'),
        SizedBox(height: context.fx(8)),
        _dataRow(context, 'Applicants', '$_count'),
      ],
    );
  }

  // ==================== DATES + IMAGE CARD ====================
  Widget _datesCard(BuildContext context) {
    final travelDate = widget.trip.arrivalDate;
    final returnDate = widget.trip.departureDate;
    final bookedOn = DateFormat('dd MMM yyyy').format(_paidAt);
    final travelStr = travelDate != null
        ? DateFormat('dd/MM/yyyy').format(travelDate)
        : '--';
    final returnStr = returnDate != null
        ? DateFormat('dd/MM/yyyy').format(returnDate)
        : '--';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(16)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.fx(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/NewIcons/calender.png',
                          width: context.w(14),
                          height: context.w(14),
                          color: AppColors.AppBlue,
                        ),
                        SizedBox(width: context.fx(8)),
                        Text(
                          'DATES',
                          style: TextStyle(
                            fontSize: context.ffs(16),
                            fontWeight: FontWeight.w600,
                            color: _ink,
                            letterSpacing: 0.55,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.fx(12)),
                    _smallDataRow(context, 'Travel', travelStr),
                    SizedBox(height: context.fx(8)),
                    _smallDataRow(context, 'Return', returnStr),
                    SizedBox(height: context.fx(8)),
                    _smallDataRow(context, 'Booked On', bookedOn),
                  ],
                ),
              ),
            ),
            // Destination image
            SizedBox(
              width: context.fx(144),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _d.cardImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _d.cardImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: Center(
                              child: SizedBox(
                                width: context.fx(20),
                                height: context.fx(20),
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: Icon(Icons.public,
                                size: context.fx(32), color: _muted),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: Icon(Icons.public,
                              size: context.fx(32), color: _muted),
                        ),
                  Positioned(
                    left: context.fx(6),
                    right: context.fx(6),
                    bottom: context.fx(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.fx(6), vertical: context.fx(4)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.fx(6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              size: context.fx(12), color: _ink),
                          SizedBox(width: context.fx(4)),
                          Flexible(
                            child: Text(
                              _d.shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.ffs(9),
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== AMOUNT PAID CARD ====================
  Widget _amountPaidCard(BuildContext context) {
    final baseFare = widget.visaFeeInr * _count;
    final taxes = widget.insuranceInr;
    return Container(
      height: context.fx(109),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.fx(12)),
        gradient: const SweepGradient(
          center: Alignment.center,
          startAngle: math.pi / 2,
          colors: [
            Color(0xFFF1F5F9),
            Color(0xFFB5E0F4),
            Color(0xFF79CBEF),
            Color(0xFF5AC1EC),
            Color(0xFF3CB6E9),
            Color(0xFF1EACE7),
            Color(0xFF0FA6E5),
            Color(0xFF00A1E4),
            Color(0xFF0FA6E5),
            Color(0xFF1EACE7),
            Color(0xFF3CB6E9),
            Color(0xFF5AC1EC),
            Color(0xFF79CBEF),
            Color(0xFFB5E0F4),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left: Amount Paid label
          SizedBox(
            width: context.fx(90),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container(
                //   width: context.fx(24),
                //   height: context.fx(24),
                //   decoration: BoxDecoration(
                //     shape: BoxShape.circle,
                //     color: Colors.white.withValues(alpha: 0.1),
                //     border: Border.all(
                //         color: Colors.white.withValues(alpha: 0.64)),
                //   ),
                //   child: Icon(Icons.account_balance_wallet_rounded,
                //       size: context.fx(14), color: Colors.white),
                // ),
                Image.asset('assets/HbookImage/amountPaid.png', width: context.w(25), height: context.w(25)),
                SizedBox(height: context.fx(4)),
                Text(
                  'Amount Paid',
                  style: TextStyle(
                    fontSize: context.ffs(12),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          // Right: price breakdown
          Expanded(
            child: Container(
              margin: EdgeInsets.all(context.fx(4)),
              padding: EdgeInsets.all(context.fx(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.fx(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _priceRow(context, 'Base Fare', _money(baseFare)),
                  SizedBox(height: context.fx(6)),
                  _priceRow(
                      context, 'Taxes & Fees', _money(taxes)),
                  SizedBox(height: context.fx(12)),
                  Container(
                    height: 0.5,
                    color: _stroke,
                  ),
                  SizedBox(height: context.fx(4)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid',
                        style: TextStyle(
                          fontSize: context.ffs(12),
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Text(
                        _money(widget.totalInr),
                        style: TextStyle(
                          fontSize: context.ffs(16),
                          fontWeight: FontWeight.w700,
                          color: _green,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOOKING SUMMARY CARD ====================
  Widget _bookingSummaryCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: _stroke, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BOOKING SUMMARY',
                style: TextStyle(
                  fontSize: context.ffs(12),
                  fontWeight: FontWeight.w600,
                  color: _pri,
                  letterSpacing: 0.6,
                  fontFamily: 'Manrope',
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.fx(8.5), vertical: context.fx(2.5)),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5).withValues(alpha: 0.54),
                  borderRadius: BorderRadius.circular(context.fx(24)),
                  border: Border.all(color: _green, width: 0.5),
                ),
                child: Text(
                  'Confirmed',
                  style: TextStyle(
                    fontSize: context.ffs(10),
                    fontWeight: FontWeight.w600,
                    color: _green,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(21)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.fx(24), vertical: context.fx(12)),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(context.fx(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: _stroke, width: 0.2),
                      ),
                    ),
                    padding: EdgeInsets.only(right: context.fx(4)),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/HbookImage/walletIcon.png',
                          width: context.fx(20),
                          height: context.fx(20),
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.account_balance_wallet_rounded,
                              size: context.fx(16),
                              color: _pri),
                        ),
                        SizedBox(width: context.fx(8)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAYMENT METHOD',
                              style: TextStyle(
                                fontSize: context.ffs(10),
                                fontWeight: FontWeight.w500,
                                color: _muted,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            SizedBox(height: context.fx(2)),
                            Text(
                              widget.paymentMode,
                              style: TextStyle(
                                fontSize: context.ffs(14),
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Image.asset(
                      'assets/NewIcons/calender.png',
                      width: context.fx(14),
                      height: context.fx(14),
                      color: AppColors.lightsubhead,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.calendar_today_rounded,
                          size: context.fx(16),
                          color: _pri),
                    ),
                    SizedBox(width: context.fx(8)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOOKING DATE',
                          style: TextStyle(
                            fontSize: context.ffs(10),
                            fontWeight: FontWeight.w500,
                            color: _muted,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        SizedBox(height: context.fx(2)),
                        Text(
                          DateFormat("d MMM''yy").format(_paidAt),
                          style: TextStyle(
                            fontSize: context.ffs(14),
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
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

  // ==================== BRANDING FOOTER ====================
  Widget _brandingFooter(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/splash/logo_footer_badge.png',
        width: context.fx(150),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
  Widget _bottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(context.fx(24))),
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
              horizontal: context.fx(19), vertical: context.fx(12)),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: context.fx(48),
                  child: OutlinedButton(
                    onPressed: _goHome,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _sec),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(context.fx(12))),
                    ),
                    child: FittedBox(
                      child: Text(
                        'GO TO HOME',
                        style: TextStyle(
                          color: _sec,
                          fontSize: context.ffs(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.fx(12)),
              Expanded(
                child: SizedBox(
                  height: context.fx(48),
                  child: ElevatedButton(
                    onPressed: _downloading ? null : _downloadInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sec,
                      disabledBackgroundColor: _sec.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(context.fx(12))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_downloading)
                          SizedBox(
                            width: context.fx(18),
                            height: context.fx(18),
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        else
                          Icon(Icons.download_rounded,
                              size: context.fx(18), color: Colors.white),
                        SizedBox(width: context.fx(8)),
                        Flexible(
                          child: FittedBox(
                            child: Text(
                              _downloading ? 'PREPARING…' : 'DOWNLOAD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.ffs(14),
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

  // ==================== HELPERS ====================
  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(context.fx(16.5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(16)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }


  Widget _dataRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.ffs(14),
            fontWeight: FontWeight.w500,
            color: _muted,
            fontFamily: 'Manrope',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.ffs(14),
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Widget _smallDataRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.ffs(12.5),
            fontWeight: FontWeight.w500,
            color: _muted,
            fontFamily: 'Manrope',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.ffs(12.5),
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.ffs(11),
            fontWeight: FontWeight.w600,
            color: _muted,
            fontFamily: 'Manrope',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.ffs(11),
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}

/// Same animated success tick used in the flight booking confirmation.
class _SuccessTick extends StatefulWidget {
  const _SuccessTick({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_SuccessTick> createState() => _SuccessTickState();
}

class _SuccessTickState extends State<_SuccessTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(_onTick);
    _controller.forward();
  }

  void _onTick() {
    if (_tapped || _controller.value < 0.42) return;
    _tapped = true;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _SuccessTickPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _SuccessTickPainter extends CustomPainter {
  _SuccessTickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static double _phase(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ripple = _phase(progress, 0.40, 1.0);
    if (ripple > 0 && ripple < 1) {
      final eased = Curves.easeOutCubic.transform(ripple);
      canvas.drawCircle(
        center,
        radius * (1 + (0.35 * eased)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.03
          ..color = color.withValues(alpha: 0.35 * (1 - eased)),
      );
    }

    final pop = _phase(progress, 0.0, 0.45);
    if (pop <= 0) return;
    final scale = Curves.easeOutBack.transform(pop);
    canvas.drawCircle(
      center,
      radius * scale,
      Paint()..color = color.withValues(alpha: Curves.easeOut.transform(pop)),
    );

    final draw = _phase(progress, 0.32, 0.78);
    if (draw <= 0) return;
    final eased = Curves.easeOutCubic.transform(draw);

    final path = Path()
      ..moveTo(size.width * 0.29, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.37);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * eased),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SuccessTickPainter old) =>
      old.progress != progress || old.color != color;
}
