import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

// Booking card from the Figma "Trip" frames (412px wide): header (logo,
// title, subtitle, status chip), from → to row, dashed rule, footer facts
// and "View details". Flights, hotels, transfers and visas all map onto it.

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);
const Color _kLine = Color(0xFFE5E7EB);

enum TripStatusKind { confirmed, processing, completed, cancelled }

class TripStatus {
  final TripStatusKind kind;
  final String label;

  const TripStatus(this.kind, this.label);

  Color get color => switch (kind) {
    TripStatusKind.confirmed => const Color(0xFF34A853),
    TripStatusKind.processing => const Color(0xFFE59400),
    TripStatusKind.completed => const Color(0xFF2196F3),
    TripStatusKind.cancelled => const Color(0xFFE53935),
  };

  Color get background => switch (kind) {
    TripStatusKind.confirmed => const Color(0xFFE6F6EA),
    TripStatusKind.processing => const Color(0xFFFFF4DE),
    TripStatusKind.completed => const Color(0xFFE3F2FD),
    TripStatusKind.cancelled => const Color(0xFFFDE8E8),
  };
}

/// One side of the route row: big code, place, time, date (any may be
/// empty).
class TripEndpoint {
  final String code;
  final String place;
  final String time;
  final String date;

  const TripEndpoint({required this.code, this.place = '', this.time = '', this.date = ''});
}

class TripCardData {
  final Widget leading;
  final String title;
  final String? titleSuffix;
  final String subtitle;
  final TripStatus status;
  final TripEndpoint from;
  final TripEndpoint to;
  final String middleTop;
  final IconData middleIcon;
  final String? middleBottom;
  final List<(IconData, String)> facts;
  final VoidCallback onDetails;

  const TripCardData({
    required this.leading,
    required this.title,
    this.titleSuffix,
    required this.subtitle,
    required this.status,
    required this.from,
    required this.to,
    required this.middleTop,
    required this.middleIcon,
    this.middleBottom,
    required this.facts,
    required this.onDetails,
  });
}

class TripCard extends StatelessWidget {
  final TripCardData data;

  const TripCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(context.fx(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.fx(16)),
        onTap: data.onDetails,
        child: Container(
          padding: EdgeInsets.fromLTRB(context.fx(14), context.fx(14), context.fx(14), context.fx(12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.fx(16)),
            border: Border.all(color: _kLine),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.fx(12)),
                child: const Divider(height: 1, color: Color(0xFFF0F1F4)),
              ),
              _route(context),
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.fx(12)),
                child: const TripDashedLine(color: Color(0xFFD5D9E0)),
              ),
              _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final status = data.status;
    return Row(
      children: [
        SizedBox(width: context.fx(32), height: context.fx(32), child: data.leading),
        SizedBox(width: context.fx(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: data.title,
                  children: [
                    if (data.titleSuffix != null && data.titleSuffix!.isNotEmpty)
                      TextSpan(
                        text: '  ${data.titleSuffix}',
                        style: const TextStyle(fontWeight: FontWeight.w400, color: _kMuted),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: _kInk),
              ),
              if (data.subtitle.isNotEmpty)
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(11), color: _kMuted),
                ),
            ],
          ),
        ),
        SizedBox(width: context.fx(8)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(4)),
          decoration: BoxDecoration(
            color: status.background,
            borderRadius: BorderRadius.circular(context.fx(20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              switch (status.kind) {
                TripStatusKind.completed => Icon(Icons.check_rounded, size: context.fx(14), color: status.color),
                TripStatusKind.cancelled => Icon(Icons.cancel, size: context.fx(14), color: status.color),
                _ => Container(
                  width: context.fx(6),
                  height: context.fx(6),
                  decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
                ),
              },
              SizedBox(width: context.fx(5)),
              Text(
                status.label,
                style: TextStyle(fontSize: context.ffs(11.5), fontWeight: FontWeight.w500, color: status.color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _route(BuildContext context) => TripRouteRow(
    from: data.from,
    to: data.to,
    middleTop: data.middleTop,
    middleIcon: data.middleIcon,
    middleBottom: data.middleBottom,
  );

  Widget _footer(BuildContext context) {
    final facts = <Widget>[];
    for (var i = 0; i < data.facts.length; i++) {
      final (icon, label) = data.facts[i];
      if (i > 0) {
        facts.add(Container(
          width: 1,
          height: context.fx(14),
          margin: EdgeInsets.symmetric(horizontal: context.fx(8)),
          color: _kLine,
        ));
      }
      facts.add(Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.fx(13), color: _kMuted),
            SizedBox(width: context.fx(4)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.ffs(11.5), color: const Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ));
    }
    return Row(
      children: [
        Expanded(child: Row(children: facts)),
        SizedBox(width: context.fx(6)),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: data.onDetails,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View details',
                  style: TextStyle(
                    fontSize: context.ffs(11.5),
                    fontWeight: FontWeight.w500,
                    color: AppColors.AppBlue,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: context.fx(16), color: AppColors.AppBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "COK 10:30 —✈— DMK 16:00" row shared by the Trip card, Trip Details
/// and the Ticket.
class TripRouteRow extends StatelessWidget {
  final TripEndpoint from;
  final TripEndpoint to;
  final String middleTop;
  final IconData middleIcon;
  final String? middleBottom;

  const TripRouteRow({
    super.key,
    required this.from,
    required this.to,
    required this.middleTop,
    required this.middleIcon,
    this.middleBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _endpoint(context, from, CrossAxisAlignment.start)),
        SizedBox(
          width: context.fx(124),
          child: Padding(
            padding: EdgeInsets.only(top: context.fx(10)),
            child: Column(
              children: [
                Text(
                  middleTop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(10.5), color: _kMuted),
                ),
                SizedBox(height: context.fx(4)),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const TripDashedLine(color: Color(0xFFB8C0CC)),
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: context.fx(3)),
                      child: Icon(middleIcon, size: context.fx(14), color: AppColors.AppBlue),
                    ),
                  ],
                ),
                if (middleBottom != null && middleBottom!.isNotEmpty) ...[
                  SizedBox(height: context.fx(4)),
                  Text(
                    middleBottom!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.ffs(10.5),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF07C35),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(child: _endpoint(context, to, CrossAxisAlignment.end)),
      ],
    );
  }

  Widget _endpoint(BuildContext context, TripEndpoint e, CrossAxisAlignment align) {
    final textAlign = align == CrossAxisAlignment.end ? TextAlign.end : TextAlign.start;
    Text line(String value, TextStyle style) =>
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: textAlign, style: style);
    return Column(
      crossAxisAlignment: align,
      children: [
        line(e.code, TextStyle(fontSize: context.ffs(18), fontWeight: FontWeight.w600, color: _kInk)),
        if (e.place.isNotEmpty) line(e.place, TextStyle(fontSize: context.ffs(11), color: _kMuted)),
        if (e.time.isNotEmpty) ...[
          SizedBox(height: context.fx(2)),
          line(e.time, TextStyle(fontSize: context.ffs(14), fontWeight: FontWeight.w600, color: _kInk)),
        ],
        if (e.date.isNotEmpty) line(e.date, TextStyle(fontSize: context.ffs(11), color: _kMuted)),
      ],
    );
  }
}

/// Square brand tile used as the card's leading logo for non-flight trips.
class TripIconTile extends StatelessWidget {
  final IconData icon;

  const TripIconTile({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1B7A),
        borderRadius: BorderRadius.circular(context.fx(6)),
      ),
      child: Icon(icon, size: context.fx(17), color: Colors.white),
    );
  }
}

class TripDashedLine extends StatelessWidget {
  final Color color;

  const TripDashedLine({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(color)),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0, gap = 3.0;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
