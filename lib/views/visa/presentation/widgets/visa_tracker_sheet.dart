import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/visa_theme.dart';

/// Government portal stats from the destination's admin-entered
/// `app_insights.portal`. Null when the admin has not filled them in.
class VisaPortalStatus {
  final String name;
  final String title;
  final String status;
  final double? uptimePercent;
  final int? latencyMs;
  final List<String> daily;
  final List<({String at, String status, String text})> incidents;

  const VisaPortalStatus({
    required this.name,
    required this.title,
    required this.status,
    required this.uptimePercent,
    required this.latencyMs,
    required this.daily,
    required this.incidents,
  });

  static VisaPortalStatus? from(Map<String, dynamic> insights, String country) {
    final p = insights['portal'];
    if (p is! Map) return null;
    final uptime = num.tryParse('${p['uptime_percent'] ?? ''}')?.toDouble();
    return VisaPortalStatus(
      name: (p['name'] ?? '$country Portal').toString(),
      title: (p['title'] ?? "$country's Government Portal").toString(),
      status: (p['status'] ?? 'operational').toString().toLowerCase(),
      uptimePercent: uptime,
      latencyMs: int.tryParse('${p['latency_ms'] ?? ''}'),
      daily: (p['daily'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [],
      incidents: (p['incidents'] as List?)
              ?.whereType<Map>()
              .map((i) => (
                    at: (i['at'] ?? '').toString(),
                    status: (i['status'] ?? '').toString(),
                    text: (i['text'] ?? '').toString(),
                  ))
              .toList() ??
          const [],
    );
  }

  String get statusLabel => switch (status) {
        'degraded' || 'slow' => 'Running Slow',
        'down' || 'outage' => 'Currently Down',
        _ => 'Currently Operational',
      };

  Color get statusColor => switch (status) {
        'degraded' || 'slow' => const Color(0xFFF59E0B),
        'down' || 'outage' => VisaColors.red,
        _ => VisaColors.primary,
      };
}

/// "92.5%", "93%".
String visaPercent(double v) => '${v == v.roundToDouble() ? v.toInt() : v}%';

/// "Your visa time drop…" sheet: Government Systems Tracker.
class VisaTrackerSheet extends StatelessWidget {
  final String country;
  final VisaPortalStatus portal;

  const VisaTrackerSheet({super.key, required this.country, required this.portal});

  @override
  Widget build(BuildContext context) {
    final serif = GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600, color: VisaColors.title);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: VisaColors.stroke),
            ),
            child: const Icon(Icons.account_balance, size: 18, color: VisaColors.primary),
          ),
        ),
        const SizedBox(height: 10),
        Text('$country Government', textAlign: TextAlign.center, style: serif),
        Text('Systems Tracker', textAlign: TextAlign.center, style: serif.copyWith(color: VisaColors.primary)),
        const SizedBox(height: 8),
        Text(
          'A real-time dashboard showing whether\nWander Nova, as well as each government\nvisa portal is up, slow, or experiencing issues.',
          textAlign: TextAlign.center,
          style: visaText(9, color: VisaColors.text, height: 1.4),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFCDEBF8), Color(0xFFEAF6FC)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: portal.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: portal.statusColor),
                    const SizedBox(width: 4),
                    Text(portal.statusLabel,
                        style: visaText(8, weight: FontWeight.w600, color: portal.statusColor, letterSpacing: 0.4)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(portal.title, style: visaText(11, weight: FontWeight.w700, color: VisaColors.title)),
              if (portal.daily.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      for (final d in portal.daily)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.6),
                            color: switch (d) {
                              'slow' || 'degraded' => const Color(0xFFF59E0B),
                              'down' || 'outage' => VisaColors.red,
                              _ => const Color(0xFF86D69B),
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${portal.daily.isEmpty ? 90 : portal.daily.length} days ago',
                      style: visaText(8.5, color: VisaColors.text)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 11, color: VisaColors.primary),
                  const Spacer(),
                  if (portal.uptimePercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VisaColors.primary.withOpacity(0.4)),
                        color: Colors.white.withOpacity(0.5),
                      ),
                      child: Text('${visaPercent(portal.uptimePercent!)} uptime',
                          style: visaText(9, weight: FontWeight.w600, color: VisaColors.primary)),
                    ),
                  const Spacer(),
                  const Icon(Icons.arrow_back, size: 11, color: VisaColors.primary),
                  const SizedBox(width: 4),
                  Text('Today', style: visaText(8.5, color: VisaColors.text)),
                ],
              ),
              if (portal.latencyMs != null) ...[
                const Divider(height: 18, color: Color(0x33000000)),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Latency: ', style: visaText(8, color: VisaColors.text)),
                  TextSpan(
                      text: '${portal.latencyMs}ms',
                      style: visaText(8, weight: FontWeight.w700, color: VisaColors.title)),
                ])),
              ],
            ],
          ),
        ),
        if (portal.incidents.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Last Recorded Incidents', style: visaText(10, weight: FontWeight.w600, color: VisaColors.title)),
          const SizedBox(height: 10),
          for (var i = 0; i < portal.incidents.length; i++)
            _incident(portal.incidents[i], last: i == portal.incidents.length - 1),
        ],
      ],
    );
  }

  Widget _incident(({String at, String status, String text}) i, {required bool last}) {
    final resolved = i.status.toLowerCase().contains('resolv');
    final color = resolved ? VisaColors.green : const Color(0xFFF07A2D);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: VisaColors.stroke),
                  color: Colors.white,
                ),
              ),
              if (!last) Expanded(child: Container(width: 1, color: VisaColors.stroke)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(i.at, style: visaText(10, weight: FontWeight.w600, color: VisaColors.title)),
                      const SizedBox(width: 8),
                      if (i.status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(i.status, style: visaText(7.5, weight: FontWeight.w600, color: color)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(i.text, style: visaText(9, color: VisaColors.text, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
