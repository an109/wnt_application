import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../Dashboard/profile/widgets/account_kit.dart';

// Figma "About us" frame (412px wide). Copy matches the website's India
// About page (wandernova-front: Aboutus.jsx); stats are from the Figma.

const Color _kBody = Color(0xFF5B6170);
const Color _kTeal = Color(0xFF0D9488);
const Color _kLine = Color(0xFFE8EAEE);

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(fontSize: context.ffs(13.5), height: 1.55, color: _kBody);
    final gap = SizedBox(height: context.fx(16));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(8), context.fx(16), 0),
              child: const AccountTopBar(title: 'About Us'),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: context.scrollPhysics,
                padding: EdgeInsets.fromLTRB(
                  context.fx(16),
                  context.fx(16),
                  context.fx(16),
                  context.fx(28) + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow(text: 'OUR GENESIS', dot: true),
                    SizedBox(height: context.fx(6)),
                    Text.rich(
                      const TextSpan(
                        text: 'Bridging Borders,\n',
                        children: [
                          TextSpan(text: 'Simplifying Journeys', style: TextStyle(color: AppColors.AppBlue)),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: context.ffs(22),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: kAccountInk,
                      ),
                    ),
                    SizedBox(height: context.fx(10)),
                    Text.rich(
                      const TextSpan(
                        text: 'Nurtured from a powerful vision—to seamlessly bridge the gap between global '
                            'wanderlust and effortless execution—',
                        children: [
                          TextSpan(text: 'Wander ', style: TextStyle(color: AppColors.AppBlue)),
                          TextSpan(text: 'Nova ', style: TextStyle(color: kAccountOrange)),
                          TextSpan(
                            text: 'Private Limited',
                            style: TextStyle(fontWeight: FontWeight.w600, color: kAccountInk),
                          ),
                          TextSpan(
                            text: ' is an emerging trailblazer in India\'s dynamic travel and tourism '
                                'sector. Headquartered in the thriving corporate hub of Noida, Uttar Pradesh, '
                                'Wander Nova was founded to empower travellers with meticulously curated '
                                'experiences, instant bookings, and end-to-end transparency. Built on the simple '
                                'yet profound promise to "Travel with us," what began as a passionate endeavor '
                                'to simplify journeys has rapidly evolved into a trusted global gateway for '
                                'explorers worldwide.',
                          ),
                        ],
                      ),
                      style: body,
                    ),
                    gap,
                    const _PromiseQuote(),
                    gap,
                    Text.rich(
                      const TextSpan(
                        text: 'Recognizing that modern travel requires a perfect blend of personalization and '
                            'technology, Wander Nova launched its operations with a strictly customer-first '
                            'philosophy. As the world became more connected and travellers demanded more than '
                            'just standard itineraries, we answered the call of the hour. By inviting the world to ',
                        children: [
                          TextSpan(text: '"Travel with us,"', style: TextStyle(color: _kTeal)),
                          TextSpan(
                            text: ' we transformed complex global planning into a seamless, few-clicks '
                                'experience, catering to both domestic explorers and international tourists '
                                'venturing across the globe.',
                          ),
                        ],
                      ),
                      style: body,
                    ),
                    gap,
                    const _StatsGrid(),
                    SizedBox(height: context.fx(20)),
                    const _Eyebrow(text: 'SINGLE-WINDOW ACCESS'),
                    SizedBox(height: context.fx(4)),
                    Text(
                      'Our Comprehensive Ecosystem',
                      style: TextStyle(fontSize: context.ffs(17), fontWeight: FontWeight.w600, color: kAccountInk),
                    ),
                    SizedBox(height: context.fx(6)),
                    Text(
                      'Over the years, Wander Nova has strategically expanded its portfolio to become a '
                      'holistic, single-window ecosystem for global mobility. We have built strong alliances '
                      'across the aviation, hospitality, and consular networks to ensure that whenever clients '
                      'choose to "Travel with us," they experience unparalleled comfort.',
                      style: body,
                    ),
                    gap,
                    Text(
                      'Our core offerings include:',
                      style: TextStyle(fontSize: context.ffs(13), fontWeight: FontWeight.w500, color: kAccountOrange),
                    ),
                    SizedBox(height: context.fx(12)),
                    for (final o in _kOfferings)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.fx(10)),
                        child: _OfferingCard(offering: o),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  final bool dot;

  const _Eyebrow({required this.text, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (dot) ...[
          Container(
            width: context.fx(10),
            height: context.fx(10),
            padding: EdgeInsets.all(context.fx(2)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.AppBlue, width: 1.5),
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(color: AppColors.AppBlue, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: context.fx(6)),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: context.ffs(11),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: AppColors.AppBlue,
          ),
        ),
      ],
    );
  }
}

class _PromiseQuote extends StatelessWidget {
  const _PromiseQuote();

  @override
  Widget build(BuildContext context) {
    // System serif (Georgia on iOS, Noto Serif on Android) — no font download.
    final serif = TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['serif', 'Times New Roman'],
      fontSize: context.ffs(13.5),
      height: 1.5,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      color: kAccountInk,
    );
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(left: BorderSide(color: kAccountOrange, width: 3)),
      ),
      padding: EdgeInsets.fromLTRB(context.fx(12), context.fx(14), context.fx(14), context.fx(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, size: context.fx(28), color: kAccountOrange),
          SizedBox(width: context.fx(8)),
          Expanded(
            child: Text.rich(
              const TextSpan(
                text: '"Built on the simple yet profound promise to ',
                children: [
                  TextSpan(text: '"Travel with us,"', style: TextStyle(color: _kTeal)),
                  TextSpan(
                    text: ' what began as a passionate endeavor to simplify journeys has rapidly evolved '
                        'into a trusted global gateway for explorers worldwide."',
                  ),
                ],
              ),
              style: serif,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  static const _stats = [
    ('50k+', 'Happy Travelers', Color(0xFF3B9BE0)),
    ('40+', 'Global Destinations', Color(0xFFF07C35)),
    ('99.4%', 'Visa Success Rate', Color(0xFF4CAF50)),
    ('24/7', 'Concierge Support', Color(0xFF5B5BD6)),
  ];

  @override
  Widget build(BuildContext context) {
    Widget card((String, String, Color) s) => Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.fx(16), horizontal: context.fx(8)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.fx(12)),
          border: Border.all(color: _kLine),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(
              s.$1,
              style: TextStyle(fontSize: context.ffs(22), fontWeight: FontWeight.w700, color: s.$3),
            ),
            SizedBox(height: context.fx(4)),
            Text(
              s.$2,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: context.ffs(12), color: _kBody),
            ),
          ],
        ),
      ),
    );

    final space = SizedBox(width: context.fx(12));
    return Column(
      children: [
        Row(children: [card(_stats[0]), space, card(_stats[1])]),
        SizedBox(height: context.fx(12)),
        Row(children: [card(_stats[2]), space, card(_stats[3])]),
      ],
    );
  }
}

class _Offering {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _Offering(this.icon, this.color, this.title, this.description);
}

const List<_Offering> _kOfferings = [
  _Offering(
    Icons.beach_access_rounded,
    Color(0xFF3B9BE0),
    'Bespoke Packages',
    'Curated international and domestic itineraries for leisure, adventure, and cultural immersion.',
  ),
  _Offering(
    Icons.flight_rounded,
    Color(0xFFF07C35),
    'Global Flight Bookings',
    'Seamless air ticketing with competitive pricing and optimized routes across major global airlines.',
  ),
  _Offering(
    Icons.menu_book_rounded,
    Color(0xFF4CAF50),
    'End-to-End Visa',
    'A highly efficient, expert-led visa processing wing that demystifies international documentation.',
  ),
  _Offering(
    Icons.location_on_rounded,
    Color(0xFF5B5BD6),
    'Ancillary Solutions',
    'From premium accommodation sourcing to localized ground transportation, covering every mile.',
  ),
];

class _OfferingCard extends StatelessWidget {
  final _Offering offering;

  const _OfferingCard({required this.offering});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: _kLine),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.fx(36),
            height: context.fx(36),
            decoration: BoxDecoration(
              color: offering.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.fx(8)),
            ),
            child: Icon(offering.icon, size: context.fx(18), color: offering.color),
          ),
          SizedBox(width: context.fx(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offering.title,
                  style: TextStyle(fontSize: context.ffs(14), fontWeight: FontWeight.w600, color: kAccountInk),
                ),
                SizedBox(height: context.fx(3)),
                Text(
                  offering.description,
                  style: TextStyle(fontSize: context.ffs(12), height: 1.45, color: _kBody),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
