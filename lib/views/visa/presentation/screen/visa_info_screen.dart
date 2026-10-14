import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import 'visa_application_form_screen.dart';

/// "View more free …" details page (Figma 1957:8937 family).
class VisaInfoScreen extends StatefulWidget {
  final VisaPopularDestinationEntity destination;
  const VisaInfoScreen({super.key, required this.destination});

  @override
  State<VisaInfoScreen> createState() => _VisaInfoScreenState();
}

class _VisaInfoScreenState extends State<VisaInfoScreen> {
  VisaTypeEntity? _type;

  VisaPopularDestinationEntity get _d => widget.destination;

  @override
  void initState() {
    super.initState();
    _type = _d.primaryType;
  }

  bool get _free => _type?.isFree ?? false;

  String get _formName => _free ? 'Entry Form' : (_type == null ? 'Visa' : _d.kindOf(_type!).label);

  @override
  Widget build(BuildContext context) {
    final type = _type;
    final processing = type?.parsedProcessing ?? _d.fastestProcessing;
    final requirements = _d.requiredDocuments.isNotEmpty ? _d.requiredDocuments : _d.requirementsItems;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VisaColors.title),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _headerCard(type, processing),
          const SizedBox(height: 16),
          _illustration(),
          if (_d.visaTypes.length > 1) ...[
            const SizedBox(height: 20),
            Text('Choose visa type', style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
            const SizedBox(height: 10),
            _typePicker(),
          ],
          const SizedBox(height: 20),
          Text(
            _d.requirementsHeading.isNotEmpty ? _d.requirementsHeading : 'Required to apply',
            style: visaText(13, weight: FontWeight.w600, color: VisaColors.title),
          ),
          const SizedBox(height: 10),
          if (requirements.isEmpty)
            _requirement('Passport', 'Personal details')
          else
            for (final r in requirements) _requirement(r, null),
          const SizedBox(height: 20),
          Text('Processing Timeline', style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
          const SizedBox(height: 10),
          _timeline(processing),
          if (_d.faqs.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Frequently asked questions',
                style: visaText(13, weight: FontWeight.w600, color: VisaColors.title)),
            const SizedBox(height: 6),
            for (final f in _d.faqs) _faq(f['q']!, f['a']!),
          ],
        ],
      ),
      bottomNavigationBar: _bottomBar(processing),
    );
  }

  Widget _headerCard(VisaTypeEntity? type, VisaProcessing? processing) {
    final priceText = type?.feeLabel ?? '—';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white, Color(0xFFF3E8FF), Color(0xFFE0F2FE)],
          stops: [0, 0.6, 0.85, 1],
        ),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(
            '${_d.shortName}\n$_formName',
            textAlign: TextAlign.center,
            style: GoogleFonts.goblinOne(fontSize: 18, color: VisaColors.cta, height: 1.25, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            _free
                ? 'The ${_d.shortName} entry form is the\nonly document required to enter'
                : '${type?.title ?? 'Visa'} for ${_d.shortName},\napplied online in a few minutes',
            textAlign: TextAlign.center,
            style: visaText(10, color: VisaColors.text, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(Icons.payments_outlined, 'PRICE', priceText),
              _divider(),
              _stat(Icons.bolt, 'PROCESSING TIME', type?.processing.isNotEmpty == true ? type!.processing : (processing?.humanized ?? '—')),
              _divider(),
              _stat(Icons.calendar_month_outlined, 'MAX STAY', type?.stay.isNotEmpty == true ? type!.stay : '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 0.6, height: 28, color: VisaColors.stroke);

  Widget _stat(IconData icon, String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: VisaColors.title),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: visaText(6.5, weight: FontWeight.w600, color: VisaColors.text)),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: visaText(10, weight: FontWeight.w700, color: VisaColors.title)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _illustration() {
    return Center(
      child: Container(
        width: 250,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5FAFF), Color(0xFFDCEBFA)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: CustomPaint(
          painter: _TicketLinesPainter(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight, size: 22, color: VisaColors.primary),
              Text(
                _formName,
                style: const TextStyle(fontFamily: 'CaveatBrush', fontSize: 30, color: VisaColors.primary, height: 1.1),
              ),
              Text(
                '${_d.shortName.toUpperCase()} ${_free ? 'TRAVELER DECLARATION' : 'VISA APPLICATION'}',
                style: visaText(8, weight: FontWeight.w600, color: VisaColors.primary, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typePicker() {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _d.visaTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = _d.visaTypes[i];
          final selected = t == _type;
          return GestureDetector(
            onTap: () => setState(() => _type = t),
            child: Container(
              width: 170,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? VisaColors.primarySoft : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? VisaColors.primary : VisaColors.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [t.stay, t.entry].where((s) => s.trim().isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: visaText(9, color: VisaColors.text),
                        ),
                      ),
                      Text(t.feeLabel,
                          style: visaText(11, weight: FontWeight.w700, color: VisaColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _requirement(String title, String? subtitle) {
    final t = title.toLowerCase();
    final icon = t.contains('flight') || t.contains('ticket') || t.contains('itinerary')
        ? Icons.airplane_ticket_outlined
        : t.contains('hotel') || t.contains('accommodation')
            ? Icons.apartment
            : t.contains('photo')
                ? Icons.photo_camera_outlined
                : t.contains('bank') || t.contains('financial') || t.contains('fund') || t.contains('salary')
                    ? Icons.account_balance_outlined
                    : t.contains('passport')
                        ? Icons.badge_outlined
                        : Icons.description_outlined;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: VisaColors.primarySoft, borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 18, color: VisaColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
                if (subtitle != null) Text(subtitle, style: visaText(9, color: VisaColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(VisaProcessing? processing) {
    final total = processing?.humanized ?? (_type?.processing ?? 'On request');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('TOTAL TIME', style: visaText(9, weight: FontWeight.w600, color: VisaColors.text)),
              const Spacer(),
              const Icon(Icons.circle, size: 7, color: VisaColors.green),
              const SizedBox(width: 6),
              Text(total, style: visaText(14, weight: FontWeight.w700, color: VisaColors.title)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(height: 5, decoration: BoxDecoration(color: const Color(0xFFBFE6F8), borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Container(height: 5, decoration: BoxDecoration(color: VisaColors.primary, borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 16, color: VisaColors.green),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _phase('5 minutes', 'Submission', VisaColors.title, CrossAxisAlignment.start),
              _phase(_type?.processing.isNotEmpty == true ? _type!.processing : total, 'Processing',
                  VisaColors.primary, CrossAxisAlignment.center),
              _phase('Approved', 'Delivered by email', VisaColors.green, CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }

  Widget _phase(String value, String label, Color color, CrossAxisAlignment align) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: visaText(9, weight: FontWeight.w700, color: color)),
          Text(label, style: visaText(8, color: VisaColors.text)),
        ],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 10),
        expandedAlignment: Alignment.centerLeft,
        title: Text(q, style: visaText(11, weight: FontWeight.w600, color: VisaColors.title)),
        children: [Text(a, style: visaText(11, color: VisaColors.text, height: 1.5))],
      ),
    );
  }

  Widget _bottomBar(VisaProcessing? processing) {
    final type = _type;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delivered in ${processing?.humanized ?? type?.processing ?? '—'}',
                    style: visaText(11, weight: FontWeight.w700, color: VisaColors.title),
                  ),
                  Text(
                    type == null
                        ? ''
                        : type.isFree
                            ? '100% Free'
                            : '${type.feeLabel} per traveller',
                    style: visaText(10, weight: FontWeight.w600, color: VisaColors.primary),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 140,
              height: 38,
              child: ElevatedButton(
                onPressed: type == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VisaApplicationFormScreen(destination: _d, visaType: type),
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VisaColors.cta,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text('GET NOW', style: visaText(12, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two yellow dashed travel lines across the "Entry Form" ticket.
class _TicketLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5C542)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    void dashed(Offset a, Offset b) {
      const dash = 6.0, gap = 4.0;
      final total = (b - a).distance;
      final dir = (b - a) / total;
      for (double t = 0; t < total; t += dash + gap) {
        canvas.drawLine(a + dir * t, a + dir * (t + dash).clamp(0, total), paint);
      }
    }

    dashed(Offset(0, size.height * 0.95), Offset(size.width * 0.45, size.height * 0.62));
    dashed(Offset(size.width, size.height * 0.95), Offset(size.width * 0.55, size.height * 0.62));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
