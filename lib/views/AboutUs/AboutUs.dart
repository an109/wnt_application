import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: context.scrollPhysics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(context),

              // Intro Text Section
              _buildIntroSection(context),

              // Bridging Borders Section
              _buildBridgingBordersSection(context),

              // Comprehensive Ecosystem Section
              _buildEcosystemSection(context),

              // Looking Ahead Section
              _buildLookingAheadSection(context),

              // Bottom spacing
              SizedBox(height: context.h(20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.bodyLarge,
        vertical: context.h(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WE ARE WANDER NOVA
          // Text(
          //   'WE ARE WANDER NOVA',
          //   style: TextStyle(
          //     fontSize: context.fs(12),
          //     fontWeight: FontWeight.w600,
          //     color: const Color(0xFF0F766E), // Teal color
          //     letterSpacing: 1.5,
          //   ),
          // ),
          // SizedBox(height: context.h(12)),

          // About Us Title
          Text(
            'About Us',
            style: TextStyle(
              fontSize: context.fs(36),
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          SizedBox(height: context.h(16)),

          // Travel with us badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: context.w(16),
                color: const Color(0xFF0F766E),
              ),
              SizedBox(width: context.w(8)),
              Text(
                'Travel with us',
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.bodyMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            context,
            'Nurtured from a powerful vision—to seamlessly bridge the gap between global wanderlust and effortless execution—Wander Nova Tourism LLC is an emerging trailblazer in India\'s dynamic travel and tourism sector. Headquartered in the thriving corporate hub of Noida, Uttar Pradesh, Wander Nova was founded to empower travellers with meticulously curated experiences, instant bookings, and end-to-end transparency.',
          ),
          SizedBox(height: context.h(20)),
          _buildParagraph(
            context,
            'Built on the simple yet profound promise to "Travel with us," what began as a passionate endeavor to simplify journeys has rapidly evolved into a trusted global gateway for explorers worldwide.',
          ),
          SizedBox(height: context.h(32)),

          // Divider
          Container(
            height: context.h(1),
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildBridgingBordersSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.bodyMedium,
        vertical: context.h(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bridging Borders, Simplifying Journeys',
            style: TextStyle(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: context.h(16)),
          _buildParagraph(
            context,
            'Recognizing that modern travel requires a perfect blend of personalization and technology, Wander Nova launched its operations with a strictly customer-first philosophy. As the world became more connected and travellers demanded more than just standard itineraries, we answered the call of the hour. By inviting the world to "Travel with us," we transformed complex global planning into a seamless, few-clicks experience, catering to both domestic explorers and international tourists venturing across the globe.',
          ),
          SizedBox(height: context.h(32)),

          // Divider
          Container(
            height: context.h(1),
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildEcosystemSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.bodyMedium,
        vertical: context.h(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Comprehensive Ecosystem',
            style: TextStyle(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1,
            ),
          ),
          SizedBox(height: context.h(16)),
          _buildParagraph(
            context,
            'Over the years, Wander Nova has strategically expanded its portfolio to become a holistic, single-window ecosystem for global mobility. We have built strong alliances across the aviation, hospitality, and consular networks to ensure that whenever clients choose to "Travel with us," they experience unparalleled comfort.',
          ),
          SizedBox(height: context.h(16)),
          Text(
            'Our core offerings include:',
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: context.h(24)),

          // Service Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: context.isMobile ? 1 : (context.isTablet ? 2 : 2),
            mainAxisSpacing: context.h(16),
            crossAxisSpacing: context.w(16),
            childAspectRatio: context.isMobile ? 1.3 : 1.2,
            children: [
              _buildServiceCard(
                context,
                icon: Icons.upcoming_outlined,
                title: 'Bespoke Tourism Packages',
                description: 'Curated international and domestic itineraries designed for leisure, adventure, and cultural immersion.',
              ),
              _buildServiceCard(
                context,
                icon: Icons.flight,
                title: 'Global Flight Bookings',
                description: 'Seamless air ticketing with competitive pricing and optimized routes across major global airlines.',
              ),
              _buildServiceCard(
                context,
                icon: Icons.event_note_outlined,
                title: 'End-to-End Visa Services',
                description: 'A highly efficient, expert-led visa processing wing that demystifies international documentation for hassle-free immigration.',
              ),
              _buildServiceCard(
                context,
                icon: Icons.location_on,
                title: 'Ancillary Travel Solutions',
                description: 'From premium accommodation sourcing to localized ground transportation, we cover every mile of the journey.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
      }) {
    return Container(
      padding: EdgeInsets.all(context.w(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Icon(
              icon,
              size: context.w(24),
              color: const Color(0xFF0F766E),
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            title,
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            description,
            style: TextStyle(
              fontSize: context.fs(13),
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookingAheadSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.bodySmall,
      ),
      padding: EdgeInsets.all(context.w(22)),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C5C), // Dark blue-teal
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Looking Ahead: The Next Horizon',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            'What makes the Wander Nova story truly compelling is our relentless drive to innovate. By consistently entering new geographic markets and embracing emerging travel trends, we continue to capture significant market share. Whether it is a curated solo expedition, a massive corporate retreat, or complex multi-destination international logistics, our core mission remains unchanged: inspiring the world to step out, explore, and confidently "Travel with us."',
            style: TextStyle(
              fontSize: context.fs(14),
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.fs(15),
        color: Colors.grey.shade700,
        height: 1.7,
        letterSpacing: 0.3,
      ),
    );
  }
}