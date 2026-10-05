import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../data/models/diy_models.dart';
import 'diy_common.dart';

/// City names for the airport codes a flight carries ("DEL to COK"), so the
/// flight screens can read "New Delhi to Kochi" as the design does. An
/// unknown code is shown as the code.
const Map<String, String> _airportCities = {
  'DEL': 'New Delhi',
  'BOM': 'Mumbai',
  'BLR': 'Bengaluru',
  'MAA': 'Chennai',
  'HYD': 'Hyderabad',
  'CCU': 'Kolkata',
  'COK': 'Kochi',
  'TRV': 'Thiruvananthapuram',
  'CCJ': 'Kozhikode',
  'CNN': 'Kannur',
  'GOI': 'Goa (South)',
  'GOX': 'Goa (North)',
  'IXC': 'Chandigarh',
  'JAI': 'Jaipur',
  'AMD': 'Ahmedabad',
  'PNQ': 'Pune',
  'IXB': 'Bagdogra',
  'SXR': 'Srinagar',
  'IXL': 'Leh',
  'IXZ': 'Port Blair',
  'GAU': 'Guwahati',
  'LKO': 'Lucknow',
  'ATQ': 'Amritsar',
  'VNS': 'Varanasi',
  'PAT': 'Patna',
  'BBI': 'Bhubaneswar',
  'IDR': 'Indore',
  'NAG': 'Nagpur',
  'UDR': 'Udaipur',
  'JDH': 'Jodhpur',
  'DED': 'Dehradun',
  'IXJ': 'Jammu',
  'IXE': 'Mangaluru',
  'CJB': 'Coimbatore',
  'IXM': 'Madurai',
  'TRZ': 'Tiruchirappalli',
  'VTZ': 'Visakhapatnam',
  'BHO': 'Bhopal',
  'RPR': 'Raipur',
  'IXR': 'Ranchi',
  'IXA': 'Agartala',
  'DIB': 'Dibrugarh',
  'KUU': 'Kullu',
  'DHM': 'Dharamshala',
  'DXB': 'Dubai',
  'AUH': 'Abu Dhabi',
  'SIN': 'Singapore',
  'BKK': 'Bangkok',
  'HKT': 'Phuket',
  'DPS': 'Bali',
  'KUL': 'Kuala Lumpur',
  'MLE': 'Male',
  'KTM': 'Kathmandu',
  'CMB': 'Colombo',
  'PBH': 'Paro',
};

String diyAirportCity(String code) =>
    _airportCities[code.trim().toUpperCase()] ?? code;

/// "DEL to COK" → ("DEL", "COK"). Either may be empty.
(String, String) diyRouteCodes(String title) {
  final parts = title.split(' to ');
  return (
    parts.isNotEmpty ? parts.first.trim() : '',
    parts.length > 1 ? parts.last.trim() : '',
  );
}

/// "Chandigarh - Goa (South)" style, from a flight title.
String diyRouteCities(String title, {String joiner = ' to '}) {
  final (from, to) = diyRouteCodes(title);
  if (from.isEmpty || to.isEmpty) return title;
  return '${diyAirportCity(from)}$joiner${diyAirportCity(to)}';
}

/// The design's flight path: an orange arc fading out towards both ends, a
/// hollow blue dot where it lands on each side, and the plane at the top.
class DiyFlightArc extends StatelessWidget {
  const DiyFlightArc({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.h(48),
      child: CustomPaint(
        painter: _FlightArcPainter(),
        child: Align(
          alignment: const Alignment(0, -0.9),
          child: Transform.rotate(
            angle: 1.5708,
            child: Icon(
              Icons.flight_rounded,
              size: context.w(22),
              color: DiyTokens.blue,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlightArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final left = Offset(size.width * 0.08, size.height * 0.95);
    final right = Offset(size.width * 0.92, size.height * 0.95);
    final control = Offset(size.width / 2, -size.height * 0.15);
    final path = Path()
      ..moveTo(left.dx, left.dy - 8)
      ..quadraticBezierTo(control.dx, control.dy, right.dx, right.dy - 8);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FF6600),
          Color(0xFFFF6600),
          Color(0xFFFF6600),
          Color(0x00FF6600),
        ],
        stops: [0, 0.4, 0.6, 1],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, arc);

    final dot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = DiyTokens.blue;
    canvas.drawCircle(left, 4, dot);
    canvas.drawCircle(right, 4, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "2h 35m Layover in BOM, Mumbai" — the band between two flights, when the
/// second leaves after the first lands.
class DiyLayoverBand extends StatelessWidget {
  final String arrivedAt;
  final String leavesAt;
  final String airport;

  const DiyLayoverBand({
    super.key,
    required this.arrivedAt,
    required this.leavesAt,
    required this.airport,
  });

  /// Between two of a day's flight rows.
  factory DiyLayoverBand.rows({
    Key? key,
    required DiyRow arriving,
    required DiyRow leaving,
  }) => DiyLayoverBand(
    key: key,
    arrivedAt: arriving.arrivalAt,
    leavesAt: leaving.departureAt,
    airport: diyRouteCodes(arriving.title).$2,
  );

  @override
  Widget build(BuildContext context) {
    final landed = diyParseDate(arrivedAt);
    final departs = diyParseDate(leavesAt);
    final gap = landed != null && departs != null
        ? departs.difference(landed).inMinutes
        : 0;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: context.h(14)),
      padding: EdgeInsets.symmetric(vertical: context.h(4)),
      color: const Color(0xFFE1F1FB),
      alignment: Alignment.center,
      child: Text(
        [
          if (gap > 0) '${diyDuration(gap)} Layover',
          if (airport.isNotEmpty) 'in $airport, ${diyAirportCity(airport)}',
        ].join(' '),
        style: TextStyle(fontSize: context.fs(11), color: DiyTokens.blue),
      ),
    );
  }
}
