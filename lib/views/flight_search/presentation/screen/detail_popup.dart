import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';

class FlightDetailsPopup extends StatelessWidget {
  final String airlineName;
  final String airlineCode;
  final String flightNumber;
  final String fromCode;
  final String toCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String price;
  final String? traceId;
  final String? resultIndex;

  /// Number of travellers — forwarded to booking → SSR for seat selection.
  final int travellerCount;

  const FlightDetailsPopup({
    super.key,
    required this.airlineName,
    required this.airlineCode,
    required this.flightNumber,
    required this.fromCode,
    required this.toCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    this.traceId,
    this.resultIndex,
    this.travellerCount = 1,
  });

  static void show(
    BuildContext context, {
    required String airlineName,
    required String airlineCode,
    required String flightNumber,
    required String fromCode,
    required String toCode,
    required String departureTime,
    required String arrivalTime,
    required String duration,
    required String price,
    String? traceId,
    String? resultIndex,
    int travellerCount = 1,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => FlightDetailsPopup(
        airlineName: airlineName,
        airlineCode: airlineCode,
        flightNumber: flightNumber,
        fromCode: fromCode,
        toCode: toCode,
        departureTime: departureTime,
        arrivalTime: arrivalTime,
        duration: duration,
        price: price,
        traceId: traceId,
        resultIndex: resultIndex,
        travellerCount: travellerCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _displayAirlineCode;

    return Padding(
      padding: EdgeInsets.only(
        left: context.w(12),
        right: context.w(12),
        bottom: MediaQuery.of(context).viewInsets.bottom + context.h(10),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: context.screenHeight * 0.88),
        decoration: BoxDecoration(
          color: const Color(0xffF4F7FF),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.r(26)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: context.w(26),
              offset: Offset(0, -context.h(8)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.r(26)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(18),
                context.h(10),
                context.w(18),
                context.h(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: context.w(42),
                    height: context.h(4),
                    decoration: BoxDecoration(
                      color: const Color(0xffCBD5E1),
                      borderRadius: BorderRadius.circular(context.r(4)),
                    ),
                  ),
                  SizedBox(height: context.h(14)),
                  _header(context, code),
                  SizedBox(height: context.h(16)),
                  _ticket(context, code),
                  SizedBox(height: context.h(14)),
                  _amenities(context),
                  SizedBox(height: context.h(12)),
                  _features(context),
                  SizedBox(height: context.h(14)),
                  _bottomBar(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String code) {
    return Row(
      children: [
        _airlineBadge(context, code, size: context.w(38)),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                airlineName,
                style: TextStyle(
                  color: const Color(0xff07163B),
                  fontSize: context.fs(16),
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.h(2)),
              Text(
                'Flight $flightNumber',
                style: TextStyle(
                  color: const Color(0xff8D95B3),
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(context.r(18)),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: context.w(34),
            height: context.w(34),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: const Color(0xff4B5563),
              size: context.w(19),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ticket(BuildContext context, String code) {
    return CustomPaint(
      painter: _DetailTicketPainter(
        color: Colors.white,
        shadowColor: const Color(0xff2B3A67).withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(18),
          context.h(18),
          context.w(18),
          context.h(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _priceBox(context),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(4),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFF),
                    borderRadius: BorderRadius.circular(context.r(14)),
                    border: Border.all(color: const Color(0xffE6ECFF)),
                  ),
                  child: Text(
                    'Flight $code$flightNumber',
                    style: TextStyle(
                      color: const Color(0xff8D95B3),
                      fontSize: context.fs(10),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(22)),
            Row(
              children: [
                _timeBlock(context, departureTime, fromCode, false),
                SizedBox(width: context.w(10)),
                Expanded(child: _flightPath(context)),
                SizedBox(width: context.w(10)),
                _timeBlock(context, arrivalTime, toCode, true),
              ],
            ),
            SizedBox(height: context.h(16)),
            _dashedDivider(context),
            SizedBox(height: context.h(14)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metaChip(context, 'Stops', 'Non-stop'),
                _metaChip(context, 'Duration', _cleanDuration),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBox(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(9),
      ),
      decoration: BoxDecoration(
        color: const Color(0xffEAFBF1),
        borderRadius: BorderRadius.circular(context.r(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Price',
            style: TextStyle(
              color: const Color(0xff4B5563),
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.h(4)),
          Text(
            price,
            style: TextStyle(
              color: const Color(0xff07163B),
              fontSize: context.fs(20),
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'per adult',
            style: TextStyle(
              color: const Color(0xff6B7280),
              fontSize: context.fs(10),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBlock(
    BuildContext context,
    String time,
    String code,
    bool alignRight,
  ) {
    return SizedBox(
      width: context.w(74),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: TextStyle(
              color: const Color(0xff3D3F4A),
              fontSize: context.fs(22),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: context.h(4)),
          Text(
            code,
            style: TextStyle(
              color: const Color(0xffA0A6C2),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flightPath(BuildContext context) {
    const color = Color(0xff5F86FF);
    return Row(
      children: [
        _pathDot(context, color),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
            child: SizedBox(height: context.h(1)),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(6)),
          child: Icon(Icons.flight, color: color, size: context.w(24)),
        ),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
            child: SizedBox(height: context.h(1)),
          ),
        ),
        _pathDot(context, color),
      ],
    );
  }

  Widget _pathDot(BuildContext context, Color color) {
    return Container(
      width: context.w(9),
      height: context.w(9),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.26),
            blurRadius: context.w(8),
            spreadRadius: context.w(1),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
      child: SizedBox(width: double.infinity, height: context.h(1)),
    );
  }

  Widget _metaChip(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xffA0A6C2),
            fontSize: context.fs(11),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.h(4)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(4),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: const Color(0xffE6ECFF)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xff3D3F4A),
              fontSize: context.fs(11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _amenities(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            context,
            icon: Icons.airline_seat_recline_normal,
            iconColor: const Color(0xff9B5DE5),
            title: 'Seats & Meals',
            subtitle: 'Meals information not available',
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: _infoCard(
            context,
            icon: Icons.shield_outlined,
            iconColor: const Color(0xffF59E0B),
            title: 'Flexibility',
            subtitle: 'Per airline rules',
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: const Color(0xffE6ECFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.w(30),
            height: context.w(30),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: context.w(17)),
          ),
          SizedBox(width: context.w(9)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xff07163B),
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.h(3)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xff7C849F),
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _features(BuildContext context) {
    final items = [
      (Icons.lock_outline, 'Trusted Booking', '100% Secure'),
      (Icons.headphones, '24/7 Support', "We're here to help"),
      (Icons.sync_alt, 'Easy Changes', 'Hassle-free process'),
      (Icons.verified_outlined, 'Best Price', 'Best deals'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF2),
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: const Color(0xffFDE68A)),
      ),
      child: Wrap(
        spacing: context.w(16),
        runSpacing: context.h(12),
        children: items
            .map(
              (item) => SizedBox(
                width: context.w(136),
                child: Row(
                  children: [
                    Icon(
                      item.$1,
                      color: const Color(0xffF59E0B),
                      size: context.w(16),
                    ),
                    SizedBox(width: context.w(7)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: TextStyle(
                              color: const Color(0xff07163B),
                              fontSize: context.fs(11),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.$3,
                            style: TextStyle(
                              color: const Color(0xff7C849F),
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: const Color(0xff16A34A),
                size: context.w(18),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Free cancellation ',
                        style: TextStyle(
                          color: const Color(0xff16A34A),
                          fontWeight: FontWeight.w800,
                          fontSize: context.fs(11),
                        ),
                      ),
                      TextSpan(
                        text: 'as per airline policy',
                        style: TextStyle(
                          color: const Color(0xff4B5563),
                          fontWeight: FontWeight.w500,
                          fontSize: context.fs(11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(12)),
        SizedBox(
          height: context.h(48),
          child: ElevatedButton(
            onPressed: () => _bookNow(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1663F7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: context.w(22)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(14)),
              ),
            ),
            child: Text(
              'Book Now',
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _airlineBadge(
    BuildContext context,
    String code, {
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _airlineColor(code),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        code.length > 2 ? code.substring(0, 2) : code,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.fs(10),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _bookNow(BuildContext context) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlightBookingScreen(
          routes: [
            FlightRouteSegment(
              from: fromCode,
              price: price,
              to: toCode,
              traceId: traceId,
              resultIndex: resultIndex,
              departureTime: departureTime,
              arrivalTime: arrivalTime,
              duration: duration,
              airline: airlineName,
              flightNo: "$airlineCode • $flightNumber",
            ),
          ],
          totalPrice: price,
          traceId: traceId,
          resultIndex: resultIndex,
          price: price,
          travellerCount: travellerCount,
          isLoggedIn: false,
        ),
      ),
    );
  }

  String get _displayAirlineCode {
    final compact = airlineCode.trim().isNotEmpty ? airlineCode : airlineName;
    final letters = compact
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (letters.length >= 2) return letters.substring(0, 2);
    return letters.isEmpty ? 'FL' : letters;
  }

  String get _cleanDuration {
    final value = duration.trim();
    if (value.endsWith(' min')) {
      final raw = int.tryParse(value.replaceAll(' min', ''));
      if (raw != null) {
        final hours = raw ~/ 60;
        final mins = raw % 60;
        if (hours > 0 && mins > 0) return '$hours hr $mins min';
        if (hours > 0) return '$hours hr';
        return '$mins min';
      }
    }
    return value;
  }

  Color _airlineColor(String code) {
    final colors = [
      const Color(0xffC29200),
      const Color(0xff25358D),
      const Color(0xff7A003C),
      const Color(0xff0F766E),
      const Color(0xffB42318),
    ];
    final hash = code.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return colors[hash % colors.length];
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    var startX = 0.0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(math.min(startX + dashWidth, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DetailTicketPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _DetailTicketPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    const notchRadius = 13.0;
    const radius = 18.0;
    final notchY = size.height * 0.62;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)));
    final leftNotch = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(0, notchY), radius: notchRadius),
      );
    final rightNotch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width, notchY),
          radius: notchRadius,
        ),
      );
    final cutLeft = Path.combine(PathOperation.difference, path, leftNotch);
    final ticket = Path.combine(PathOperation.difference, cutLeft, rightNotch);

    canvas.drawShadow(ticket, shadowColor, 12, true);
    canvas.drawPath(ticket, Paint()..color = color);
    canvas.drawPath(
      ticket,
      Paint()
        ..color = const Color(0xffE6ECFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DetailTicketPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
